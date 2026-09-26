# Validation record

Date: September 16, 2026. Environment: macOS 27.0 (26A428), Xcode 27.0 (27A266a), Apple Silicon.

## Verified in the current revision

- **39 tests passed (September 26):** 13 core tests, 19 application-support tests, and 7 Finder menu-layout tests.
- Core coverage: literal Unicode, quote, space, and newline arguments; selection semantics; parent-folder deduplication; configuration round trips; corruption preservation; unsupported versions; invalid and oversized launch requests.
- App-model coverage: Follow System defaults, preservation of explicit Chinese/English choices, add/edit/disable/remove persistence, drag move semantics in both directions and across multiple indices, rejected invalid moves, failed writes leaving published state unchanged, and corrupt configuration remaining read-only. Preset restoration tests cover iTerm-specific defaults, stable identity, duplicate prevention, preservation of edited/reordered/custom launchers, reload persistence, and failed writes.
- Actual process test: the launcher starts a controlled executable fixture, which records its received argument and working directory. Shell-like text stays literal and does not execute; the working directory's filesystem identity matches the requested folder.
- Unsigned Debug build passed for the host and Finder extension.
- Unsigned Release universal build passed for both targets with arm64 and x86_64. Deployment target remains 15.7. This is build evidence, not runtime evidence for Intel or earlier macOS versions.
- English and Chinese localization resources have matching keys. English and Simplified Chinese READMEs are maintained together; developer documentation remains English.
- New configurations follow the system language. On the Chinese-language development system the native UI opens in Chinese. Explicit saved choices remain unchanged.
- Zed, Fork, and Typora presets use bundle identifiers verified against the installed apps. All three resolve to their actual icons and paths in the native UI. Fork opens directories (or parent directories of selected files). Individual launch/runtime coverage remains pending below.
- Both README screenshots show the split button and eight presets after restoring Zed to the end of the list, with no Cursor or custom test entries. Existing saved launcher lists are preserved rather than reset by the preset update.
- Add Launcher is a split button: its main segment directly opens a custom editor, and its arrow lists only missing presets. Native preview verified removing and restoring Zed, automatic enablement and append order, and the arrow becoming disabled after restoration. Cancelling the unsaved-draft confirmation preserved the draft; confirming it restored the preset.
- In isolated preview, a custom application path and two argument lines were saved through the UI. The resulting configuration file contained the exact path and argument array.
- English → Simplified Chinese → English was verified in preview. The sidebar, settings content, and application Edit menu update without relaunching. Follow System was also selected and persisted through the native picker.
- Native launcher rows expose no action menu. Clicking a row updates the inspector; a reordered preview list was observed in the UI and configuration file, then retained after relaunch.
- About, General, and Finder screenshots confirm that the bundle ID, lifecycle explanation, and internal compatibility status are absent from the UI.
- About reads `CFBundleShortVersionString` from the running app and displays a localized version label. The installed Debug build was verified visually in Chinese as “版本 0.1.0”; the matching English resource is “Version %@”.
- Closing the settings window was followed by a process check: no gogo process remained. Computer Use automatically relaunches a closed app when asked to read it again, so the exit check was performed independently.
- Reproduced the installed application's save failure by enabling Zed. Replaced protected App Group file storage with a versioned JSON snapshot in CFPreferences and a read-only shared-preference entitlement for the Finder extension. On the installed ad-hoc build, enabling Zed succeeds, survives host restart, and appears in the Finder toolbar menu.
- Shared-preference tests cover complete-snapshot persistence across separate store/model instances and corrupt-data preservation with the UI remaining read-only. The isolated file store now distinguishes a missing file from other read errors.
- Native Finder Copy Current Path prioritizes selected files/folders in both toolbar and context menus, falling back to the current folder with nothing selected. On the installed build, exact clipboard checks passed for a toolbar-selected README file, two selected folders separated by a newline, the unselected current folder, and a context-selected Assets folder. Both native menus showed “复制当前路径”; the English resource is “Copy Current Path”. Menu payloads are retained in the extension and looked up by transported integer tags; passing representedObject did not produce a working copy action in the tested Finder runtime.
- Copy Current Path remains independent of launcher enablement and is also built in the configuration-error recovery menu. Only the absence of both selection and target disables the command; configuration-error/no-target cases remain code-reviewed rather than separate native runtime checks.

## Screenshots

- [Launchers, English](screenshots/launchers-en.png)
- [Launchers, Simplified Chinese](screenshots/launchers-zh.png)

Only approved README images are versioned. Test screenshots remain local and are excluded from Git; the written validation observations above are retained.

The preview uses a separate configuration file. Its successful saves do not prove shared-preference access or Finder extension behavior; installed runtime checks are recorded separately above.

## Remaining gaps

| Check | Status |
| --- | --- |
| Shared settings | Installed ad-hoc host save/relaunch and sandboxed Finder read verified on macOS 27. App Groups are no longer used. Other OS versions and Developer ID builds remain pending. |
| Finder registration | Ad-hoc local installation in `/Applications/gogo.app` is registered by PlugInKit and visible in System Settings on macOS 27. Original preview signatures omitted the sandbox entitlement; pkd explicitly rejected them. Re-signing with the configured entitlements and registering the installed containing app resolved discovery. |
| Finder toolbar image | Extension enablement and toolbar-image callbacks observed on macOS 27. The approved monochrome SVG is rendered into a dedicated 18-point template image with concrete 18px/36px bitmap representations. The prior color image rendered correctly in the toolbar and customization palette after updating the installed app and refreshing Finder. Archive round-trip checks confirm both sizes and image coverage. |
| Finder menu actions | Toolbar and multi-selection context Copy Path verified against clipboard contents. Terminal launched from a newly mounted test volume; the shell's working directory matched the selected Chinese/space-containing folder. Other presets remain pending. |
| Individual terminal/editor integrations | Presets still need cold-start and already-running checks, including iTerm2 Automation approval and denial. The executable fixture does not establish terminal compatibility. |
| macOS 15.7 and 26 runtime | No matching runtime environment available. |
| Intel runtime | Universal binaries compiled; no Intel runtime validation. |
| UI drag edge cases | Delete, restore, and discard/cancel flows were exercised in preview. Basic row selection and reordered-list persistence were also observed. Failed-save, invalid-index, and multi-index moves are covered by model tests; exhaustive native interaction coverage remains pending. |
| Dark mode and minimum-window-size visual review | Pending; current captured visual scope is the standard-size light appearance. |
| Developer ID, notarization, DMG, downloaded installation | Not performed. No release is published. |

## Release acceptance

1. Sign both targets with the same team, preserving the sandbox and read-only shared-preference entitlement; install and launch from Applications.
2. Save settings in the host and verify menu order, enablement, and language refresh in the extension.
3. Exercise selected files/folders, background clicks, sidebar, toolbar, no accessible location, and multiple Finder windows.
4. Validate each preset cold and already running; test iTerm2 permission approval and denial.
5. Validate custom apps/executables, arguments, working folders, special characters, multiple selections, and missing applications.
6. Preserve configuration on read/write failure and unknown versions; retain a working Settings recovery action.
7. Record actual system versions and screenshots for 15.7, 26, and 27; verify settings and launch-request process lifecycles.
8. Validate signed/notarized release artifacts again after downloading and installing them independently.

## Historical Finder menu icon update (before September 26 menu changes)

- Debug and universal Release builds checked after adding the monochrome SVG and menu images.
- Image archive round-trip checks preserve 16/18-point sizes, 1x/2x bitmap dimensions, and the template flag. Pixel inspection confirms monochrome, nonempty artwork with no clipped edges at all four sizes.
- All menu symbols resolve using the current SDK/runtime. The installed Finder toolbar menu exposes launcher names without an “Open in” prefix. Native context-menu inspection confirms the parent label “用 gogo 快速打开”, one submenu after refreshing Finder, and unchanged Copy Path behavior verified against the clipboard. A native window screenshot confirms the small monochrome toolbar mark. Menu-open screenshots were unavailable through the UI capture tool, so menu-image sizing/template transport was checked with image inspection rather than a captured live menu.
- Native dark-appearance and macOS 15.7/26 checks remain pending; template semantics and compile-time deployment targeting do not replace those checks.

## README screenshots (September 26, 2026)

- Replaced the English and Simplified Chinese launcher screenshots with user-provided captures showing Gogo branding and the per-launcher context-menu switch.
- Replaced the English context-menu screenshot and added its Chinese counterpart. Both show direct iTerm2 and Zed launchers, top-level Copy Current Path, and Open with Gogo.
- Added localized Finder settings screenshots showing the independent submenu, copy-path placement, and toolbar controls. These show one possible configuration, not the defaults; the submenu is hidden in the settings captures and visible in the menu captures.
- Retained the existing toolbar screenshot because that menu's presentation is unchanged. Only these approved presentation images are included in the screenshot allowlist. Screenshot content does not establish action dispatch or cross-version compatibility.

## Per-launcher context menu placement (September 26, 2026)

- Copy Current Path has an independent Finder settings toggle for placement at the context-menu root, off by default and when decoding older version-1 settings. Invalid values are rejected. When enabled, the same action item moves out of the submenu and stays visible when that submenu is hidden; toolbar placement and selection snapshots are unchanged. Tests cover legacy decoding, invalid values, persistence and reversal, all context/toolbar and submenu visibility combinations, no duplicate visible copy item, and preservation of its tag, action, image, and disabled state. All 39 Swift tests and the universal Release build passed; both localizations contain the same 118 keys. On request, the copy-path placement build was installed at `/Applications/Gogo.app` as local version 0.1.2 (17), preserving settings. Native inspection confirmed the new Finder settings checkbox is present and off, with the extension enabled. PlugInKit listed one enabled installed extension, and the actual Finder context menu contained one Gogo submenu with Copy Current Path inside it and no duplicate group. The enabled top-level copy action remains covered by automated menu tests, not an installed-configuration toggle or clipboard runtime check.
- Follow-up: the product display name, app bundle/executable, localized permission text, and release packaging now use Gogo. Bundle identifiers, saved-setting keys, and repository URLs stay unchanged. The submenu is now “Open with Gogo” / “用 Gogo 打开”. `showContextMenu` only controls this submenu, retaining direct launchers when off; an empty context menu returns nil. Toolbar and configuration-error recovery behavior are unchanged. Three new menu tests cover hiding the group with direct launchers, with no direct launchers, and in the toolbar. All 35 Swift tests and 7 release-tool tests passed; shell syntax, property lists, and both 116-key localizations were checked. The universal Release app and extension build passed, and their built bundle names and executable architectures were inspected. On request, these follow-up changes were installed at `/Applications/Gogo.app` as local version 0.1.2 (17), preserving settings. After replacing the lowercase app path and refreshing Finder, the registration disappeared once; re-registering the final installed path restored it. PlugInKit then listed one enabled extension, signature verification passed, and native Finder inspection showed one “用 Gogo 打开” submenu alongside the direct iTerm2 and Zed items and a toolbar button labeled Gogo. The visibility toggle was covered by menu tests, not toggled in the installed user configuration. DMG creation was not rerun.
- After installing the localized root-item titles (`Open with %@` / `用 %@ 打开`), Finder displayed two identical groups despite PlugInKit listing only one installed extension. Two extension processes were running from the installed path. Restarting Finder and those extension processes restored a single group; a fresh native accessibility inspection confirmed one iTerm2 item, one Zed item, and one gogo submenu containing Visual Studio Code, Fork, Copy Current Path, and Settings. This points to stale Finder extension connections after local replacement, not duplicate configuration. A registration check alone is insufficient: verify the actual context menu after local installation and refresh Finder if duplicates remain. Launcher action dispatch was not exercised by this check.
- The launcher editor has a localized "Show directly in context menu" switch using the existing draft, Save, and Cancel flow. It defaults to off for presets, custom launchers, and older version-1 snapshots that omit the new field. A present but invalid field is rejected instead of silently resetting configuration.
- Initial implementation, superseded by the follow-up above: enabled direct launchers appeared before the then-named Quick Open with gogo submenu, and the context-menu switch hid the entire integration. The current switch hides only Open with Gogo; direct launchers and an optionally top-level Copy Current Path remain available. Toolbar placement is unchanged.
- Tests cover legacy configuration preservation, malformed placement values, save/reload/revert, mixed top-level/submenu order, retention of menu-item identity, images, tags, actions, and disabled state, toolbar independence, and the utility submenu when every launcher is direct. All 32 Swift tests passed, as did the unsigned arm64/x86_64 Debug build. Both localizations have the same 115 keys, including the localized root-item titles.
- In the isolated native settings preview on macOS 27, the Chinese switch and explanatory text appeared in the launcher inspector. Enabling and saving persisted the flag, reopening retained it, and Cancel reverted an unsaved change. The preview setting was restored afterward.
- On request, the universal Release build was ad-hoc signed with the configured entitlements and installed at `/Applications/gogo.app` as a local 0.1.2 (16) build containing these uncommitted changes. Signature verification passed for the installed app; both executables contain arm64 and x86_64. The installed settings window shows the new switch with existing launcher selections retained, and PlugInKit reports exactly one enabled extension at the installed path with a fresh running extension process. End-to-end top-level action dispatch in Finder on macOS 15.7/26/27 remains unverified.

## Finder menu image appearance (September 23, 2026)

- A user reported that Copy Current Path and Settings icons remain dark in dark appearance. The previous implementation marked rasterized images as templates but their actual pixels stayed black. This does not by itself prove which Finder transport/rendering stage ignores the template flag.
- Menu symbols now resolve `NSApplication.shared.effectiveAppearance` on every menu request and render with `NSColor.labelColor` under `performAsCurrentDrawingAppearance`. The context-menu logo follows the same path instead of keeping a startup-time image. The template flag remains set for renderers that honor it; the toolbar template and full-color application icons retain their existing behavior.
- An isolated AppKit check on macOS 27 exercised light, dark, both high-contrast appearances, then light again within one process. Copy, Settings, warning, unavailable-folder, terminal, app, and menu-logo images kept their 16-point size, 1x/2x bitmap representations, and template flag. TIFF pixel round trips retained the expected dark/light color without relying on template tinting. For the Settings symbol in dark appearance, the previous rasterizer's mean opaque-pixel RGB brightness was 0.0; the new path was approximately 1.0.
- The unsigned Debug and Release host and Finder extension builds passed for arm64 and x86_64 with deployment target 15.7. The Release build was ad-hoc signed with the configured entitlements and installed at `/Applications/gogo.app` on request, retaining existing settings. Its About page shows version 0.1.1, and PlugInKit reports exactly one enabled gogo extension at the installed path. These are rendering-logic, build, and installation checks, not a verified end-to-end system-theme switch in Finder. The affected OS version, actual Finder menu appearance after switching themes, and highlighted/disabled item rendering remain to be confirmed. No system appearance or published release was changed.

## macOS 15 menu separator fallback

- A user screenshot from macOS 15.7 shows the two native separators as blank, full-height rows in the Finder toolbar menu. The implementation already used `NSMenuItem.separator()`. A [similar Finder Sync report](https://developer.apple.com/forums/thread/836136) describes the same behavior; it has no Apple-confirmed resolution.
- A follow-up review of Apple's Finder Sync guide, the separator API documentation, and the forum report found no documented native compatibility fix. The open-source [MediaInfo Finder extension](https://github.com/sbarex/MediaInfo/blob/master/MediaInfo%20Finder%20Extension/FinderSync.swift#L432-L508) also replaces separators with horizontal-rule characters because Finder turns them into disabled empty menu items. This is corroborating implementation evidence, not an Apple guarantee about all OS versions.
- On macOS 15, both the toolbar and context submenu now use disabled plain-text horizontal rules consisting of five `─` characters, as requested. The configuration-error menu uses the same helper. Empty menus do not receive a leading divider. macOS 26 and later retain native separators.
- This is a visual fallback, not restoration of native separator semantics: Finder still controls the row height, and the horizontal rule has a fixed text width. No custom menu view, action, or launcher payload is attached to the divider.
- The unsigned Debug build passed for the host and extension on macOS 27, for arm64 and x86_64 with deployment target 15.7. The fallback still needs actual macOS 15.7 toolbar/context-menu verification in light and dark appearance and with VoiceOver. Build success does not establish its Finder rendering on macOS 15.7. No release or installed application was changed.

## External volumes and launch handoff

- Reproduced missing context menus and disabled toolbar actions on the physical USB APFS volume `/Volumes/ssd`. Registering each mounted volume restored its context submenu and enabled toolbar launchers. Copy Path matched both the current project directory and the selected Assets folder.
- Mounted a disposable HFS+ disk image after extension startup. Its context menu appeared without restarting Finder. Terminal cold-started from the context submenu, and `lsof` confirmed the child shell's working directory was `/Volumes/gogo Volume Test/Folder with 空格`. The request document was consumed and its host instance exited. A `nobrowse` mount is intentionally excluded by `skipHiddenVolumes`.
- Finder-to-host argv handoff was replaced because NSWorkspace ignores arguments supplied by sandboxed callers. An explicitly registered request document now reaches the host. Tests cover consume-once behavior and rejection of outside-directory paths, symbolic links, expired documents, and oversized documents.
- The physical SSD Terminal launch remains pending: process sampling showed the host waiting inside LaunchServices' sandbox-extension issuance call; its request had already been consumed. No successful SSD shell launch is claimed. The test-volume result does not establish permissions or launching behavior for every external drive.

## Permission Management

- General has Finder extension, Files and Folders, and iTerm2 Automation cards. File permission details, volume selectors, probes, mount observers, and preauthorization are removed. Files and Folders only links to its System Settings pane; file consent occurs during actual use.
- Four permission tests cover passive Automation querying, explicit consent requests, preview isolation, duplicate request prevention, and fresh status after revocation/reopening. No permission history is saved or restored.
- Existing native checks on macOS 27 confirmed aligned, full-width language/permission cards, Follow System language selection, and working Files and Folders / Automation settings links. On the current installed build, a native screenshot confirms the simplified file card matches the Finder card layout and has no detail rows. Clicking Open Settings successfully opened the Files and Folders pane, showing gogo’s OS-managed grants. No grants were changed. All 26 tests and the Debug build passed.
- Fresh system prompt approval/denial and revocation are not runtime-verified; Automation changes are tested with an injected service. macOS 15.7/26 and Developer ID signing remain pending. This UI change does not resolve the previously recorded SSD LaunchServices issue.
