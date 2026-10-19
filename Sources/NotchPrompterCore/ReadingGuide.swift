import CoreGraphics

public enum ReadingGuide {
    public static let viewportFraction: CGFloat = 0.22

    public static func position(in viewportHeight: CGFloat) -> CGFloat {
        guard viewportHeight.isFinite else { return 0 }
        return max(viewportHeight, 0) * viewportFraction
    }

    public static func textOriginY(
        viewportHeight: CGFloat,
        firstLineCenter: CGFloat,
        scrollOffset: CGFloat
    ) -> CGFloat {
        position(in: viewportHeight) - firstLineCenter - max(scrollOffset, 0)
    }

    public static func scrollDistance(
        firstLineCenter: CGFloat?,
        lastLineCenter: CGFloat?
    ) -> CGFloat {
        guard let firstLineCenter,
              let lastLineCenter,
              firstLineCenter.isFinite,
              lastLineCenter.isFinite else {
            return 0
        }
        return max(lastLineCenter - firstLineCenter, 0)
    }
}

public struct PromptLayoutMetrics: Equatable {
    public let firstLineCenter: CGFloat?
    public let lastLineCenter: CGFloat?
    public let lineCenters: [CGFloat]
    public let viewportHeight: CGFloat

    public init(
        firstLineCenter: CGFloat?,
        lastLineCenter: CGFloat?,
        lineCenters: [CGFloat]? = nil,
        viewportHeight: CGFloat
    ) {
        self.firstLineCenter = firstLineCenter
        self.lastLineCenter = lastLineCenter
        self.lineCenters = lineCenters ?? [firstLineCenter, lastLineCenter]
            .compactMap { $0 }
            .reduce(into: []) { centers, center in
                if centers.last != center { centers.append(center) }
            }
        self.viewportHeight = max(viewportHeight, 0)
    }

    public var maximumScrollOffset: CGFloat {
        ReadingGuide.scrollDistance(
            firstLineCenter: firstLineCenter,
            lastLineCenter: lastLineCenter
        )
    }
}
