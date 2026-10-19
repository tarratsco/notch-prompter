import Foundation
import Testing
@testable import NotchPrompterCore

@Suite("Panel geometry")
struct PanelGeometryTests {
    @Test("Notched panels reach the screen top and reserve a safe-area cap")
    func notchedScreenUsesTopEdgeCap() {
        let screen = PanelScreenGeometry(
            frame: CGRect(x: 0, y: 0, width: 1512, height: 982),
            visibleFrame: CGRect(x: 0, y: 0, width: 1512, height: 944),
            safeAreaTop: 38,
            auxiliaryTopLeftArea: CGRect(x: 0, y: 944, width: 630, height: 38),
            auxiliaryTopRightArea: CGRect(x: 882, y: 944, width: 630, height: 38)
        )

        let placement = PanelGeometry.placement(for: screen, expanded: true)

        #expect(placement.maxY == screen.frame.maxY)
        #expect(placement.height == 420)
        #expect(placement.midX == 756)
        #expect(PanelGeometry.topInset(for: screen) == 38)
    }

    @Test("Collapsed panel reserves controls on both sides of the notch")
    func collapsedPanelClearsNotchControls() throws {
        let screen = PanelScreenGeometry(
            frame: CGRect(x: 0, y: 0, width: 1512, height: 982),
            visibleFrame: CGRect(x: 0, y: 0, width: 1512, height: 944),
            safeAreaTop: 38,
            auxiliaryTopLeftArea: CGRect(x: 0, y: 944, width: 630, height: 38),
            auxiliaryTopRightArea: CGRect(x: 882, y: 944, width: 630, height: 38)
        )

        let notch = try #require(PanelGeometry.notchSpan(for: screen))
        let placement = PanelGeometry.placement(for: screen, expanded: false)

        #expect(placement.width == notch.width + PanelGeometry.collapsedSideClearance * 2)
        #expect(placement.maxY == screen.frame.maxY)
        #expect(placement.height == 50)
        #expect(placement.minX <= notch.minX - PanelGeometry.collapsedSideClearance)
        #expect(placement.maxX >= notch.maxX + PanelGeometry.collapsedSideClearance)
    }

    @Test("Ordinary screens use the visible frame top")
    func ordinaryScreenUsesVisibleFrameTop() {
        let screen = PanelScreenGeometry(
            frame: CGRect(x: 100, y: 50, width: 1920, height: 1080),
            visibleFrame: CGRect(x: 100, y: 73, width: 1920, height: 1033),
            safeAreaTop: 0,
            auxiliaryTopLeftArea: nil,
            auxiliaryTopRightArea: nil
        )

        let placement = PanelGeometry.placement(for: screen, expanded: false)

        #expect(placement.maxY == screen.visibleFrame.maxY)
        #expect(placement.height == 50)
        #expect(placement.midX == screen.visibleFrame.midX)
        #expect(PanelGeometry.topInset(for: screen) == 0)
    }
}
