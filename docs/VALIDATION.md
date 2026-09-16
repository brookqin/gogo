# Validation record

Date: September 16, 2026. Environment: macOS 27.0 (26A428), Xcode 27.0 (27A266a), Apple Silicon.

## Verified in the current revision

- **26 tests passed:** 9 core tests and 17 application-support tests.
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

## Finder menu icon update

- Debug and universal Release builds checked after adding the monochrome SVG and menu images.
- Image archive round-trip checks preserve 16/18-point sizes, 1x/2x bitmap dimensions, and the template flag. Pixel inspection confirms monochrome, nonempty artwork with no clipped edges at all four sizes.
- All menu symbols resolve using the current SDK/runtime. The installed Finder toolbar menu exposes launcher names without an “Open in” prefix. Native context-menu inspection confirms the parent label “用 gogo 快速打开”, one submenu after refreshing Finder, and unchanged Copy Path behavior verified against the clipboard. A native window screenshot confirms the small monochrome toolbar mark. Menu-open screenshots were unavailable through the UI capture tool, so menu-image sizing/template transport was checked with image inspection rather than a captured live menu.
- Native dark-appearance and macOS 15.7/26 checks remain pending; template semantics and compile-time deployment targeting do not replace those checks.

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
