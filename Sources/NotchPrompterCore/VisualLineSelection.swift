import CoreGraphics

public enum VisualLineSelection {
    public static func activeFragmentIndex(
        guideY: CGFloat,
        fragmentRects: [CGRect]
    ) -> Int? {
        guard guideY.isFinite else { return nil }

        return fragmentRects.firstIndex { rect in
            guard !rect.isNull, !rect.isInfinite, rect.height > 0 else { return false }
            return guideY >= rect.minY && guideY < rect.maxY
        }
    }
}
