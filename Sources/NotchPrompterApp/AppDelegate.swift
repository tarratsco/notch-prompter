import AppKit
import Combine
import NotchPrompterCore
import OSLog
import SwiftUI
import UniformTypeIdentifiers

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private let logger = Logger(subsystem: "com.local.NotchPrompter", category: "App")
    private let model = TeleprompterViewModel()
    private let commands = AppCommands()
    private var editorWindow: NSWindow!
    private var panelController: NotchPanelController!
    private var statusItem: NSStatusItem!
    private var globalHotKey: GlobalHotKey?
    private var workspaceObservers: [NSObjectProtocol] = []
    private var hotKeyRegistrationError: String?
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        configureCommands()
        createEditorWindow()
        panelController = NotchPanelController(model: model, editorWindow: editorWindow)
        createMainMenu()
        createStatusItem()
        registerGlobalHotKey()
        observeWorkspacePowerEvents()

        editorWindow.makeKeyAndOrderFront(nil)
        panelController.show()
        NSApp.activate(ignoringOtherApps: true)

        Publishers.CombineLatest4(
            model.$isPlaying,
            model.$countdownValue,
            model.$isPanelVisible,
            model.$isPanelExpanded
        )
            .sink { [weak self] _, _, _, _ in self?.refreshStatusMenu() }
            .store(in: &cancellables)
    }

    func applicationWillTerminate(_ notification: Notification) {
        globalHotKey?.unregister()
        globalHotKey = nil
        let center = NSWorkspace.shared.notificationCenter
        workspaceObservers.forEach(center.removeObserver)
        workspaceObservers.removeAll()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        sender.orderOut(nil)
        return false
    }

    private func configureCommands() {
        commands.openDocument = { [weak self] in self?.openDocument() }
        commands.showEditor = { [weak self] in self?.showEditor() }
        commands.togglePanelVisibility = { [weak self] in self?.syncPanelVisibility() }
        commands.panelExpansionChanged = { [weak self] in self?.panelController?.reposition(animated: true) }
        commands.quit = { NSApp.terminate(nil) }
    }

    private func createEditorWindow() {
        let view = EditorView(model: model, commands: commands)
        editorWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1040, height: 680),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        editorWindow.title = "Notch Prompter"
        editorWindow.titleVisibility = .hidden
        editorWindow.titlebarAppearsTransparent = true
        editorWindow.isMovableByWindowBackground = true
        editorWindow.minSize = NSSize(width: 820, height: 570)
        editorWindow.isReleasedWhenClosed = false
        editorWindow.delegate = self
        editorWindow.contentView = NSHostingView(rootView: view)
        editorWindow.center()
    }

    private func createMainMenu() {
        let mainMenu = NSMenu()

        let applicationItem = NSMenuItem()
        mainMenu.addItem(applicationItem)
        let applicationMenu = NSMenu()
        applicationMenu.addItem(withTitle: "About Notch Prompter", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        applicationMenu.addItem(.separator())
        let quitItem = NSMenuItem(title: "Quit Notch Prompter", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        applicationMenu.addItem(quitItem)
        applicationItem.submenu = applicationMenu

        let fileItem = NSMenuItem()
        mainMenu.addItem(fileItem)
        let fileMenu = NSMenu(title: "File")
        let openItem = NSMenuItem(title: "Open Script…", action: #selector(openScript), keyEquivalent: "o")
        openItem.target = self
        fileMenu.addItem(openItem)
        fileItem.submenu = fileMenu

        let editItem = NSMenuItem()
        mainMenu.addItem(editItem)
        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
        editMenu.addItem(withTitle: "Redo", action: Selector(("redo:")), keyEquivalent: "Z")
        editMenu.addItem(.separator())
        editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editItem.submenu = editMenu

        let controlItem = NSMenuItem()
        mainMenu.addItem(controlItem)
        let controlMenu = NSMenu(title: "Controls")
        let playItem = NSMenuItem(title: "Play / Pause", action: #selector(togglePlayback), keyEquivalent: "p")
        playItem.keyEquivalentModifierMask = [.command, .shift]
        playItem.target = self
        controlMenu.addItem(playItem)
        let resetItem = NSMenuItem(title: "Reset", action: #selector(resetPlayback), keyEquivalent: "r")
        resetItem.keyEquivalentModifierMask = [.command, .shift]
        resetItem.target = self
        controlMenu.addItem(resetItem)
        controlItem.submenu = controlMenu

        let windowItem = NSMenuItem()
        mainMenu.addItem(windowItem)
        let windowMenu = NSMenu(title: "Window")
        let closeItem = NSMenuItem(title: "Close Window", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        windowMenu.addItem(closeItem)
        let minimizeItem = NSMenuItem(title: "Minimize", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
        windowMenu.addItem(minimizeItem)
        windowMenu.addItem(.separator())
        let showItem = NSMenuItem(title: "Show Editor", action: #selector(showEditorAction), keyEquivalent: "1")
        showItem.keyEquivalentModifierMask = [.command]
        showItem.target = self
        windowMenu.addItem(showItem)
        windowItem.submenu = windowMenu
        NSApp.windowsMenu = windowMenu

        NSApp.mainMenu = mainMenu
    }

    private func createStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "captions.bubble.fill", accessibilityDescription: "Notch Prompter")
            button.toolTip = "Notch Prompter"
        }
        refreshStatusMenu()
    }

    private func refreshStatusMenu() {
        guard statusItem != nil else { return }
        let menu = NSMenu()
        let status = NSMenuItem(title: "Status: \(model.statusText)", action: nil, keyEquivalent: "")
        status.isEnabled = false
        menu.addItem(status)
        if let hotKeyRegistrationError {
            let shortcutStatus = NSMenuItem(title: hotKeyRegistrationError, action: nil, keyEquivalent: "")
            shortcutStatus.isEnabled = false
            menu.addItem(shortcutStatus)
        }
        menu.addItem(.separator())

        let playback = NSMenuItem(
            title: model.isPlaying || model.countdownValue != nil ? "Pause" : "Play",
            action: #selector(togglePlayback),
            keyEquivalent: ""
        )
        playback.image = NSImage(
            systemSymbolName: model.isPlaying || model.countdownValue != nil ? "pause.fill" : "play.fill",
            accessibilityDescription: nil
        )
        playback.target = self
        menu.addItem(playback)

        let editor = NSMenuItem(title: "Show Editor", action: #selector(showEditorAction), keyEquivalent: "")
        editor.target = self
        menu.addItem(editor)

        let panel = NSMenuItem(
            title: model.isPanelVisible ? "Hide Notch Panel" : "Show Notch Panel",
            action: #selector(togglePanel),
            keyEquivalent: ""
        )
        panel.target = self
        menu.addItem(panel)

        let expansion = NSMenuItem(
            title: model.isPanelExpanded ? "Collapse Panel" : "Expand Panel",
            action: #selector(togglePanelExpansion),
            keyEquivalent: ""
        )
        expansion.target = self
        menu.addItem(expansion)

        menu.addItem(.separator())
        let quit = NSMenuItem(title: "Quit Notch Prompter", action: #selector(quitApp), keyEquivalent: "")
        quit.target = self
        menu.addItem(quit)
        statusItem.menu = menu
    }

    private func registerGlobalHotKey() {
        let hotKey = GlobalHotKey { [weak self] in
            self?.model.togglePlayback()
        }
        let status = hotKey.register()
        guard status == noErr else {
            let message = "Global shortcut unavailable (error \(status)). Command-Shift-P still works from the app menu."
            hotKeyRegistrationError = message
            model.errorMessage = message
            logger.error("\(message, privacy: .public)")
            refreshStatusMenu()
            return
        }
        globalHotKey = hotKey
    }

    private func observeWorkspacePowerEvents() {
        let center = NSWorkspace.shared.notificationCenter
        workspaceObservers.append(center.addObserver(
            forName: NSWorkspace.willSleepNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.model.pause()
        })
        workspaceObservers.append(center.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.model.rebaseTimingClock()
        })
    }

    private func openDocument() {
        let panel = NSOpenPanel()
        panel.title = "Open a Script"
        panel.prompt = "Open"
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [
            .plainText,
            UTType(filenameExtension: "md") ?? .plainText,
            UTType(filenameExtension: "markdown") ?? .plainText
        ]
        panel.beginSheetModal(for: editorWindow) { [weak self] response in
            guard response == .OK, let url = panel.url else { return }
            self?.model.loadScript(from: url)
        }
    }

    private func showEditor() {
        editorWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func syncPanelVisibility() {
        if model.isPanelVisible {
            panelController.show()
        }
    }

    @objc private func openScript() { openDocument() }
    @objc private func showEditorAction() { showEditor() }
    @objc private func togglePlayback() { model.togglePlayback() }
    @objc private func resetPlayback() { model.reset() }
    @objc private func quitApp() { NSApp.terminate(nil) }

    @objc private func togglePanel() {
        model.isPanelVisible.toggle()
        syncPanelVisibility()
    }

    @objc private func togglePanelExpansion() {
        model.isPanelExpanded.toggle()
        panelController.reposition(animated: true)
    }
}
