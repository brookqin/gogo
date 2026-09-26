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
    let root = layout.presented(submenuTitle: "Gogo", submenuImage: NSImage())
    #expect(root.items.map(\.title) == ["App 0", "App 2", "Gogo"])
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
    let menu = layout.presented(submenuTitle: "Gogo", submenuImage: NSImage())
    #expect(menu.items.map(\.title) == ["First", "Second", "Third"])
    #expect(menu.items.allSatisfy { $0.submenu == nil })
}

@MainActor @Test func allDirectLaunchersKeepUtilitySubmenu() throws {
    let layout = FinderMenu(toolbar: false)
    layout.addLauncher(NSMenuItem(title: "App", action: nil, keyEquivalent: ""), directlyInContextMenu: true)
    layout.content.addItem(NSMenuItem(title: "Copy", action: nil, keyEquivalent: ""))
    layout.content.addItem(NSMenuItem(title: "Settings", action: nil, keyEquivalent: ""))
    let menu = layout.presented(submenuTitle: "Gogo", submenuImage: NSImage())
    #expect(menu.items.map(\.title) == ["App", "Gogo"])
    #expect(try #require(menu.items.last?.submenu).items.map(\.title) == ["Copy", "Settings"])
}

@MainActor @Test func hidingSubmenuPreservesDirectLaunchers() {
    let layout = FinderMenu(toolbar: false)
    let direct = NSMenuItem(title: "Open with App", action: NSSelectorFromString("launch:"), keyEquivalent: "")
    layout.addLauncher(direct, directlyInContextMenu: true)
    layout.addLauncher(NSMenuItem(title: "Nested", action: nil, keyEquivalent: ""), directlyInContextMenu: false)
    layout.content.addItem(NSMenuItem(title: "Settings", action: nil, keyEquivalent: ""))
    let menu = layout.presented(submenuTitle: "Open with Gogo", submenuImage: NSImage(), showSubmenu: false)
    #expect(menu.items.count == 1)
    #expect(menu.items.first === direct)
    #expect(direct.action == NSSelectorFromString("launch:"))
    #expect(direct.submenu == nil)
}

@MainActor @Test func hiddenSubmenuWithoutDirectLaunchersIsEmpty() {
    let layout = FinderMenu(toolbar: false)
    layout.addLauncher(NSMenuItem(title: "Nested", action: nil, keyEquivalent: ""), directlyInContextMenu: false)
    let menu = layout.presented(submenuTitle: "Open with Gogo", submenuImage: NSImage(), showSubmenu: false)
    #expect(menu.items.isEmpty)
}

@MainActor @Test func hidingContextSubmenuDoesNotHideToolbarItems() {
    let layout = FinderMenu(toolbar: true)
    for direct in [true, false] {
        layout.addLauncher(NSMenuItem(title: "App", action: nil, keyEquivalent: ""), directlyInContextMenu: direct)
    }
    layout.content.addItem(NSMenuItem(title: "Settings", action: nil, keyEquivalent: ""))
    let menu = layout.presented(submenuTitle: "Open with Gogo", submenuImage: NSImage(), showSubmenu: false)
    #expect(menu.items.map(\.title) == ["App", "App", "Settings"])
}

@MainActor @Test func copyPathPlacementRespectsContextAndToolbarVisibility() throws {
    for toolbar in [false, true] {
        for direct in [false, true] {
            for showSubmenu in [false, true] {
                let layout = FinderMenu(toolbar: toolbar)
                layout.addLauncher(NSMenuItem(title: "App", action: nil, keyEquivalent: ""), directlyInContextMenu: true)
                let copy = NSMenuItem(title: "Copy Current Path", action: NSSelectorFromString("copyPath:"), keyEquivalent: "")
                copy.tag = 42
                copy.isEnabled = false
                copy.image = NSImage(size: NSSize(width: 16, height: 16))
                layout.addCopyPath(copy, directlyInContextMenu: direct) { menu in
                    if !menu.items.isEmpty { menu.addItem(.separator()) }
                }
                layout.content.addItem(NSMenuItem(title: "Settings", action: nil, keyEquivalent: ""))
                let menu = layout.presented(submenuTitle: "Open with Gogo", submenuImage: NSImage(), showSubmenu: showSubmenu)
                let visibleCopies = menu.items.filter { $0 === copy }.count
                    + menu.items.flatMap { $0.submenu?.items ?? [] }.filter { $0 === copy }.count
                #expect(visibleCopies == (toolbar || direct || showSubmenu ? 1 : 0))
                #expect(menu.items.contains { $0 === copy } == (toolbar || direct))
                #expect(layout.content.items.contains { $0 === copy } == (toolbar || !direct))
                #expect(copy.tag == 42 && copy.action == NSSelectorFromString("copyPath:"))
                #expect(copy.image != nil && !copy.isEnabled)
                #expect(menu.items.first?.isSeparatorItem != true)
            }
        }
    }
}
