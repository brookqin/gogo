# Design and architecture decisions

## Visual baseline

On September 16, 2026, the user selected the first concept and explicitly retained its logo.

- Reference: `selected-concept.png`. Preserve the blue rounded icon and white italic lowercase `go`.
- Master icon: `Assets/AppIcon.png`, generated with the built-in ImageGen tool using the selected concept as an identity reference. ICNS files are standard size exports.
- Icon prompt: faithfully extract the blue rounded square and white italic lowercase go from the About panel; preserve lettering, blue gradient, and corners; transparent padding; no additional symbols or text.
- Native SwiftUI settings with an AppKit window; system fonts and SF Symbols.
- Sidebar navigation, launcher list, and inspector. Finder, General, and About are separate settings pages.

## Product language and content

- New configurations default to Follow System. Explicit English and Simplified Chinese choices remain available; saved choices are preserved.
- Both English and Simplified Chinese READMEs are maintained. Developer documentation is written in English. The original Chinese concept image remains an approved historical visual reference.
- About omits the bundle identifier. Lifecycle, signing, and validation details belong in this documentation, not in the product UI.
- Add Launcher is a split button: the main segment opens a custom editor; the arrow lists missing presets and is disabled when none are missing. Restoring a preset appends it with its default settings and enables it. Existing presets are omitted, and an unsaved editor draft requires confirmation before switching.
- Launcher rows use native drag-and-drop reordering. Clicking a row edits it; there are no per-row action menus.
- Usage guidance stays where it affects a decision: arguments, working folders, supported selection types, and application launching behavior.

## Launching and persistence

- Application arguments require a new application instance. The UI explains that behavior; document opening can reuse an existing application.
- Only executable launchers expose an actual process working directory. Application launchers receive directory tokens through supported arguments.
- Finder uses system NSMenu surfaces. The observed root declares menu scope; there is no filesystem scan, badge, or recursive watcher.
- Shared settings are one versioned JSON Data value in the `cn.053x.gogo.settings` CFPreferences domain. The host publishes complete snapshots; the sandboxed extension has only the documented shared-preference read-only exception for this domain. This removes the protected App Group dependency that prevented ad-hoc local builds from saving on macOS 27. The preview retains its separate atomic JSON file.
- Copy Path uses the menu context: selected items for an item context menu, targeted folder for the toolbar/background/sidebar. Multiple paths use newline separators, without shell quoting. Copy remains available if configuration loading fails.
- Launch requests start a separate host instance with a bounded encoded argument. The settings instance remains independent. There is no web-addressable URL scheme.
- No resident tray app, login item, polling daemon, or permanent XPC service.
- The earlier conversation's macOS 27 root-cause discussion is a hypothesis, not established evidence.

## API references

- [Finder Sync](https://developer.apple.com/documentation/findersync)
- [FIFinderSync](https://developer.apple.com/documentation/findersync/fifindersync-swift.class)
- [New application instances](https://developer.apple.com/documentation/appkit/nsworkspace/openconfiguration/createsnewapplicationinstance)
- [Shared preference domain exceptions](https://developer.apple.com/library/archive/documentation/Miscellaneous/Reference/EntitlementKeyReference/Chapters/AppSandboxTemporaryExceptionEntitlements.html)
- [Ghostty CLI configuration](https://ghostty.org/docs/config)

The design's non-resident requirement applies to the host. The operating system controls the Finder extension's lifetime.
