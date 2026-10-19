import CoreGraphics

public struct PanelScreenGeometry {
    public let frame: CGRect
    public let visibleFrame: CGRect
    public let safeAreaTop: CGFloat
    public let auxiliaryTopLeftArea: CGRect?
    public let auxiliaryTopRightArea: CGRect?

    public init(
        frame: CGRect,
        visibleFrame: CGRect,
        safeAreaTop: CGFloat,
        auxiliaryTopLeftArea: CGRect?,
        auxiliaryTopRightArea: CGRect?
    ) {
        self.frame = frame
        self.visibleFrame = visibleFrame
        self.safeAreaTop = safeAreaTop
        self.auxiliaryTopLeftArea = auxiliaryTopLeftArea
        self.auxiliaryTopRightArea = auxiliaryTopRightArea
    }
}

public enum PanelGeometry {
    public static let collapsedSideClearance: CGFloat = 148

    public static func placement(for screen: PanelScreenGeometry, expanded: Bool) -> CGRect {
        let notch = notchSpan(for: screen)
        let panelTop = notch == nil ? screen.visibleFrame.maxY : screen.frame.maxY
        let horizontalBounds = screen.visibleFrame
        let centerX = notch?.midX ?? horizontalBounds.midX
        let availableWidth = max(horizontalBounds.width - 16, 1)
        let anchorWidth = notch?.width ?? 220
        let collapsedWidth = min(
            max(anchorWidth + collapsedSideClearance * 2, 520),
            min(680, availableWidth)
        )
        let width = expanded ? min(640, availableWidth) : collapsedWidth
        let desiredContentHeight: CGFloat = expanded ? 420 : 50
        let availableHeight = max(panelTop - horizontalBounds.minY, 1)
        let height = min(desiredContentHeight, availableHeight)
        let x = min(
            max(centerX - width / 2, horizontalBounds.minX + 8),
            horizontalBounds.maxX - width - 8
        )

        return CGRect(x: x, y: panelTop - height, width: width, height: height)
    }

    public static func topInset(for screen: PanelScreenGeometry) -> CGFloat {
        notchSpan(for: screen) == nil ? 0 : max(screen.safeAreaTop, 0)
    }

    public static func notchSpan(for screen: PanelScreenGeometry) -> CGRect? {
        guard screen.safeAreaTop > 0,
              let left = screen.auxiliaryTopLeftArea,
              let right = screen.auxiliaryTopRightArea else {
            return nil
        }
        let width = right.minX - left.maxX
        guard width >= 40, width <= 400 else { return nil }
        return CGRect(
            x: left.maxX,
            y: screen.frame.maxY - screen.safeAreaTop,
            width: width,
            height: screen.safeAreaTop
        )
    }
}
