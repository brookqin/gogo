import AppKit
import FinderSync

final class FinderSync: FIFinderSync {
    override init() {
        super.init()
        // Observe menu context only. No recursive enumeration, filesystem watcher or badges.
        FIFinderSyncController.default().directoryURLs = [URL(fileURLWithPath: "/")]
    }
    override var toolbarItemName: String { "gogo" }
    override var toolbarItemToolTip: String { "gogo" }
    override var toolbarItemImage: NSImage {
        let image = NSImage(named: "AppIcon") ?? NSImage(systemSymbolName: "terminal", accessibilityDescription: "gogo")!
        image.isTemplate = false
        return image
    }

    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        let menu = NSMenu()
        let config: Configuration
        do { config = try SharedConfiguration.file().read() }
        catch {
            let unavailable = NSMenuItem(title: Texts.get("configuration.unavailable"), action: nil, keyEquivalent: "")
            unavailable.isEnabled = false; menu.addItem(unavailable)
            menu.autoenablesItems = false
            addSettings(to: menu, language: .system)
            return menu
        }
        let toolbar = menuKind == .toolbarItemMenu
        if !toolbar && !config.showContextMenu { return nil }
        let controller = FIFinderSyncController.default()
        let selected: [URL]
        switch menuKind {
        case .contextualMenuForItems:
            selected = controller.selectedItemURLs() ?? []
        default:
            selected = controller.targetedURL().map { [$0] } ?? []
        }
        let content = NSMenu()
        if !toolbar || config.showToolbarLaunchers {
            for launcher in config.launchers where launcher.enabled {
                let title = String(format: Texts.get("open.in", language: config.language), launcher.name)
                let item = NSMenuItem(title: title, action: #selector(launch(_:)), keyEquivalent: "")
                item.target = self
                let selection = LaunchSelection(paths: selected.map(\.path))
                let request = LaunchRequest(launcherID: launcher.id, selection: selection)
                item.representedObject = request
                // Availability and capabilities are reevaluated when the user opens the menu.
                item.isEnabled = (try? request.encoded()) != nil && (try? LaunchPlan.make(launcher: launcher, selection: selection, isDirectory: Applications.isDirectory)) != nil
                content.addItem(item)
            }
            if selected.isEmpty {
                let empty = NSMenuItem(title: Texts.get("selection.unavailable", language: config.language), action: nil, keyEquivalent: "")
                empty.isEnabled = false; content.addItem(empty)
            }
        }
        content.autoenablesItems = false
        addSettings(to: content, language: config.language)
        if toolbar { return content }
        let parent = NSMenuItem(title: "gogo", action: nil, keyEquivalent: "")
        parent.submenu = content
        menu.addItem(parent)
        return menu
    }

    private func addSettings(to menu: NSMenu, language: AppLanguage) {
        if !menu.items.isEmpty { menu.addItem(.separator()) }
        let item = NSMenuItem(title: Texts.get("settings.open", language: language), action: #selector(settings), keyEquivalent: "")
        item.target = self
        menu.addItem(item)
    }
    private var hostURL: URL {
        // gogo.app/Contents/PlugIns/GogoFinder.appex -> gogo.app
        Bundle.main.bundleURL.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    }
    @objc private func settings() {
        NSWorkspace.shared.openApplication(at: hostURL, configuration: NSWorkspace.OpenConfiguration(), completionHandler: nil)
    }
    @objc private func launch(_ sender: NSMenuItem) {
        guard let request = sender.representedObject as? LaunchRequest, let encoded = try? request.encoded() else { return }
        let options = NSWorkspace.OpenConfiguration()
        options.activates = false
        options.createsNewApplicationInstance = true
        options.arguments = ["--launch-request", encoded]
        NSWorkspace.shared.openApplication(at: hostURL, configuration: options) { _, error in
            if error != nil {
                // Always leave the settings entry available for recovery.
                NSLog("gogo: could not dispatch launcher request")
            }
        }
    }
}
