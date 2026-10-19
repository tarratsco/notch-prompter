import Foundation

public enum PlaybackMath {
    public static let wordsPerMinuteRange = 60.0...400.0
    public static let speedMultiplierRange = 0.5...2.0
    public static let fontSizeRange = 24.0...72.0

    public static func wordCount(in text: String) -> Int {
        text.split(whereSeparator: { $0.isWhitespace }).count
    }

    public static func estimatedDuration(
        wordCount: Int,
        wordsPerMinute: Double,
        speedMultiplier: Double
    ) -> TimeInterval {
        guard wordCount > 0 else { return 0 }
        let wpm = min(max(wordsPerMinute, wordsPerMinuteRange.lowerBound), wordsPerMinuteRange.upperBound)
        let multiplier = min(max(speedMultiplier, speedMultiplierRange.lowerBound), speedMultiplierRange.upperBound)
        return Double(wordCount) / (wpm * multiplier) * 60
    }

    public static func pointsPerSecond(
        scrollableDistance: Double,
        wordCount: Int,
        wordsPerMinute: Double,
        speedMultiplier: Double
    ) -> Double {
        let duration = estimatedDuration(
            wordCount: wordCount,
            wordsPerMinute: wordsPerMinute,
            speedMultiplier: speedMultiplier
        )
        guard duration > 0, scrollableDistance > 0 else { return 0 }
        return scrollableDistance / duration
    }
}
