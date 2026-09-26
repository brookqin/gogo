import AppKit
import Testing
@testable import GogoFinderMenus

@MainActor @Test func contextPlacementPreservesOrderActionsAndAvailability() throws {
    let layout = FinderMenu(toolbar: false)
    let items = (0..<4).map { index in
        let item = NSMenuItem(title: "App \(index)", action: NSSelectorFromString("launch:"), keyEquivalent: "")
        item.tag = index + 100
        item.isEnabled = index != 2
        item.image = NSImage(size: NSSize(width: 16, height: 16))
        return item
    }
    for (index, item) in items.enumerated() {
        layout.addLauncher(item, directlyInContextMenu: index.isMultiple(of: 2))
    }
    let copy = NSMenuItem(title: "Copy", action: NSSelectorFromString("copyPath:"), keyEquivalent: "")
    let settings = NSMenuItem(title: "Settings", action: NSSelectorFromString("settings:"), keyEquivalent: "")
    layout.content.addItem(copy)
    layout.content.addItem(settings)
    let root = layout.presented(submenuTitle: "gogo", submenuImage: NSImage())
    #expect(root.items.map(\.title) == ["App 0", "App 2", "gogo"])
    let submenu = try #require(root.items.last?.submenu)
    #expect(submenu.items.map(\.title) == ["App 1", "App 3", "Copy", "Settings"])
    #expect(root.items[0] === items[0])
    #expect(root.items[1].tag == 102)
    #expect(root.items[1].action == NSSelectorFromString("launch:"))
    #expect(root.items[1].image === items[2].image)
    #expect(!root.items[1].isEnabled)
    #expect(!root.autoenablesItems && !submenu.autoenablesItems)
}

@MainActor @Test func toolbarIgnoresContextPlacement() {
    let layout = FinderMenu(toolbar: true)
    for (name, direct) in [("First", true), ("Second", false), ("Third", true)] {
        layout.addLauncher(NSMenuItem(title: name, action: nil, keyEquivalent: ""), directlyInContextMenu: direct)
    }
    let menu = layout.presented(submenuTitle: "gogo", submenuImage: NSImage())
    #expect(menu.items.map(\.title) == ["First", "Second", "Third"])
    #expect(menu.items.allSatisfy { $0.submenu == nil })
}

@MainActor @Test func allDirectLaunchersKeepUtilitySubmenu() throws {
    let layout = FinderMenu(toolbar: false)
    layout.addLauncher(NSMenuItem(title: "App", action: nil, keyEquivalent: ""), directlyInContextMenu: true)
    layout.content.addItem(NSMenuItem(title: "Copy", action: nil, keyEquivalent: ""))
    layout.content.addItem(NSMenuItem(title: "Settings", action: nil, keyEquivalent: ""))
    let menu = layout.presented(submenuTitle: "gogo", submenuImage: NSImage())
    #expect(menu.items.map(\.title) == ["App", "gogo"])
    #expect(try #require(menu.items.last?.submenu).items.map(\.title) == ["Copy", "Settings"])
}
