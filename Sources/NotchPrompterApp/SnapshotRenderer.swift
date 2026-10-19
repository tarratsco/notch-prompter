#if DEBUG
import AppKit
import NotchPrompterCore
import SwiftUI

enum SnapshotRenderer {
    enum SnapshotError: LocalizedError {
        case bitmapCreationFailed
        case pngEncodingFailed

        var errorDescription: String? {
            switch self {
            case .bitmapCreationFailed:
                return "Could not create a bitmap for the UI snapshot."
            case .pngEncodingFailed:
                return "Could not encode the UI snapshot as PNG."
            }
        }
    }

    static func capture(to directory: URL) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let editorModel = TeleprompterViewModel(startsTimer: false)
        let editor = EditorView(model: editorModel, commands: AppCommands())
        try render(
            editor,
            size: NSSize(width: 1040, height: 680),
            to: directory.appendingPathComponent("editor.png")
        )

        let panelModel = TeleprompterViewModel(startsTimer: false)
        panelModel.isPanelExpanded = true
        panelModel.panelTopInset = 38
        let panel = PrompterPanelView(model: panelModel, expansionChanged: {}, openEditor: {})
        try render(
            panel,
            size: NSSize(width: 640, height: 420),
            to: directory.appendingPathComponent("prompter-panel.png")
        )

        let collapsedModel = TeleprompterViewModel(startsTimer: false)
        collapsedModel.isPanelExpanded = false
        collapsedModel.panelTopInset = 38
        let collapsedPanel = PrompterPanelView(
            model: collapsedModel,
            expansionChanged: {},
            openEditor: {}
        )
        try render(
            collapsedPanel,
            size: NSSize(width: 548, height: 50),
            to: directory.appendingPathComponent("prompter-panel-collapsed.png")
        )
    }

    private static func render<Content: View>(_ content: Content, size: NSSize, to url: URL) throws {
        let hostingView = NSHostingView(rootView: content.frame(width: size.width, height: size.height))
        hostingView.frame = NSRect(origin: .zero, size: size)
        hostingView.appearance = NSAppearance(named: .darkAqua)

        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.appearance = NSAppearance(named: .darkAqua)
        window.contentView = hostingView
        hostingView.layoutSubtreeIfNeeded()
        window.displayIfNeeded()
        hostingView.displayIfNeeded()

        guard let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(size.width),
            pixelsHigh: Int(size.height),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bitmapFormat: [],
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else {
            throw SnapshotError.bitmapCreationFailed
        }
        bitmap.size = size
        hostingView.cacheDisplay(in: hostingView.bounds, to: bitmap)
        guard let data = bitmap.representation(using: .png, properties: [:]) else {
            throw SnapshotError.pngEncodingFailed
        }
        try data.write(to: url, options: .atomic)
    }
}
#endif
