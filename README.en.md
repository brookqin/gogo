# gogo

English · [简体中文](README.md)

<img src="Assets/AppIcon.png" alt="gogo" width="120" />

Open Finder selections in your favorite terminal, editor, or custom program.

gogo is an independent Swift macOS project inspired by the workflow of [OpenInTerminal](https://github.com/Ji4n1ng/OpenInTerminal). The host app provides settings and About only. It has no menu bar icon or login item and quits when its settings window closes. macOS manages the Finder extension separately.

**Development version, not a compatibility-certified release.** Deployment target: macOS 15.7. Intended coverage: macOS 15.7, 26, and 27. Signed Finder integration still requires validation on each version.

## Features in the initial source implementation

- Configurable presets for Terminal, iTerm2, Ghostty, Visual Studio Code, Cursor, and Xcode.
- Custom application or executable paths and one argument per line.
- Finder context submenu and toolbar menu, with a persistent Settings recovery entry.
- English and Simplified Chinese, with a system-language option.
- Versioned, atomically written shared settings. Unreadable settings are never silently overwritten.
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
codesign --force --sign - .build/xcode/Build/Products/Debug/gogo.app/Contents/PlugIns/GogoFinder.appex
codesign --force --sign - .build/xcode/Build/Products/Debug/gogo.app
open -n .build/xcode/Build/Products/Debug/gogo.app --args --preview
```

Preview configuration lives under `gogo-preview/configuration.json` in the system temporary directory and does not configure the Finder extension. Ad-hoc signing is not a distribution workflow.

For real Finder installation, configure the same development team and valid signing/provisioning for both Xcode targets and App Group `group.cn.053x.gogo`. Host bundle ID: `cn.053x.gogo`; extension: `cn.053x.gogo.finder`. Signing settings may also be passed to the build script, for example `DEVELOPMENT_TEAM=YOUR_TEAM CODE_SIGN_IDENTITY="Apple Development"`.

After installation, open gogo once and use **Finder → Manage Extensions**. Finder toolbar customization controls the button's placement. Extension settings entry points must be checked on each supported macOS version.

## Arguments

- **Open files with application** uses LaunchServices and may reuse the running application.
- **Application with arguments** starts a new instance so arguments are delivered at launch.
- **Executable with arguments** runs an absolute executable path with a working directory, without a shell.

Use `{paths}` on its own line for selected paths, one argument per item. Use `{directory}` for the selected directory or a file's parent directory. Do not add shell quotes. Tilde, environment variables, globbing, and shell commands are not expanded. Argument-based launchers currently require a selection that resolves to one working directory; document launchers allow multiple directories.

User-selected executables may themselves be long-lived. The host's lifecycle does not terminate them.

## Contributing

Core models and argument tests are under `Sources/GogoCore` and `Tests/GogoCoreTests`. The host UI is under `Sources/Gogo`; the thin Finder extension is under `Sources/GogoFinder`. Translation resources are in `Resources/en.lproj` and `Resources/zh-Hans.lproj`.

[Selected design](docs/design/selected-concept.png) · [Validation record](docs/VALIDATION.md)

## License

[MIT](LICENSE). Independently implemented; no OpenInTerminal source code was copied.
