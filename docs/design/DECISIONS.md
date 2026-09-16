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
- Finder uses system NSMenu surfaces. Register the boot root and each visible mounted volume separately: the boot root alone did not cover the external SSD. Refresh the set on volume mount, unmount, rename, and wake notifications. This declares menu scope without scanning files, badges, or recursive watchers.
- Shared settings are one versioned JSON Data value in the `cn.053x.gogo.settings` CFPreferences domain. The host publishes complete snapshots; the sandboxed extension has only the documented shared-preference read-only exception for this domain. This removes the protected App Group dependency that prevented ad-hoc local builds from saving on macOS 27. The preview retains its separate atomic JSON file.
- Copy Current Path prioritizes selected items in every menu, including the toolbar, and falls back to the targeted folder when selection is empty. Multiple paths use newline separators, without shell quoting. Copy remains available if configuration loading fails; it is disabled only when neither selection nor target is available.
- The sandboxed extension writes a bounded request document to the app's private request directory and explicitly opens it with the containing host. NSWorkspace ignores launch arguments from sandboxed callers. The host declares a private document type, validates location, ownership, regular-file type, size, age, and payload, then consumes the document before dispatch. Its handler rank is None and there is no web-addressable URL scheme. A narrowly scoped home-relative entitlement grants the extension access only to the gogo application-support directory. Settings remain independent of request instances.
- No resident tray app, login item, polling daemon, or permanent XPC service.
- The earlier conversation's macOS 27 root-cause discussion is a hypothesis, not established evidence.

## API references

- [Finder Sync](https://developer.apple.com/documentation/findersync)
- [FIFinderSync](https://developer.apple.com/documentation/findersync/fifindersync-swift.class)
- [New application instances](https://developer.apple.com/documentation/appkit/nsworkspace/openconfiguration/createsnewapplicationinstance)
- [Shared preference domain exceptions](https://developer.apple.com/library/archive/documentation/Miscellaneous/Reference/EntitlementKeyReference/Chapters/AppSandboxTemporaryExceptionEntitlements.html)
- [Ghostty CLI configuration](https://ghostty.org/docs/config)

The design's non-resident requirement applies to the host. The operating system controls the Finder extension's lifetime.

## Finder identity and menu icons

The approved Finder mark is `Assets/GogoTemplate.svg`: an italic, round-ended, monoline `go` with a transparent background. The blue application icon remains the host identity. The Finder mark is a template image so the system supplies the appearance-dependent tint.

The toolbar uses an 18-point canvas; menu icons use 16-point canvases. These are design choices, not fixed Finder Sync API requirements. Apple's [toolbarItemImage documentation](https://developer.apple.com/documentation/findersync/fifindersyncprotocol/toolbaritemimage) specifies an NSImage but no fixed dimensions. The current [Icons HIG](https://developer.apple.com/design/human-interface-guidelines/icons) recommends vector sources, consistent stroke weight, and optical alignment. Sidebar icon tables and Safari extension dimensions do not specify Finder toolbar dimensions.

The SVG is rasterized into concrete 1x/2x representations for transport to Finder, preserving its template flag and point size. Bitmap point sizes are assigned after rendering to avoid applying the Retina scale twice. Application menu entries use the installed application/file icons; missing targets fall back to an app or terminal symbol. Copy Path and Settings use monochrome SF Symbols. Launcher labels are their configured names only. The localized context-menu parent is “Quick Open with gogo” / “用 gogo 快速打开”.
