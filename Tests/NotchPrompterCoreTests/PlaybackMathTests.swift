import Testing
@testable import NotchPrompterCore

@Suite("Playback")
struct PlaybackMathTests {
    @Test("Duration uses WPM and speed multiplier")
    func durationUsesWordsPerMinuteAndMultiplier() {
        let normal = PlaybackMath.estimatedDuration(wordCount: 300, wordsPerMinute: 150, speedMultiplier: 1)
        let faster = PlaybackMath.estimatedDuration(wordCount: 300, wordsPerMinute: 150, speedMultiplier: 1.5)
        #expect(abs(normal - 120) < 0.001)
        #expect(abs(faster - 80) < 0.001)
    }

    @Test("Playback stops at the end")
    func playbackStopsAtEnd() {
        let words = Array(repeating: "word", count: 100).joined(separator: " ")
        let model = TeleprompterViewModel(
            scriptText: words,
            wordsPerMinute: 100,
            speedMultiplier: 1,
            fontSize: 40,
            startsTimer: false
        )
        model.countdownEnabled = false
        model.updateLayout(PromptLayoutMetrics(
            firstLineCenter: 20,
            lastLineCenter: 1_000,
            viewportHeight: 200
        ))
        model.start()
        model.advance(by: 60)

        #expect(abs(model.progress - 1) < 0.001)
        #expect(!model.isPlaying)
    }

    @Test("Countdown precedes playback and pause cancels it")
    func countdownPrecedesPlaybackAndPauseCancelsIt() {
        let model = TeleprompterViewModel(scriptText: "A short script", startsTimer: false)
        model.start()
        #expect(model.countdownValue == 3)
        #expect(!model.isPlaying)

        model.advance(by: 1)
        #expect(model.countdownValue == 2)
        model.advance(by: 2)
        #expect(model.countdownValue == nil)
        #expect(model.isPlaying)

        model.pause()
        #expect(!model.isPlaying)
        #expect(model.countdownValue == nil)
    }

    @Test("Settings are clamped to safe ranges")
    func settingsAreClampedToSafeRanges() {
        let model = TeleprompterViewModel(
            wordsPerMinute: 10,
            speedMultiplier: 9,
            fontSize: 8,
            startsTimer: false
        )
        #expect(model.wordsPerMinute == 60)
        #expect(model.speedMultiplier == 2)
        #expect(model.fontSize == 24)

        model.wordsPerMinute = 1_000
        model.speedMultiplier = 0
        model.fontSize = 200
        #expect(model.wordsPerMinute == 400)
        #expect(model.speedMultiplier == 0.5)
        #expect(model.fontSize == 72)
    }

    @Test("Irregular ticks preserve exact accumulated playback time")
    func irregularTicksAccumulateWithoutDrift() {
        let words = Array(repeating: "word", count: 120).joined(separator: " ")
        let model = TeleprompterViewModel(
            scriptText: words,
            wordsPerMinute: 120,
            speedMultiplier: 1,
            startsTimer: false
        )
        model.countdownEnabled = false
        model.updateLayout(PromptLayoutMetrics(
            firstLineCenter: 16,
            lastLineCenter: 1_000,
            viewportHeight: 200
        ))
        model.start()

        [0.016, 0.243, 1.7, 0.041, 13.0].forEach(model.advance)

        #expect(abs(model.progress - 0.25) < 0.000_001)
    }

    @Test("A tick crossing countdown applies its remaining time to playback")
    func countdownCarriesRemainingTickIntoPlayback() {
        let words = Array(repeating: "word", count: 60).joined(separator: " ")
        let model = TeleprompterViewModel(
            scriptText: words,
            wordsPerMinute: 60,
            speedMultiplier: 1,
            startsTimer: false
        )
        model.updateLayout(PromptLayoutMetrics(
            firstLineCenter: 16,
            lastLineCenter: 1_000,
            viewportHeight: 200
        ))
        model.start()

        model.advance(by: 3.5)

        #expect(model.countdownValue == nil)
        #expect(model.isPlaying)
        #expect(abs(model.progress - (0.5 / 60.0)) < 0.000_001)
    }

    @Test("The display timer only runs during active work")
    func timerLifecycleTracksPlayback() {
        let model = TeleprompterViewModel(scriptText: "one two", startsTimer: true)
        #expect(!model.hasActiveTimer)

        model.start()
        #expect(model.hasActiveTimer)

        model.pause()
        #expect(!model.hasActiveTimer)

        model.start()
        model.scriptText = "replacement"
        #expect(!model.hasActiveTimer)
    }

    @Test("Manual point seeking pauses and clamps to the script")
    func manualPointSeekingPausesAndClamps() {
        let model = TeleprompterViewModel(
            scriptText: Array(repeating: "word", count: 60).joined(separator: " "),
            startsTimer: false
        )
        model.countdownEnabled = false
        model.updateLayout(PromptLayoutMetrics(
            firstLineCenter: 20,
            lastLineCenter: 220,
            viewportHeight: 200
        ))
        model.start()
        model.seek(byPoints: 80)

        #expect(!model.isPlaying)
        #expect(model.scrollOffset == 80)
        #expect(abs(model.progress - 0.4) < 0.000_001)

        model.seek(byPoints: -1_000)
        #expect(model.scrollOffset == 0)
        #expect(model.progress == 0)

        model.seek(byPoints: 1_000)
        #expect(model.scrollOffset == 200)
        #expect(model.progress == 1)
    }

    @Test("Progress scrubbing and line steps update the offset")
    func progressScrubbingAndLineSteps() {
        let model = TeleprompterViewModel(fontSize: 40, startsTimer: false)
        model.updateLayout(PromptLayoutMetrics(
            firstLineCenter: 20,
            lastLineCenter: 220,
            lineCenters: [20, 75, 140, 220],
            viewportHeight: 200
        ))

        model.seek(toProgress: 0.25)
        #expect(model.scrollOffset == 50)
        #expect(model.progress == 0.25)

        model.stepVisualLine(-1)
        #expect(abs(model.scrollOffset - 0) < 0.000_001)
        #expect(!model.canSeekBackward)

        model.stepVisualLine(1)
        #expect(abs(model.scrollOffset - 55) < 0.000_001)
        #expect(abs(model.progress - 0.275) < 0.000_001)
        #expect(model.canSeekBackward)
        #expect(model.canSeekForward)

        model.stepVisualLine(1)
        #expect(abs(model.scrollOffset - 120) < 0.000_001)

        model.stepVisualLine(1)
        #expect(abs(model.scrollOffset - 200) < 0.000_001)
        #expect(!model.canSeekForward)
    }
}
