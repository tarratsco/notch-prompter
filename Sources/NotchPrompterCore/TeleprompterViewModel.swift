import Combine
import Foundation

public final class TeleprompterViewModel: ObservableObject {
    public static let sampleScript = """
    Good evening.

    Keep your eyes near the camera and let the words come to you.

    Notch Prompter moves at your pace, so you can focus on the delivery—not the controls.

    Take a breath. You’re live in three, two, one.
    """

    @Published public var scriptText: String {
        didSet {
            guard scriptText != oldValue else { return }
            stopAndResetPosition()
        }
    }
    @Published public private(set) var isPlaying = false
    @Published public var wordsPerMinute: Double {
        didSet {
            let clamped = Self.clamp(wordsPerMinute, to: PlaybackMath.wordsPerMinuteRange)
            if wordsPerMinute != clamped { wordsPerMinute = clamped }
        }
    }
    @Published public var speedMultiplier: Double {
        didSet {
            let clamped = Self.clamp(speedMultiplier, to: PlaybackMath.speedMultiplierRange)
            if speedMultiplier != clamped { speedMultiplier = clamped }
        }
    }
    @Published public var fontSize: Double {
        didSet {
            let clamped = Self.clamp(fontSize, to: PlaybackMath.fontSizeRange)
            if fontSize != clamped { fontSize = clamped }
        }
    }
    @Published public private(set) var scrollOffset = 0.0
    @Published public private(set) var progress = 0.0
    @Published public var countdownEnabled = true
    @Published public private(set) var countdownValue: Int?
    @Published public var isPanelVisible = true
    @Published public var isPanelExpanded = true
    @Published public var panelTopInset: CGFloat = 0
    @Published public var errorMessage: String?
    @Published public private(set) var manualNavigationRevision = 0

    public private(set) var firstLineCenter: CGFloat?
    public private(set) var lastLineCenter: CGFloat?
    public private(set) var visualLineCenters: [CGFloat] = []
    public private(set) var viewportHeight = 0.0

    private var cachedWordCount: Int
    private var countdownRemaining = 0.0
    private var timer: Timer?
    private var previousTick: TimeInterval?
    private let automaticallyRunsTimer: Bool

    public init(
        scriptText: String = TeleprompterViewModel.sampleScript,
        wordsPerMinute: Double = 150,
        speedMultiplier: Double = 1,
        fontSize: Double = 38,
        startsTimer: Bool = true
    ) {
        self.scriptText = scriptText
        self.cachedWordCount = PlaybackMath.wordCount(in: scriptText)
        self.wordsPerMinute = Self.clamp(wordsPerMinute, to: PlaybackMath.wordsPerMinuteRange)
        self.speedMultiplier = Self.clamp(speedMultiplier, to: PlaybackMath.speedMultiplierRange)
        self.fontSize = Self.clamp(fontSize, to: PlaybackMath.fontSizeRange)
        self.automaticallyRunsTimer = startsTimer
    }

    deinit {
        timer?.invalidate()
    }

    public var wordCount: Int {
        cachedWordCount
    }

    public var estimatedDuration: TimeInterval {
        PlaybackMath.estimatedDuration(
            wordCount: wordCount,
            wordsPerMinute: wordsPerMinute,
            speedMultiplier: speedMultiplier
        )
    }

    public var maximumScrollOffset: Double {
        Double(ReadingGuide.scrollDistance(
            firstLineCenter: firstLineCenter,
            lastLineCenter: lastLineCenter
        ))
    }

    public var statusText: String {
        if let countdownValue { return "STANDBY \(countdownValue)" }
        if isPlaying { return "LIVE" }
        if progress >= 1, maximumScrollOffset > 0 { return "COMPLETE" }
        return "READY"
    }

    public var canSeekBackward: Bool {
        scrollOffset > 0.5
    }

    public var canSeekForward: Bool {
        maximumScrollOffset - scrollOffset > 0.5
    }

    public func togglePlayback() {
        if isPlaying || countdownValue != nil {
            pause()
        } else {
            start()
        }
    }

    public func start() {
        guard !scriptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Add a script before starting the prompter."
            return
        }
        if progress >= 1 {
            reset()
        }
        if countdownEnabled {
            isPlaying = false
            countdownRemaining = 3
            countdownValue = 3
        } else {
            countdownValue = nil
            isPlaying = true
        }
        previousTick = ProcessInfo.processInfo.systemUptime
        startTimerIfNeeded()
    }

    public func pause() {
        isPlaying = false
        countdownValue = nil
        countdownRemaining = 0
        previousTick = nil
        stopTimer()
    }

    public func reset() {
        pause()
        scrollOffset = 0
        progress = 0
    }

    public func seek(byPoints delta: Double) {
        pause()
        let distance = maximumScrollOffset
        guard distance > 0 else {
            scrollOffset = 0
            progress = 0
            return
        }
        scrollOffset = min(max(scrollOffset + delta, 0), distance)
        progress = scrollOffset / distance
        manualNavigationRevision &+= 1
    }

    public func seek(toProgress newProgress: Double) {
        pause()
        progress = min(max(newProgress, 0), 1)
        scrollOffset = maximumScrollOffset * progress
        manualNavigationRevision &+= 1
    }

    public func stepVisualLine(_ direction: Int) {
        guard direction != 0,
              let firstLineCenter,
              !visualLineCenters.isEmpty else {
            return
        }
        let currentCenter = firstLineCenter + CGFloat(scrollOffset)
        let tolerance: CGFloat = 0.5
        let targetCenter: CGFloat?
        if direction < 0 {
            targetCenter = visualLineCenters.last {
                $0 < currentCenter - tolerance
            } ?? visualLineCenters.first
        } else {
            targetCenter = visualLineCenters.first {
                $0 > currentCenter + tolerance
            } ?? visualLineCenters.last
        }
        guard let targetCenter else { return }
        seek(byPoints: Double(targetCenter - currentCenter))
    }

    public func updateLayout(_ metrics: PromptLayoutMetrics) {
        firstLineCenter = metrics.firstLineCenter
        lastLineCenter = metrics.lastLineCenter
        visualLineCenters = metrics.lineCenters
        viewportHeight = Double(metrics.viewportHeight)
        scrollOffset = maximumScrollOffset * progress
    }

    public func loadScript(from url: URL) {
        let accessed = url.startAccessingSecurityScopedResource()
        defer {
            if accessed { url.stopAccessingSecurityScopedResource() }
        }
        do {
            scriptText = try ScriptLoader.load(from: url)
            errorMessage = nil
        } catch let error as LocalizedError {
            errorMessage = error.errorDescription ?? "The script could not be loaded."
        } catch {
            errorMessage = "The script could not be loaded: \(error.localizedDescription)"
        }
    }

    /// Public to make playback deterministic in unit tests.
    public func advance(by delta: TimeInterval) {
        guard delta > 0 else { return }
        var remainingDelta = delta

        if countdownValue != nil {
            let countdownDelta = min(remainingDelta, countdownRemaining)
            countdownRemaining -= countdownDelta
            remainingDelta -= countdownDelta
            if countdownRemaining > 0 {
                countdownValue = Int(ceil(countdownRemaining))
                return
            }
            countdownValue = nil
            isPlaying = true
        }

        guard isPlaying, remainingDelta > 0 else { return }
        let distance = maximumScrollOffset
        let duration = estimatedDuration
        guard duration > 0 else {
            isPlaying = false
            progress = scriptText.isEmpty ? 0 : 1
            scrollOffset = distance * progress
            stopTimer()
            return
        }
        progress = min(progress + remainingDelta / duration, 1)
        scrollOffset = distance * progress
        if progress >= 1 {
            scrollOffset = distance
            progress = 1
            isPlaying = false
            stopTimer()
        }
    }

    public func rebaseTimingClock() {
        guard timer != nil else { return }
        previousTick = ProcessInfo.processInfo.systemUptime
    }

    var hasActiveTimer: Bool {
        timer != nil
    }

    private func startTimerIfNeeded() {
        guard automaticallyRunsTimer, timer == nil else { return }
        let newTimer = Timer(timeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            let now = ProcessInfo.processInfo.systemUptime
            guard let previousTick = self.previousTick else {
                self.previousTick = now
                return
            }
            let delta = max(now - previousTick, 0)
            self.previousTick = now
            self.advance(by: delta)
        }
        RunLoop.main.add(newTimer, forMode: .common)
        timer = newTimer
    }

    private func stopAndResetPosition() {
        cachedWordCount = PlaybackMath.wordCount(in: scriptText)
        isPlaying = false
        countdownValue = nil
        countdownRemaining = 0
        previousTick = nil
        stopTimer()
        scrollOffset = 0
        progress = 0
        firstLineCenter = nil
        lastLineCenter = nil
        visualLineCenters = []
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private static func clamp(_ value: Double, to range: ClosedRange<Double>) -> Double {
        min(max(value, range.lowerBound), range.upperBound)
    }
}
