# Validation record

Date: September 16, 2026. Environment: macOS 27.0 (26A428), Xcode 27.0 (27A266a), Apple Silicon.

## Verified in the current revision

- **17 tests passed:** 9 core tests and 8 application-support tests.
- Core coverage: literal Unicode, quote, space, and newline arguments; selection semantics; parent-folder deduplication; configuration round trips; corruption preservation; unsupported versions; invalid and oversized launch requests.
- App-model coverage: Follow System defaults, preservation of explicit Chinese/English choices, add/edit/disable/remove persistence, drag move semantics in both directions and across multiple indices, rejected invalid moves, failed writes leaving published state unchanged, and corrupt configuration remaining read-only.
- Actual process test: the launcher starts a controlled executable fixture, which records its received argument and working directory. Shell-like text stays literal and does not execute; the working directory's filesystem identity matches the requested folder.
- Unsigned Debug build passed for the host and Finder extension.
- Unsigned Release universal build passed for both targets with arm64 and x86_64. Deployment target remains 15.7. This is build evidence, not runtime evidence for Intel or earlier macOS versions.
- English and Chinese localization resources have matching keys. English and Simplified Chinese READMEs are maintained together; developer documentation remains English.
- New configurations follow the system language. On the Chinese-language development system the native UI opens in Chinese. Explicit saved choices remain unchanged.
- Add Launcher is a regular button and directly opens a new custom-launcher editor, without an intermediate menu.
- In isolated preview, a custom application path and two argument lines were saved through the UI. The resulting configuration file contained the exact path and argument array.
- English → Simplified Chinese → English was verified in preview. The sidebar, settings content, and application Edit menu update without relaunching. Follow System was also selected and persisted through the native picker.
- Native launcher rows expose no action menu. Clicking a row updates the inspector; a reordered preview list was observed in the UI and configuration file, then retained after relaunch.
- About, General, and Finder screenshots confirm that the bundle ID, lifecycle explanation, and internal compatibility status are absent from the UI.
- Closing the settings window was followed by a process check: no gogo process remained. Computer Use automatically relaunches a closed app when asked to read it again, so the exit check was performed independently.
- Real shared-container write denial was observed in a non-preview ad-hoc/unsigned development run. The UI retained its original language rather than pretending the save had succeeded. The underlying container name is now replaced by a user-facing save error.

## Screenshots

- [Launchers, English](screenshots/launchers-en.png)
- [Launchers, Simplified Chinese](screenshots/launchers-zh.png)
- [General, Follow System](screenshots/general-auto.png)
- [About, English](screenshots/about-en.png)
- [General, English](screenshots/general-en.png)
- [General, Simplified Chinese](screenshots/general-zh.png)
- [Finder settings, English](screenshots/finder-en.png)

The preview uses a separate configuration file. Its successful saves do not prove App Group sharing or Finder extension behavior.

## Remaining gaps

| Check | Status |
| --- | --- |
| Signed App Group sharing | No valid code-signing identity is installed. Xcode rejects the entitlement-bearing development build without a certificate. A normal local run also demonstrated shared-container write denial. |
| Finder registration, enablement, contextual menu, toolbar callbacks, and dispatch | Pending signed installation and runtime validation. The Finder settings screenshot only verifies the host UI. |
| Individual terminal/editor integrations | Presets still need cold-start and already-running checks, including iTerm2 Automation approval and denial. The executable fixture does not establish terminal compatibility. |
| macOS 15.7 and 26 runtime | No matching runtime environment available. |
| Intel runtime | Universal binaries compiled; no Intel runtime validation. |
| UI delete/discard and drag edge cases | Basic row selection and reordered-list persistence were observed in preview. Failed-save, invalid-index, and multi-index moves are covered by model tests; exhaustive native interaction coverage remains pending. |
| Dark mode and minimum-window-size visual review | Pending; current captured visual scope is the standard-size light appearance. |
| Developer ID, notarization, DMG, downloaded installation | Not performed. No release is published. |

## Release acceptance

1. Sign both targets with the same team and matching App Group; install and launch from Applications.
2. Save settings in the host and verify menu order, enablement, and language refresh in the extension.
3. Exercise selected files/folders, background clicks, sidebar, toolbar, no accessible location, and multiple Finder windows.
4. Validate each preset cold and already running; test iTerm2 permission approval and denial.
5. Validate custom apps/executables, arguments, working folders, special characters, multiple selections, and missing applications.
6. Preserve configuration on read/write failure and unknown versions; retain a working Settings recovery action.
7. Record actual system versions and screenshots for 15.7, 26, and 27; verify settings and launch-request process lifecycles.
8. Validate signed/notarized release artifacts again after downloading and installing them independently.
