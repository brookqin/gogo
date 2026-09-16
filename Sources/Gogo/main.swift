import AppKit
import SwiftUI
import Combine

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private var window: NSWindow?
    private var model: AppModel?
    private var languageObservation: AnyCancellable?

    private var receivedHandoff = false
    private var finishedLaunching = false
    private var pendingRequest: Result<LaunchRequest, Error>?

    func application(_ application: NSApplication, open urls: [URL]) {
        receivedHandoff = true
        pendingRequest = Result {
            guard urls.count == 1, let url = urls.first else { throw GogoError.invalidRequest }
            return try LaunchHandoff.consume(url)
        }
        if finishedLaunching { dispatchPendingRequest() }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        finishedLaunching = true
        let args = CommandLine.arguments
        if args.count == 3, args[1] == "--launch-request" {
            receivedHandoff = true
            pendingRequest = Result { try LaunchRequest.decode(args[2]) }
        }
        if receivedHandoff { dispatchPendingRequest() }
        else if notification.userInfo?[NSApplication.launchIsDefaultUserInfoKey] as? Bool != false {
            showSettings(preview: args.contains("--preview"))
        }
    }

    private func dispatchPendingRequest() {
        guard let request = pendingRequest else { return }
        pendingRequest = nil
        let hasSettingsWindow = window != nil
        if !hasSettingsWindow { NSApp.setActivationPolicy(.accessory) }
        Task {
            var language = AppLanguage.system
            do {
                let config = try SharedConfiguration.file().read()
                language = config.language
                try await LauncherEngine.run(request.get(), configuration: config)
            } catch {
                NSApp.activate(ignoringOtherApps: true)
                let alert = NSAlert()
                alert.messageText = Texts.get("launch.failed", language: language)
                alert.informativeText = Texts.error(error, language: language)
                alert.runModal()
            }
            if window == nil { NSApp.terminate(nil) }
        }
    }

    private func showSettings(preview: Bool) {
        NSApp.setActivationPolicy(.regular)
        let model = AppModel(preview: preview)
        self.model = model
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1040, height: 660),
                              styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
        window.title = preview ? "gogo · Preview" : "gogo"
        window.minSize = NSSize(width: 980, height: 620)
        window.contentView = NSHostingView(rootView: SettingsView(model: model))
        window.delegate = self
        window.isReleasedWhenClosed = false
        window.center()
        window.makeKeyAndOrderFront(nil)
        self.window = window
        languageObservation = model.$configuration.map(\.language).removeDuplicates().sink { [weak self] language in
            self?.updateMenus(language: language)
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    private func updateMenus(language: AppLanguage) {
        func t(_ key: String) -> String { Texts.get(key, language: language) }
        let menu = NSMenu()
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: t("quit"), action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        let root = NSMenuItem(); root.submenu = appMenu; menu.addItem(root)
        let edit = NSMenuItem(title: t("edit"), action: nil, keyEquivalent: "")
        let editMenu = NSMenu(title: t("edit"))
        for (key, action, shortcut) in [("cut", "cut:", "x"), ("copy", "copy:", "c"), ("paste", "paste:", "v"), ("selectAll", "selectAll:", "a")] {
            editMenu.addItem(withTitle: t(key), action: Selector(action), keyEquivalent: shortcut)
        }
        edit.submenu = editMenu; menu.addItem(edit)
        NSApp.mainMenu = menu
    }
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if let window { window.makeKeyAndOrderFront(nil) }
        else { showSettings(preview: false) }
        return true
    }
    func applicationDidBecomeActive(_ notification: Notification) { model?.refreshExtension() }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}

MainActor.assumeIsolated {
    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate
    withExtendedLifetime(delegate) { app.run() }
}
