# Validation record

Date: September 16, 2026. Environment: macOS 27.0 (26A428), Xcode 27.0 (27A266a), Apple Silicon.

## Verified in the current revision

- **20 tests passed:** 9 core tests and 11 application-support tests.
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
- Closing the settings window was followed by a process check: no gogo process remained. Computer Use automatically relaunches a closed app when asked to read it again, so the exit check was performed independently.
- Reproduced the installed application's save failure by enabling Zed. Replaced protected App Group file storage with a versioned JSON snapshot in CFPreferences and a read-only shared-preference entitlement for the Finder extension. On the installed ad-hoc build, enabling Zed succeeds, survives host restart, and appears in the Finder toolbar menu.
- Shared-preference tests cover complete-snapshot persistence across separate store/model instances and corrupt-data preservation with the UI remaining read-only. The isolated file store now distinguishes a missing file from other read errors.
- Native Finder toolbar Copy Path wrote the current folder path to the clipboard. The gogo context submenu copied two selected folder paths separated by a newline, verified against the exact selected paths. Menu payloads are retained in the extension and looked up by transported integer tags; passing representedObject did not produce a working copy action in the tested Finder runtime.
- Copy Path remains independent of launcher enablement and is also built in the configuration-error recovery menu. English and Chinese labels are present. Empty selections disable the command; error/empty cases remain code-reviewed rather than separate native runtime checks.

## Screenshots

- [Launchers, English](screenshots/launchers-en.png)
- [Launchers, Simplified Chinese](screenshots/launchers-zh.png)
- [General, Follow System](screenshots/general-auto.png)
- [About, English](screenshots/about-en.png)
- [General, English](screenshots/general-en.png)
- [General, Simplified Chinese](screenshots/general-zh.png)
- [Finder settings, English](screenshots/finder-en.png)

The preview uses a separate configuration file. Its successful saves do not prove shared-preference access or Finder extension behavior; installed runtime checks are recorded separately above.

## Remaining gaps

| Check | Status |
| --- | --- |
| Shared settings | Installed ad-hoc host save/relaunch and sandboxed Finder read verified on macOS 27. App Groups are no longer used. Other OS versions and Developer ID builds remain pending. |
| Finder registration | Ad-hoc local installation in `/Applications/gogo.app` is registered by PlugInKit and visible in System Settings on macOS 27. Original preview signatures omitted the sandbox entitlement; pkd explicitly rejected them. Re-signing with the configured entitlements and registering the installed containing app resolved discovery. |
| Finder toolbar image | Extension enablement and toolbar-image callbacks observed on macOS 27. A dedicated 18-point image with concrete 18px/36px bitmap representations renders correctly in the toolbar and customization palette after updating the installed app and refreshing Finder. Archive round-trip checks confirm both sizes and image coverage. |
| Finder menu actions | Toolbar and multi-selection context Copy Path verified against clipboard contents. Individual launcher dispatch still requires end-to-end validation. |
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
