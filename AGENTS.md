# gogo

- Communicate with the user in Chinese unless requested otherwise. Maintain both English and Simplified Chinese READMEs; keep developer documentation in English.
- Native Swift macOS app; deployment target 15.7, intended coverage macOS 15.7, 26, and 27.
- Default new configurations to Follow System; keep explicit English and Simplified Chinese choices available. Preserve saved language choices.
- The host provides settings and About only, without a resident menu bar icon. macOS manages the Finder extension.
- Follow `docs/design/selected-concept.png` and retain the blue icon with white italic `go`.
- Keep implementation details out of the UI: no bundle ID in About, process-lifecycle notes, signing architecture, or internal verification status. Explain behavior only when it helps the user make a choice.
- Add Launcher is a split button: the main segment opens a custom editor directly, and the separate arrow lists missing presets. Disable the arrow when no presets are missing. Restoring a preset appends and enables it without resetting existing launchers. Launcher rows are reordered by dragging and edited by clicking; do not add per-row action menus.
- Version shared configuration and write it atomically. Never overwrite a file that failed to load.
- Pass arguments as arrays; never interpolate user paths into shell source.
- Update English and Chinese resources together. Compilation does not establish Finder runtime compatibility.
- Do not commit credentials, certificates, private keys, personal signing settings, build artifacts, or user configuration.
