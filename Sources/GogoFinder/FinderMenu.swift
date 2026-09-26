import AppKit

/// Keeps launcher placement separate from the selection and action snapshots.
final class FinderMenu {
    let content = NSMenu()
    private let root = NSMenu()
    private let toolbar: Bool

    init(toolbar: Bool) {
        self.toolbar = toolbar
        content.autoenablesItems = false
        root.autoenablesItems = false
    }

    func addLauncher(_ item: NSMenuItem, directlyInContextMenu: Bool) {
        let destination = !toolbar && directlyInContextMenu ? root : content
        destination.addItem(item)
    }

    func presented(submenuTitle: String, submenuImage: NSImage) -> NSMenu {
        if toolbar { return content }
        let parent = NSMenuItem(title: submenuTitle, action: nil, keyEquivalent: "")
        parent.image = submenuImage
        parent.submenu = content
        root.addItem(parent)
        return root
    }
}
