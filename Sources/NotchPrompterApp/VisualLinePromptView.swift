import AppKit
import NotchPrompterCore
import SwiftUI

struct VisualLinePromptView: NSViewRepresentable {
    let text: String
    let fontSize: CGFloat
    let scrollOffset: CGFloat
    let manualNavigationRevision: Int
    let onLayout: (PromptLayoutMetrics) -> Void
    let onManualScroll: (_ points: CGFloat) -> Void

    func makeNSView(context: Context) -> PromptTextView {
        let view = PromptTextView()
        view.onLayout = onLayout
        view.onManualScroll = onManualScroll
        view.configure(
            text: text,
            fontSize: fontSize,
            scrollOffset: scrollOffset,
            manualNavigationRevision: manualNavigationRevision
        )
        return view
    }

    func updateNSView(_ nsView: PromptTextView, context: Context) {
        nsView.onLayout = onLayout
        nsView.onManualScroll = onManualScroll
        nsView.configure(
            text: text,
            fontSize: fontSize,
            scrollOffset: scrollOffset,
            manualNavigationRevision: manualNavigationRevision
        )
    }
}

final class PromptTextView: NSView {
    var onLayout: ((PromptLayoutMetrics) -> Void)?
    var onManualScroll: ((CGFloat) -> Void)?

    private let textStorage = NSTextStorage()
    private let layoutManager = NSLayoutManager()
    private let textContainer = NSTextContainer()
    private let horizontalInset: CGFloat = 28
    private let activeColor = NSColor(
        calibratedRed: 0.96,
        green: 0.93,
        blue: 0.87,
        alpha: 1
    )
    private let dimmedColor = NSColor(
        calibratedRed: 0.96,
        green: 0.93,
        blue: 0.87,
        alpha: 0.42
    )

    private var script = ""
    private var promptFontSize: CGFloat = 38
    private var scrollOffset: CGFloat = 0
    private var activeGlyphRange: NSRange?
    private var activeCharacterRange: NSRange?
    private var firstLineCenter: CGFloat = 0
    private var currentLineText: String?
    private var lastManualNavigationRevision = 0
    private var pendingAnnouncement: DispatchWorkItem?
    private var lastContainerWidth: CGFloat = -1
    private var lastReportedMetrics: PromptLayoutMetrics?
    private var pendingMetrics: PromptLayoutMetrics?
    private var layoutReportScheduled = false

    override var isFlipped: Bool { true }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        textContainer.lineFragmentPadding = 0
        textContainer.widthTracksTextView = false
        textContainer.heightTracksTextView = false
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)

        setAccessibilityElement(true)
        setAccessibilityRole(.staticText)
        setAccessibilityLabel("Teleprompter script")
        setAccessibilityValue("")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(
        text: String,
        fontSize: CGFloat,
        scrollOffset: CGFloat,
        manualNavigationRevision: Int
    ) {
        let contentChanged = script != text || promptFontSize != fontSize
        let shouldAnnounce = manualNavigationRevision != lastManualNavigationRevision
        script = text
        promptFontSize = fontSize
        self.scrollOffset = max(scrollOffset, 0)
        lastManualNavigationRevision = manualNavigationRevision

        if contentChanged {
            rebuildTextStorage()
        }
        updateLayoutIfNeeded(force: contentChanged)
        if shouldAnnounce {
            scheduleManualNavigationAnnouncement()
        }
        needsDisplay = true
    }

    override func layout() {
        super.layout()
        updateLayoutIfNeeded(force: false)
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        updateLayoutIfNeeded(force: false)

        let glyphRange = layoutManager.glyphRange(for: textContainer)
        guard glyphRange.length > 0 else { return }

        let origin = textOrigin
        if let activeCharacterRange {
            layoutManager.addTemporaryAttribute(
                .foregroundColor,
                value: activeColor,
                forCharacterRange: activeCharacterRange
            )
        }

        layoutManager.drawBackground(forGlyphRange: glyphRange, at: origin)
        layoutManager.drawGlyphs(forGlyphRange: glyphRange, at: origin)
        if let activeCharacterRange {
            layoutManager.removeTemporaryAttribute(
                .foregroundColor,
                forCharacterRange: activeCharacterRange
            )
        }
    }

    override func scrollWheel(with event: NSEvent) {
        guard event.scrollingDeltaY != 0 else {
            super.scrollWheel(with: event)
            return
        }
        let scale: CGFloat = event.hasPreciseScrollingDeltas ? 1 : 24
        onManualScroll?(-event.scrollingDeltaY * scale)
    }

    private var textOrigin: CGPoint {
        CGPoint(
            x: horizontalInset,
            y: ReadingGuide.textOriginY(
                viewportHeight: bounds.height,
                firstLineCenter: firstLineCenter,
                scrollOffset: scrollOffset
            )
        )
    }

    private func rebuildTextStorage() {
        activeGlyphRange = nil
        activeCharacterRange = nil

        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        paragraph.lineBreakMode = .byWordWrapping
        paragraph.lineSpacing = promptFontSize * 0.26

        let font = NSFont.systemFont(ofSize: promptFontSize, weight: .medium)
        textStorage.setAttributedString(NSAttributedString(
            string: script,
            attributes: [
                .font: font,
                .foregroundColor: dimmedColor,
                .paragraphStyle: paragraph
            ]
        ))
        setAccessibilityValue(script)
        lastContainerWidth = -1
    }

    private func updateLayoutIfNeeded(force: Bool) {
        let width = max(bounds.width - horizontalInset * 2, 1)
        if force || abs(width - lastContainerWidth) > 0.25 {
            lastContainerWidth = width
            textContainer.containerSize = NSSize(
                width: width,
                height: CGFloat.greatestFiniteMagnitude
            )
            layoutManager.ensureLayout(for: textContainer)
        }

        let fullGlyphRange = layoutManager.glyphRange(for: textContainer)
        var fragmentRects: [CGRect] = []
        var glyphRanges: [NSRange] = []

        layoutManager.enumerateLineFragments(forGlyphRange: fullGlyphRange) {
            lineFragmentRect, _, _, glyphRange, _ in
            fragmentRects.append(lineFragmentRect)
            glyphRanges.append(glyphRange)
        }

        firstLineCenter = fragmentRects.first?.midY ?? 0
        updateActiveFragment(fragmentRects: fragmentRects, glyphRanges: glyphRanges)
        scheduleLayoutReport(PromptLayoutMetrics(
            firstLineCenter: fragmentRects.first?.midY,
            lastLineCenter: fragmentRects.last?.midY,
            lineCenters: fragmentRects.map(\.midY),
            viewportHeight: bounds.height
        ))
    }

    private func updateActiveFragment(
        fragmentRects: [CGRect],
        glyphRanges: [NSRange]
    ) {
        let guideY = ReadingGuide.position(in: bounds.height)
        let guideInContainer = guideY - textOrigin.y
        let index = VisualLineSelection.activeFragmentIndex(
            guideY: guideInContainer,
            fragmentRects: fragmentRects
        )
        let newGlyphRange = index.map { glyphRanges[$0] }
        let newCharacterRange = newGlyphRange.map {
            layoutManager.characterRange(forGlyphRange: $0, actualGlyphRange: nil)
        }

        if !NSEqualRanges(activeGlyphRange ?? NSRange(location: NSNotFound, length: 0),
                          newGlyphRange ?? NSRange(location: NSNotFound, length: 0)) {
            activeGlyphRange = newGlyphRange
            activeCharacterRange = newCharacterRange
            updateCurrentLineAccessibility()
        } else {
            activeCharacterRange = newCharacterRange
        }
    }

    private func updateCurrentLineAccessibility() {
        guard let activeCharacterRange,
              activeCharacterRange.location != NSNotFound,
              NSMaxRange(activeCharacterRange) <= (script as NSString).length else {
            setAccessibilityHelp(nil)
            return
        }

        let currentLine = (script as NSString)
            .substring(with: activeCharacterRange)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        currentLineText = currentLine.isEmpty ? nil : currentLine
        setAccessibilityHelp(
            currentLine.isEmpty ? nil : "Current line: \(currentLine)"
        )
    }

    private func scheduleManualNavigationAnnouncement() {
        pendingAnnouncement?.cancel()
        let announcement = DispatchWorkItem { [weak self] in
            guard let self, let currentLineText = self.currentLineText else { return }
            NSAccessibility.post(
                element: self,
                notification: .announcementRequested,
                userInfo: [
                    .announcement: "Current line: \(currentLineText)",
                    .priority: NSAccessibilityPriorityLevel.medium.rawValue
                ]
            )
        }
        pendingAnnouncement = announcement
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: announcement)
    }

    private func scheduleLayoutReport(_ metrics: PromptLayoutMetrics) {
        if let lastReportedMetrics,
           centersMatch(lastReportedMetrics.firstLineCenter, metrics.firstLineCenter),
           centersMatch(lastReportedMetrics.lastLineCenter, metrics.lastLineCenter),
           lastReportedMetrics.lineCenters == metrics.lineCenters,
           abs(lastReportedMetrics.viewportHeight - metrics.viewportHeight) <= 0.25 {
            return
        }

        pendingMetrics = metrics
        guard !layoutReportScheduled else { return }
        layoutReportScheduled = true

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.layoutReportScheduled = false
            guard let metrics = self.pendingMetrics else { return }
            self.pendingMetrics = nil
            self.lastReportedMetrics = metrics
            self.onLayout?(metrics)
        }
    }

    private func centersMatch(_ lhs: CGFloat?, _ rhs: CGFloat?) -> Bool {
        switch (lhs, rhs) {
        case let (lhs?, rhs?):
            return abs(lhs - rhs) <= 0.25
        case (nil, nil):
            return true
        default:
            return false
        }
    }
}
