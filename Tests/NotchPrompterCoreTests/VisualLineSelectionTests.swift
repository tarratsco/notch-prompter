import CoreGraphics
import Testing
@testable import NotchPrompterCore

@Suite("Visual line selection")
struct VisualLineSelectionTests {
    private let wrappedLines = [
        CGRect(x: 0, y: 0, width: 300, height: 42),
        CGRect(x: 0, y: 42, width: 270, height: 42),
        CGRect(x: 0, y: 84, width: 190, height: 42)
    ]

    @Test("Guide selects the intersecting wrapped fragment")
    func selectsWrappedFragment() {
        #expect(VisualLineSelection.activeFragmentIndex(guideY: 8, fragmentRects: wrappedLines) == 0)
        #expect(VisualLineSelection.activeFragmentIndex(guideY: 63, fragmentRects: wrappedLines) == 1)
        #expect(VisualLineSelection.activeFragmentIndex(guideY: 120, fragmentRects: wrappedLines) == 2)
    }

    @Test("A shared boundary belongs to the following fragment")
    func assignsBoundaryToFollowingFragment() {
        #expect(VisualLineSelection.activeFragmentIndex(guideY: 42, fragmentRects: wrappedLines) == 1)
        #expect(VisualLineSelection.activeFragmentIndex(guideY: 84, fragmentRects: wrappedLines) == 2)
    }

    @Test("Guide outside laid-out text has no active fragment")
    func returnsNilOutsideText() {
        #expect(VisualLineSelection.activeFragmentIndex(guideY: -0.01, fragmentRects: wrappedLines) == nil)
        #expect(VisualLineSelection.activeFragmentIndex(guideY: 126, fragmentRects: wrappedLines) == nil)
        #expect(VisualLineSelection.activeFragmentIndex(guideY: .infinity, fragmentRects: wrappedLines) == nil)
        #expect(VisualLineSelection.activeFragmentIndex(guideY: 1, fragmentRects: []) == nil)
    }

    @Test("Invalid and empty fragments are ignored")
    func ignoresInvalidFragments() {
        let fragments = [
            CGRect(x: 0, y: 0, width: 100, height: 0),
            CGRect.null,
            CGRect(x: 0, y: 20, width: 100, height: 30)
        ]

        #expect(VisualLineSelection.activeFragmentIndex(guideY: 25, fragmentRects: fragments) == 2)
    }
}
