# gogo

[English](README.md) · 简体中文

<img src="Assets/AppIcon.png" alt="gogo" width="120" />

从 Finder 中，用喜欢的终端、编辑器或自定义程序打开文件与文件夹。

gogo 是独立开发的 Swift macOS 项目，使用场景受 [OpenInTerminal](https://github.com/Ji4n1ng/OpenInTerminal) 启发。主程序只提供设置与关于页面，不创建常驻菜单栏图标或登录项；关闭设置窗口即退出。Finder 扩展由 macOS 管理。

**当前为开发版本，尚未完成跨版本兼容性验收。** 最低部署目标为 macOS 15.7，计划覆盖 macOS 15.7、26、27。签名后的 Finder 集成仍需逐版本实机验证。

![gogo 原生设置界面](docs/screenshots/launchers-zh.png)

## 功能

- 内置 Terminal、iTerm2、Ghostty、Visual Studio Code、Zed、Fork、Typora、Xcode 启动预设。
- 支持自定义应用或可执行文件路径，逐行填写启动参数。
- Finder 右键子菜单与工具栏菜单，并保留设置入口。
- 默认跟随系统语言，也可手动选择 English 或简体中文。
- 拖拽启动项调整顺序，点击行即可编辑，无行末操作菜单。
- 共享配置具有版本标识，以完整快照保存；读取失败时不会静默覆盖原有设置。
- 按需处理启动请求，完成后主程序退出。

各终端和编辑器仍需独立验证；提供预设不代表该应用已在全部目标系统上通过测试。

## 构建

需要 Xcode 和系统 Python 3，无第三方运行时依赖。当前使用 Xcode 27 构建验证。

```sh
swift test
./scripts/build.sh CODE_SIGNING_ALLOWED=NO
```

脚本生成 `gogo.xcodeproj`，构建产物位于 `.build/xcode/Build/Products/Debug/gogo.app`。未签名构建只用于编译检查。

如需使用独立配置预览设置界面：

```sh
codesign --force --sign - --entitlements Config/Finder.entitlements .build/xcode/Build/Products/Debug/gogo.app/Contents/PlugIns/GogoFinder.appex
codesign --force --sign - --entitlements Config/Gogo.entitlements .build/xcode/Build/Products/Debug/gogo.app
open -n .build/xcode/Build/Products/Debug/gogo.app --args --preview
```

预览配置位于系统临时目录下的 `gogo-preview/configuration.json`，不会配置 Finder 扩展。Ad-hoc 签名不能替代正式发行签名。

正式分发时，需为两个 Xcode target 配置同一开发团队与有效签名。无需配置 App Group provisioning。主程序 bundle ID 为 `cn.053x.gogo`，扩展为 `cn.053x.gogo.finder`。也可向构建脚本传入 `DEVELOPMENT_TEAM=你的团队ID CODE_SIGN_IDENTITY="Apple Development"`。

安装后先打开一次 gogo，再进入 **Finder → 管理扩展**。通过 Finder 的“显示 → 自定工具栏”调整按钮位置；扩展设置入口需要在各目标系统上验证。

## 扩展未出现在系统设置中

设置界面能打开，不代表 Finder 扩展已经注册。签名时必须保留扩展的沙盒声明：仅使用 `codesign --sign -` 重新签名会移除该声明，PlugInKit 会以 `plug-ins must be sandboxed` 为由拒绝扩展。

将应用安装到 `/Applications` 并打开安装后的副本，再前往**系统设置 → 通用 → 登录项与扩展 → 按 App → gogo**。当前测试的 macOS 27 将 Finder Sync 标为“文件提供程序”。扩展是否启用由用户单独选择。

本地开发时可检查注册状态：

```sh
pluginkit -a /Applications/gogo.app/Contents/PlugIns/GogoFinder.appex
pluginkit -m -A -D -v -i cn.053x.gogo.finder
```

本地 ad-hoc 安装的共享设置及拷贝路径已在 macOS 27 验证；各应用启动流程及其他系统版本仍需分别验证。

## 启动参数

- **用应用打开文件**：通过 LaunchServices 打开所选路径，可复用已运行的应用。
- **应用与启动参数**：启动新的应用实例，以便传入命令行参数。
- **可执行文件与参数**：直接运行绝对路径下的程序并设置工作目录，不经过 shell。

`{paths}` 必须单独占一行，每个所选路径作为独立参数传入。`{directory}` 表示所选文件夹或文件所在目录。无需添加 shell 引号，也不展开波浪号、环境变量、通配符或 shell 命令。

带参数的启动项目前要求所选项目对应同一个工作目录；文件打开方式允许选择多个目录。用户选择运行的程序可能长期运行，gogo 退出不会自动终止它。

## 设置界面

拖拽启动项即可调整顺序，松开后自动保存。点击启动项进入编辑面板。

**添加启动项**采用两段式按钮。点击左侧直接新建自定义启动项，保存后加入列表，取消则放弃草稿。右侧箭头列出当前缺少的预设，选择后恢复默认参数、启用并添加到列表末尾，不影响已有启动项的顺序和设置。没有需要恢复的预设时，箭头置灰。界面沿用选定的分栏设计与蓝底白色 `go` 图标；关于页只展示产品信息，不展示 bundle ID 或内部实现细节。

已有的语言选择会保留，新配置默认跟随系统。

## 参与开发

配置和参数逻辑位于 `Sources/GogoCore`，测试位于 `Tests`。主程序界面位于 `Sources/Gogo`，Finder 扩展位于 `Sources/GogoFinder`。中英文文本资源分别位于 `Resources/zh-Hans.lproj` 和 `Resources/en.lproj`。

[选定的设计草图](docs/design/selected-concept.png) · [验证记录（英文）](docs/VALIDATION.md)

## 许可证

[MIT](LICENSE)。本项目独立实现，未复制 OpenInTerminal 源码。

## 拷贝路径与共享设置

在 Finder 右键菜单和工具栏的 gogo 菜单中选择「拷贝路径」。右键选中文件或文件夹时，复制其绝对路径，多选以换行分隔；工具栏和文件夹空白处菜单复制当前文件夹路径。复制内容为普通文本，不添加 shell 引号。

主程序通过 CFPreferences 在 `cn.053x.gogo.settings` 域保存完整的版本化 JSON 配置，沙盒扩展仅有此域的只读权限，每次打开菜单重新读取。本地 ad-hoc 签名无需 App Group 容器即可保存和共享设置，正式发布仍需验证 Developer ID 签名与公证。

旧开发版的 `group.cn.053x.gogo/configuration.json` 保留不动；无法访问的旧容器设置不会自动导入。预览配置仍独立存储。
