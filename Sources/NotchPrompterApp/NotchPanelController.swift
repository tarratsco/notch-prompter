import AppKit
import Combine
import NotchPrompterCore
import SwiftUI

private final class PassivePanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

final class NotchPanelController {
    private let model: TeleprompterViewModel
    private let panel: NSPanel
    private weak var editorWindow: NSWindow?
    private var cancellables = Set<AnyCancellable>()
    private var observers: [NSObjectProtocol] = []

    init(model: TeleprompterViewModel, editorWindow: NSWindow) {
        self.model = model
        self.editorWindow = editorWindow
        panel = PassivePanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.hidesOnDeactivate = false
        panel.isMovable = false
        panel.isReleasedWhenClosed = false
        panel.title = "Notch Prompter Panel"
        panel.contentView = NSHostingView(
            rootView: PrompterPanelView(
                model: model,
                expansionChanged: { [weak self] in
                    self?.reposition(animated: true)
                },
                openEditor: { [weak self] in
                    self?.showEditor()
                }
            )
        )
        model.$isPanelExpanded
            .removeDuplicates()
            .sink { [weak self] _ in self?.reposition(animated: true) }
            .store(in: &cancellables)

        model.$isPanelVisible
            .removeDuplicates()
            .sink { [weak self] visible in
                visible ? self?.show() : self?.panel.orderOut(nil)
            }
            .store(in: &cancellables)

        let center = NotificationCenter.default
        observers.append(center.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in self?.reposition(animated: false) })
        observers.append(center.addObserver(
            forName: NSWindow.didChangeScreenNotification,
            object: editorWindow,
            queue: .main
        ) { [weak self] _ in self?.reposition(animated: false) })
    }

    deinit {
        observers.forEach(NotificationCenter.default.removeObserver)
    }

    func show() {
        guard model.isPanelVisible else { return }
        reposition(animated: false)
        panel.orderFrontRegardless()
    }

    func reposition(animated: Bool) {
        guard let screen = targetScreen else { return }
        let geometry = Self.geometry(for: screen)
        model.panelTopInset = PanelGeometry.topInset(for: geometry)
        let placement = PanelGeometry.placement(for: geometry, expanded: model.isPanelExpanded)
        if animated {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion ? 0 : 0.18
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                panel.animator().setFrame(placement, display: true)
            }
        } else {
            panel.setFrame(placement, display: true)
        }
    }

    private var targetScreen: NSScreen? {
        if let screen = editorWindow?.screen { return screen }
        let mouse = NSEvent.mouseLocation
        return NSScreen.screens.first(where: { NSMouseInRect(mouse, $0.frame, false) }) ?? NSScreen.main
    }

    private func showEditor() {
        guard let editorWindow else { return }
        editorWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    static func placement(for screen: NSScreen, expanded: Bool) -> NSRect {
        PanelGeometry.placement(for: geometry(for: screen), expanded: expanded)
    }

    private static func geometry(for screen: NSScreen) -> PanelScreenGeometry {
        PanelScreenGeometry(
            frame: screen.frame,
            visibleFrame: screen.visibleFrame,
            safeAreaTop: screen.safeAreaInsets.top,
            auxiliaryTopLeftArea: screen.auxiliaryTopLeftArea,
            auxiliaryTopRightArea: screen.auxiliaryTopRightArea
        )
    }
}
