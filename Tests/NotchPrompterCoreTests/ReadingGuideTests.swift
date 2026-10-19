import CoreGraphics
import Testing
@testable import NotchPrompterCore

@Suite("Reading guide geometry")
struct ReadingGuideTests {
    @Test("Guide is twenty-two percent down the prompt viewport")
    func guideUsesRaisedFraction() {
        #expect(ReadingGuide.viewportFraction == 0.22)
        #expect(abs(ReadingGuide.position(in: 310) - 68.2) < 0.000_001)
        #expect(ReadingGuide.position(in: -20) == 0)
    }

    @Test("Zero offset centers the first visual line on the guide")
    func firstLineStartsAtGuide() {
        let viewportHeight: CGFloat = 310
        let firstLineCenter: CGFloat = 24
        let origin = ReadingGuide.textOriginY(
            viewportHeight: viewportHeight,
            firstLineCenter: firstLineCenter,
            scrollOffset: 0
        )

        #expect(abs(origin + firstLineCenter - ReadingGuide.position(in: viewportHeight)) < 0.000_001)
    }

    @Test("Exact fragment centers define the complete scroll distance")
    func fragmentCentersDefineScrollDistance() {
        let firstLineCenter: CGFloat = 24
        let lastLineCenter: CGFloat = 486
        let distance = ReadingGuide.scrollDistance(
            firstLineCenter: firstLineCenter,
            lastLineCenter: lastLineCenter
        )
        let originAtCompletion = ReadingGuide.textOriginY(
            viewportHeight: 310,
            firstLineCenter: firstLineCenter,
            scrollOffset: distance
        )

        #expect(distance == 462)
        #expect(abs(originAtCompletion + lastLineCenter - ReadingGuide.position(in: 310)) < 0.000_001)
    }

    @Test("Missing or reversed fragments do not scroll")
    func invalidFragmentExtentsDoNotScroll() {
        #expect(ReadingGuide.scrollDistance(firstLineCenter: nil, lastLineCenter: 40) == 0)
        #expect(ReadingGuide.scrollDistance(firstLineCenter: 80, lastLineCenter: 20) == 0)
    }

    @Test("View model uses exact fragment-center distance")
    func modelUsesFragmentCenters() {
        let model = TeleprompterViewModel(scriptText: "one two", startsTimer: false)
        model.updateLayout(PromptLayoutMetrics(
            firstLineCenter: 24,
            lastLineCenter: 486,
            viewportHeight: 310
        ))

        #expect(model.maximumScrollOffset == 462)
        #expect(model.firstLineCenter == 24)
        #expect(model.lastLineCenter == 486)
        #expect(model.viewportHeight == 310)
    }

    @Test("Completion lands the last fragment center on the guide")
    func completionUsesExactDistance() {
        let words = Array(repeating: "word", count: 60).joined(separator: " ")
        let model = TeleprompterViewModel(
            scriptText: words,
            wordsPerMinute: 60,
            startsTimer: false
        )
        model.countdownEnabled = false
        model.updateLayout(PromptLayoutMetrics(
            firstLineCenter: 24,
            lastLineCenter: 486,
            viewportHeight: 310
        ))

        model.start()
        model.advance(by: 60)

        #expect(model.scrollOffset == 462)
        #expect(model.progress == 1)
        #expect(!model.isPlaying)
    }

    @Test("Layout changes preserve time-based progress")
    func layoutChangesPreserveProgress() {
        let words = Array(repeating: "word", count: 60).joined(separator: " ")
        let model = TeleprompterViewModel(
            scriptText: words,
            wordsPerMinute: 60,
            startsTimer: false
        )
        model.countdownEnabled = false
        model.updateLayout(PromptLayoutMetrics(
            firstLineCenter: 20,
            lastLineCenter: 1_020,
            viewportHeight: 310
        ))
        model.start()
        model.advance(by: 15)

        model.updateLayout(PromptLayoutMetrics(
            firstLineCenter: 30,
            lastLineCenter: 830,
            viewportHeight: 260
        ))

        #expect(model.progress == 0.25)
        #expect(model.maximumScrollOffset == 800)
        #expect(model.scrollOffset == 200)

        model.advance(by: 45)
        #expect(model.scrollOffset == 800)
        #expect(model.progress == 1)
    }

    @Test("A single visual line remains live for its WPM duration")
    func singleLineUsesReadingDuration() {
        let words = Array(repeating: "word", count: 60).joined(separator: " ")
        let model = TeleprompterViewModel(
            scriptText: words,
            wordsPerMinute: 60,
            startsTimer: false
        )
        model.countdownEnabled = false
        model.updateLayout(PromptLayoutMetrics(
            firstLineCenter: 24,
            lastLineCenter: 24,
            viewportHeight: 310
        ))
        model.start()

        model.advance(by: 30)
        #expect(model.progress == 0.5)
        #expect(model.scrollOffset == 0)
        #expect(model.isPlaying)

        model.advance(by: 30)
        #expect(model.progress == 1)
        #expect(!model.isPlaying)
    }
}
