# Native settings UI review

final result: passed

Scope: the captured standard-size light-appearance settings UI, with the user's Follow System default, drag ordering, and content-removal changes. This result does not cover Finder extension runtime, dark mode, or every window size.

## Evidence

- Visual baseline: `docs/design/selected-concept.png`, 1422 × 1106 px, containing a settings window, About, and Finder concepts.
- Main implementation: `docs/screenshots/launchers-en.png`, 1040 × 692 px including title bar, 1040 × 660 pt content.
- Additional implementation captures: `docs/screenshots/about-en.png`, `general-en.png`, `general-zh.png`, `general-auto.png`, `launchers-zh.png`, and `finder-en.png`, each 1040 × 692 px.
- The source and current launcher screenshot were opened together in one comparison input. The source is a multi-window board: compare its upper-left settings window, not the whole board, to the implementation.
- No pixel-for-pixel or CSS comparison is claimed. This is a native AppKit/SwiftUI app. Captures use one output pixel per logical point; the source board has no authoritative point density.
- Current main state: the restored Zed preset selected at the end of an eight-launcher list, including Fork and Typora. Both README screenshots were recaptured from the native app after adding the split Add Launcher button; no custom test launcher remains. The English labels and removed implementation details are intentional user-requested changes to the Chinese reference.
- Full-view evidence covers the sidebar/list/inspector hierarchy, native controls, row grouping, primary Save action, and retained logo. The standalone About and General captures provide readable focused evidence for branding and removed copy; an additional crop was unnecessary.

## Review findings

No actionable P0/P1/P2 mismatch was found within this captured scope.

- **Typography:** system fonts retain the reference's clear heading, field-label, and helper-text hierarchy. English and Chinese settings labels are readable. No clipped form label or hidden primary control was visible.
- **Spacing/layout:** the three-column structure, simple separators, row grouping, and inspector remain intact. The implemented window is taller than the reference's settings crop to accommodate an explicit launch-method choice; Save/Cancel remain visible.
- **Colors:** blue sidebar selection and enabled toggles, neutral native surfaces, and a blue Save button follow the reference. Inactive-window controls naturally turn gray; the final main capture shows the active appearance.
- **Image quality:** the blue-and-white go icon is retained and clear in the sidebar and About page. Installed apps use their real icons; missing apps use a system placeholder and a truthful availability label.
- **Copy/content:** New settings follow the system language; English and Simplified Chinese can be selected explicitly. About omits the bundle ID and development-validation copy. General and Finder omit process-lifecycle explanations. Argument and location guidance remains because it affects user choices.
- **Interactions:** direct add, preset deletion/restoration, unsaved-draft cancellation/confirmation, path/argument editing, save, language switching, and persistence were exercised. The split button separates custom creation from preset restoration, with a disabled arrow when all presets are present. Native list selection now drives the inspector, and reordered preview rows survive relaunch. Per-row action menus have been removed. A failed real-container save retained the previous visible value. Broader control coverage is tracked in `docs/VALIDATION.md`.

## Comparison history

1. Initial pass: blocked because Computer Use could not obtain screenshots reliably.
2. Current pass: native captures succeeded. The user's requested copy cleanup and direct-add change were applied before capture. The old screenshot blocker is resolved for this scope.
3. A normal-development save exposed an internal container name in an OS error. The app-model error mapping was changed to a user-facing message; write-failure state preservation is covered by tests.

## Follow-up coverage

- Inspect dark appearance and minimum window size.
- Exercise native failed-drop and remaining drag edge cases.
- Capture actual signed Finder menus on every supported OS; settings screenshots are not a substitute.
