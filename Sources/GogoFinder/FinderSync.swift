import AppKit
import FinderSync

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
        // Observe menu context only. No recursive enumeration, filesystem watcher or badges.
        FIFinderSyncController.default().directoryURLs = [URL(fileURLWithPath: "/")]
    }
    override var toolbarItemName: String { "gogo" }
    override var toolbarItemToolTip: String { "gogo" }
    override var toolbarItemImage: NSImage {
        let source = NSImage(named: "AppIcon") ?? NSImage(systemSymbolName: "terminal", accessibilityDescription: "gogo")!
        // Give Finder a separate toolbar-sized image, not the named application icon.
        // The customization palette otherwise expands to the app icon's intrinsic size.
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size)
        // Concrete 1x/2x bitmap representations survive transport to the Finder process.
        for scale in [1, 2] {
            guard let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil,
                pixelsWide: 18 * scale, pixelsHigh: 18 * scale,
                bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0),
                let context = NSGraphicsContext(bitmapImageRep: bitmap) else { continue }
            bitmap.size = size
            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.current = context
            context.imageInterpolation = .high
            context.cgContext.scaleBy(x: CGFloat(scale), y: CGFloat(scale))
            source.draw(in: NSRect(origin: .zero, size: size), from: .zero,
                        operation: .sourceOver, fraction: 1)
            NSGraphicsContext.restoreGraphicsState()
            image.addRepresentation(bitmap)
        }
        image.isTemplate = false
        return image
    }

    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        // Finder transports menu-item tags; payloads stay inside the extension.
        for tag in menuTags.removeValue(forKey: menuKind.rawValue) ?? [] { actions.removeValue(forKey: tag) }
        let menu = NSMenu()
        let toolbar = menuKind == .toolbarItemMenu
        let controller = FIFinderSyncController.default()
        let selected: [URL]
        switch menuKind {
        case .contextualMenuForItems:
            selected = controller.selectedItemURLs() ?? []
        default:
            selected = controller.targetedURL().map { [$0] } ?? []
        }
        let config: Configuration
        do { config = try SharedConfiguration.file().read() }
        catch {
            let unavailable = NSMenuItem(title: Texts.get("configuration.unavailable"), action: nil, keyEquivalent: "")
            unavailable.isEnabled = false; menu.addItem(unavailable)
            menu.autoenablesItems = false
            addCopyPath(to: menu, selected: selected, language: .system, kind: menuKind)
            addSettings(to: menu, language: .system)
            return menu
        }
        if !toolbar && !config.showContextMenu { return nil }
        let content = NSMenu()
        if !toolbar || config.showToolbarLaunchers {
            for launcher in config.launchers where launcher.enabled {
                let title = String(format: Texts.get("open.in", language: config.language), launcher.name)
                let item = NSMenuItem(title: title, action: #selector(launch(_:)), keyEquivalent: "")
                let selection = LaunchSelection(paths: selected.map(\.path))
                let request = LaunchRequest(launcherID: launcher.id, selection: selection)
                remember(.launch(request), for: item, kind: menuKind)
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
        addCopyPath(to: content, selected: selected, language: config.language, kind: menuKind)
        addSettings(to: content, language: config.language)
        if toolbar { return content }
        let parent = NSMenuItem(title: "gogo", action: nil, keyEquivalent: "")
        parent.submenu = content
        menu.addItem(parent)
        return menu
    }

    private func addCopyPath(to menu: NSMenu, selected: [URL], language: AppLanguage, kind: FIMenuKind) {
        if !menu.items.isEmpty { menu.addItem(.separator()) }
        let item = NSMenuItem(title: Texts.get("path.copy", language: language), action: #selector(copyPath(_:)), keyEquivalent: "")
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
        guard case let .launch(request) = actions[sender.tag], let encoded = try? request.encoded() else { return }
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
