# gogo

[English](README.md) · 简体中文

<img src="Assets/AppIcon.png" alt="gogo" width="120" />

从 Finder 中，用喜欢的终端、编辑器或自定义程序打开文件与文件夹。

**当前为开发版本，尚未完成跨版本兼容性验收。** 最低部署目标为 macOS 15.7，计划覆盖 macOS 15.7、26、27。签名后的 Finder 集成仍需逐版本实机验证。

![gogo 原生设置界面](docs/screenshots/launchers-zh.png)

## Finder 菜单

**右键菜单**

![Finder 中的 gogo 右键菜单](docs/screenshots/finder-context-menu.png)

**工具栏菜单**

![Finder 中的 gogo 工具栏菜单](docs/screenshots/finder-toolbar-menu.png)

## 功能

- 内置 Terminal、iTerm2、Ghostty、Visual Studio Code、Zed、Fork、Typora、Xcode 启动预设。
- 支持自定义应用或可执行文件路径，逐行填写启动参数。
- Finder 右键子菜单与工具栏菜单，并保留设置入口。
- Finder 菜单覆盖已挂载的可见磁盘，包括移动硬盘，插入或推出磁盘后自动更新。
- 默认跟随系统语言，也可手动选择 English 或简体中文。
- 拖拽启动项调整顺序，点击行即可编辑，无行末操作菜单。
- 从 Finder 右键菜单或工具栏复制路径，多选时每行一个路径。
- 不创建菜单栏图标或登录项。

各终端和编辑器仍需独立验证；提供预设不代表该应用已在全部目标系统上通过测试。

## 安装

安装打包后的应用无需 Xcode 或 Apple 开发者账号。gogo 目前未经 Apple 公证，首次打开时可能被 macOS 拦截。

1. 在 [GitHub Releases](https://github.com/brookqin/gogo/releases) 有安装包发布后下载，解压 ZIP 或打开 DMG，将 **gogo.app** 拖入**应用程序**。
2. 打开 gogo。若 macOS 提示无法验证开发者，前往**系统设置 → 隐私与安全性 → 仍要打开**，再确认**打开**。仅在信任下载来源时继续，具体可参考 [Apple 官方说明](https://support.apple.com/zh-cn/102445)。
3. 在 gogo 中进入**通用 → Finder 扩展 → 管理扩展**，启用 gogo 的 Finder 扩展。不同 macOS 版本的系统设置位置可能有所不同。
4. 在 Finder 中选择**显示 → 自定工具栏**，添加 gogo 按钮。使用过程中，文件访问权限由 macOS 按需请求。

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

预览配置位于系统临时目录下的 `gogo-preview/configuration.json`，不会配置 Finder 扩展。

## 扩展未出现在系统设置中

设置界面能打开，不代表 Finder 扩展已经注册。签名时必须保留扩展的沙盒声明：仅使用 `codesign --sign -` 重新签名会移除该声明，PlugInKit 会以 `plug-ins must be sandboxed` 为由拒绝扩展。

将应用安装到 `/Applications` 并打开安装后的副本，再前往**系统设置 → 通用 → 登录项与扩展 → 按 App → gogo**。当前测试的 macOS 27 将 Finder Sync 标为“文件提供程序”。扩展是否启用由用户单独选择。

本地开发时可检查注册状态：

```sh
pluginkit -a /Applications/gogo.app/Contents/PlugIns/GogoFinder.appex
pluginkit -m -A -D -v -i cn.053x.gogo.finder
```

## 启动参数

- **用应用打开文件**：通过 LaunchServices 打开所选路径，可复用已运行的应用。
- **应用与启动参数**：启动新的应用实例，以便传入命令行参数。
- **可执行文件与参数**：直接运行绝对路径下的程序并设置工作目录，不经过 shell。

`{paths}` 必须单独占一行，每个所选路径作为独立参数传入。`{directory}` 表示所选文件夹或文件所在目录。无需添加 shell 引号，也不展开波浪号、环境变量、通配符或 shell 命令。

带参数的启动项目前要求所选项目对应同一个工作目录；文件打开方式允许选择多个目录。

## 设置界面

拖拽启动项即可调整顺序，松开后自动保存。点击启动项进入编辑面板。

点击**添加启动项**可新建自定义启动项，旁边的箭头用于恢复已移除的预设，不影响已有启动项。

可在“通用”中选择跟随系统、English 或简体中文。

## 参与开发

配置和参数逻辑位于 `Sources/GogoCore`，测试位于 `Tests`。主程序界面位于 `Sources/Gogo`，Finder 扩展位于 `Sources/GogoFinder`。中英文文本资源分别位于 `Resources/zh-Hans.lproj` 和 `Resources/en.lproj`。

[选定的设计草图](docs/design/selected-concept.png) · [验证记录（英文）](docs/VALIDATION.md)

## 致谢

使用场景受 [OpenInTerminal](https://github.com/Ji4n1ng/OpenInTerminal) 启发。gogo 使用 Swift 独立实现。

## 许可证

[MIT](LICENSE)。
