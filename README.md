# gogo

English · [简体中文](README.zh-CN.md)

<img src="Assets/AppIcon.png" alt="gogo" width="120" />

Open Finder selections in your favorite terminal, editor, or custom program.

gogo is an independent Swift macOS project inspired by the workflow of [OpenInTerminal](https://github.com/Ji4n1ng/OpenInTerminal). The host app provides settings and About only. It has no menu bar icon or login item and quits when its settings window closes. macOS manages the Finder extension separately.

**Development version, not a compatibility-certified release.** Deployment target: macOS 15.7. Intended coverage: macOS 15.7, 26, and 27. Signed Finder integration still requires validation on each version.

![Native gogo settings in English](docs/screenshots/launchers-en.png)

## Features

- Configurable presets for Terminal, iTerm2, Ghostty, Visual Studio Code, Zed, Fork, Typora, and Xcode.
- Custom application or executable paths and one argument per line.
- Finder context submenu and toolbar menu, with a persistent Settings recovery entry.
- Drag to reorder launchers; click a row to edit.
- Automatically follows the system language, with English and Simplified Chinese overrides.
- Copy paths from the Finder context menu or toolbar (multiple selections are separated by newlines).
- Versioned shared settings stored as complete snapshots. Unreadable settings are never silently overwritten.
- On-demand launch handling; the host exits after dispatching the selected application.

Presets require individual application and OS validation. Their presence does not imply all integrations have passed.

## Build

Requires Xcode and system Python 3; no third-party runtime dependencies. Initially compiled using Xcode 27.

```sh
swift test
./scripts/build.sh CODE_SIGNING_ALLOWED=NO
```

The script generates `gogo.xcodeproj` and builds `.build/xcode/Build/Products/Debug/gogo.app`. Unsigned builds only establish compilation.

For isolated settings UI preview:

```sh
codesign --force --sign - --entitlements Config/Finder.entitlements .build/xcode/Build/Products/Debug/gogo.app/Contents/PlugIns/GogoFinder.appex
codesign --force --sign - --entitlements Config/Gogo.entitlements .build/xcode/Build/Products/Debug/gogo.app
open -n .build/xcode/Build/Products/Debug/gogo.app --args --preview
```

Preview configuration lives under `gogo-preview/configuration.json` in the system temporary directory and does not configure the Finder extension. Ad-hoc signing is not a distribution workflow.

For distribution, configure the same development team and valid signing for both Xcode targets. App Group provisioning is not required. Host bundle ID: `cn.053x.gogo`; extension: `cn.053x.gogo.finder`. Signing settings may also be passed to the build script, for example `DEVELOPMENT_TEAM=YOUR_TEAM CODE_SIGN_IDENTITY="Apple Development"`.

After installation, open gogo once and use **Finder → Manage Extensions**. Finder toolbar customization controls the button's placement. Extension settings entry points must be checked on each supported macOS version.

## Extension not listed

A settings preview does not establish Finder registration. Keep the extension's sandbox entitlement when signing: re-signing with only `codesign --sign -` removes it, and PlugInKit rejects the extension with `plug-ins must be sandboxed`.

Install the app in `/Applications`, open the installed copy, then check **System Settings → General → Login Items & Extensions → By App → gogo**. On the tested macOS 27 build, Finder Sync appears under the File Providers label. Enablement is a separate user choice.

For a local development registration check:

```sh
pluginkit -a /Applications/gogo.app/Contents/PlugIns/GogoFinder.appex
pluginkit -m -A -D -v -i cn.053x.gogo.finder
```

The host writes one versioned JSON snapshot through CFPreferences in `cn.053x.gogo.settings`. The sandboxed extension has a read-only shared-preference entitlement for that exact domain and refreshes it when opening a menu. This supports local ad-hoc builds without a protected App Group container. Developer ID signing and notarization still require release validation.

Older development builds used `group.cn.053x.gogo/configuration.json`. That file is left untouched; inaccessible old-container settings are not automatically imported. Preview settings remain separate.

**Copy Path:** right-click selected files/folders to copy their absolute paths, one per line. The toolbar and folder-background menu copy the current folder path. Paths are plain text, without shell quoting.

## Arguments

- **Open files with application** uses LaunchServices and may reuse the running application.
- **Application with arguments** starts a new instance so arguments are delivered at launch.
- **Executable with arguments** runs an absolute executable path with a working directory, without a shell.

Use `{paths}` on its own line for selected paths, one argument per item. Use `{directory}` for the selected directory or a file's parent directory. Do not add shell quotes. Tilde, environment variables, globbing, and shell commands are not expanded. Argument-based launchers currently require a selection that resolves to one working directory; document launchers allow multiple directories.

User-selected executables may themselves be long-lived. The host's lifecycle does not terminate them.

## Configuration UI

Drag launcher rows to change their order; changes are saved when you drop. Click a row to edit it.

**Add Launcher** is a split button. Click the main segment to create a custom launcher; Save adds it and Cancel discards the draft. The separate arrow lists missing presets. Select one to restore its default settings, enable it, and append it to the list. Existing launchers keep their order and settings. The arrow is disabled when there are no presets to restore. The selected design and blue `go` logo remain the visual baseline. About shows product information without the bundle identifier. Implementation and release-validation details belong in developer documentation.

Existing saved language choices are preserved. New configurations default to Follow System.

## Contributing

Core models and argument tests are under `Sources/GogoCore` and `Tests/GogoCoreTests`. The host UI is under `Sources/Gogo`; the thin Finder extension is under `Sources/GogoFinder`. Translation resources are in `Resources/en.lproj` and `Resources/zh-Hans.lproj`.

[Selected design](docs/design/selected-concept.png) · [Validation record](docs/VALIDATION.md)

## License

[MIT](LICENSE). Independently implemented; no OpenInTerminal source code was copied.
