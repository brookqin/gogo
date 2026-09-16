import AppKit
import FinderSync
import OSLog

final class FinderSync: FIFinderSync {
    private enum MenuAction {
        case launch(LaunchRequest)
        case copy([String])
    }
    private var actions: [Int: MenuAction] = [:]
    private var menuTags: [UInt: [Int]] = [:]
    private var nextTag = 1

    private func remember(_ action: MenuAction, for item: NSMenuItem, kind: FIMenuKind) {
        item.tag = nextTag
        nextTag += 1
        actions[item.tag] = action
        menuTags[kind.rawValue, default: []].append(item.tag)
    }

    override init() {
        super.init()
        // Finder's scope does not cross volume boundaries from the boot root.
        // Register each mounted volume without enumerating its contents.
        let center = NSWorkspace.shared.notificationCenter
        for name in [NSWorkspace.didMountNotification, NSWorkspace.didUnmountNotification,
                     NSWorkspace.didRenameVolumeNotification, NSWorkspace.didWakeNotification] {
            center.addObserver(self, selector: #selector(volumesDidChange(_:)), name: name, object: nil)
        }
        updateObservedDirectories()
    }

    deinit { NSWorkspace.shared.notificationCenter.removeObserver(self) }

    @objc private func volumesDidChange(_ notification: Notification) {
        updateObservedDirectories()
    }

    private func updateObservedDirectories() {
        let controller = FIFinderSyncController.default()
        let root = URL(fileURLWithPath: "/", isDirectory: true)
        guard let volumes = FileManager.default.mountedVolumeURLs(includingResourceValuesForKeys: nil,
                                                                  options: [.skipHiddenVolumes]) else {
            // Preserve the previous scope if the system cannot enumerate volumes.
            if controller.directoryURLs.isEmpty { controller.directoryURLs = [root] }
            return
        }
        let directories = Set(volumes.filter(\.isFileURL).map(\.standardizedFileURL)).union([root])
        if controller.directoryURLs != directories { controller.directoryURLs = directories }
    }
    override var toolbarItemName: String { "gogo" }
    override var toolbarItemToolTip: String { "gogo" }
    override var toolbarItemImage: NSImage { FinderIcons.toolbar }

    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        // Finder transports menu-item tags; payloads stay inside the extension.
        for tag in menuTags.removeValue(forKey: menuKind.rawValue) ?? [] { actions.removeValue(forKey: tag) }
        let menu = NSMenu()
        let toolbar = menuKind == .toolbarItemMenu
        let controller = FIFinderSyncController.default()
        let selectedItems = controller.selectedItemURLs() ?? []
        let currentFolder = controller.targetedURL().map { [$0] } ?? []
        let copyTargets = selectedItems.isEmpty ? currentFolder : selectedItems
        let selected: [URL]
        switch menuKind {
        case .contextualMenuForItems:
            selected = selectedItems
        default:
            selected = currentFolder
        }
        let config: Configuration
        do { config = try SharedConfiguration.file().read() }
        catch {
            let unavailable = NSMenuItem(title: Texts.get("configuration.unavailable"), action: nil, keyEquivalent: "")
            unavailable.image = FinderIcons.symbol("exclamationmark.triangle")
            unavailable.isEnabled = false; menu.addItem(unavailable)
            menu.autoenablesItems = false
            addCopyPath(to: menu, selected: copyTargets, language: .system, kind: menuKind)
            addSettings(to: menu, language: .system)
            return presentation(of: menu, toolbar: toolbar, language: .system)
        }
        if !toolbar && !config.showContextMenu { return nil }
        let content = NSMenu()
        if !toolbar || config.showToolbarLaunchers {
            for launcher in config.launchers where launcher.enabled {
                let item = NSMenuItem(title: launcher.name, action: #selector(launch(_:)), keyEquivalent: "")
                item.image = FinderIcons.launcher(launcher)
                let selection = LaunchSelection(paths: selected.map(\.path))
                let request = LaunchRequest(launcherID: launcher.id, selection: selection)
                remember(.launch(request), for: item, kind: menuKind)
                // Availability and capabilities are reevaluated when the user opens the menu.
                item.isEnabled = (try? request.encoded()) != nil && (try? LaunchPlan.make(launcher: launcher, selection: selection, isDirectory: Applications.isDirectory)) != nil
                content.addItem(item)
            }
            if selected.isEmpty {
                let empty = NSMenuItem(title: Texts.get("selection.unavailable", language: config.language), action: nil, keyEquivalent: "")
                empty.image = FinderIcons.symbol("folder.badge.questionmark")
                empty.isEnabled = false; content.addItem(empty)
            }
        }
        content.autoenablesItems = false
        addCopyPath(to: content, selected: copyTargets, language: config.language, kind: menuKind)
        addSettings(to: content, language: config.language)
        return presentation(of: content, toolbar: toolbar, language: config.language)
    }

    private func presentation(of content: NSMenu, toolbar: Bool, language: AppLanguage) -> NSMenu {
        if toolbar { return content }
        let menu = NSMenu()
        let parent = NSMenuItem(title: Texts.get("finder.quickOpen", language: language), action: nil, keyEquivalent: "")
        parent.image = FinderIcons.menuLogo
        parent.submenu = content
        menu.addItem(parent)
        return menu
    }

    private func addCopyPath(to menu: NSMenu, selected: [URL], language: AppLanguage, kind: FIMenuKind) {
        if !menu.items.isEmpty { menu.addItem(.separator()) }
        let item = NSMenuItem(title: Texts.get("path.copy", language: language), action: #selector(copyPath(_:)), keyEquivalent: "")
        item.image = FinderIcons.symbol("doc.on.doc")
        // Snapshot the menu's context; selection may change before the action arrives.
        remember(.copy(selected.map(\.path)), for: item, kind: kind)
        item.isEnabled = !selected.isEmpty
        menu.addItem(item)
    }

    // Leave NSMenuItem.target unset so Finder routes actions to this extension.
    @IBAction func copyPath(_ sender: NSMenuItem) {
        guard case let .copy(paths) = actions[sender.tag], !paths.isEmpty else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(paths.joined(separator: "\n"), forType: .string)
    }

    private func addSettings(to menu: NSMenu, language: AppLanguage) {
        if !menu.items.isEmpty { menu.addItem(.separator()) }
        let item = NSMenuItem(title: Texts.get("settings.open", language: language), action: #selector(settings(_:)), keyEquivalent: "")
        item.image = FinderIcons.symbol("gearshape")
        menu.addItem(item)
    }
    private var hostURL: URL {
        // gogo.app/Contents/PlugIns/GogoFinder.appex -> gogo.app
        Bundle.main.bundleURL.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    }
    @IBAction func settings(_ sender: Any?) {
        NSWorkspace.shared.openApplication(at: hostURL, configuration: NSWorkspace.OpenConfiguration(), completionHandler: nil)
    }
    @IBAction func launch(_ sender: NSMenuItem) {
        guard case let .launch(request) = actions[sender.tag] else { return }
        let requestURL: URL
        do { requestURL = try LaunchHandoff.write(request) }
        catch {
            Logger(subsystem: "cn.053x.gogo", category: "launch").error("Could not prepare launcher request")
            return
        }
        let options = NSWorkspace.OpenConfiguration()
        options.activates = false
        options.createsNewApplicationInstance = true
        options.addsToRecentItems = false
        // Sandboxed callers cannot pass launch arguments. Deliver a short-lived
        // request document explicitly to the containing app instead.
        NSWorkspace.shared.open([requestURL], withApplicationAt: hostURL, configuration: options) { _, error in
            if let error = error as NSError? {
                try? FileManager.default.removeItem(at: requestURL)
                // Always leave the settings entry available for recovery.
                Logger(subsystem: "cn.053x.gogo", category: "launch").error("Could not dispatch launcher request: \(error.domain, privacy: .public) \(error.code)")
            }
        }
    }
}
