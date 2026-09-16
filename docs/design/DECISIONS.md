# 设计与架构决定

2026-09-16：用户选择首次展示的第一套草图，并明确要求保留其中的 logo。

- 视觉参考：`selected-concept.png`；蓝底、白色斜体小写 `go`。
- 图标母版：`Assets/AppIcon.png`；由内置 ImageGen 参考选定草图提取并生成独立透明图标。ICNS 仅作标准尺寸导出。
- 图标生成指令：从草图右上角关于页面忠实提取唯一的蓝色圆角方块与白色斜体小写 go，保留字形、蓝色渐变与圆角；透明外边距，不增加符号、背景或其他文字。
- SwiftUI 原生设置内容 + AppKit 窗口、应用启动与生命周期；使用系统字体和 SF Symbols。
- 左侧导航、中间启动项列表、右侧编辑面板；Finder、通用、关于独立页面。
- `.app` 的参数只在进程启动时传入，界面明确提示“新应用实例”；文件打开模式用于复用运行中的应用。
- 自定义可执行文件才提供真正的工作目录设置，避免把无法保证的 `.app` 进程工作目录显示为可用功能。
- Finder 菜单采用系统 NSMenu，不自行绘制替代菜单。根目录仅声明菜单观察范围，不扫描文件、不添加 badge。
- 共享配置使用 App Group 中单个版本化 JSON 文件；宿主单写者，扩展只读，菜单打开时重读。
- 按需请求通过主程序新实例的参数传递，设置实例保持独立；不注册可被网页触发的自定义 URL scheme。
- 不设置 tray、登录项、轮询守护进程或常驻 XPC service。
- 引用讨论中的 macOS 27 根因分析只是候选假设，不作为已证实事实。

## 官方 API 依据

- [Finder Sync](https://developer.apple.com/documentation/findersync)
- [FIFinderSync](https://developer.apple.com/documentation/findersync/fifindersync-swift.class)
- [NSWorkspace.OpenConfiguration.createsNewApplicationInstance](https://developer.apple.com/documentation/appkit/nsworkspace/openconfiguration/createsnewapplicationinstance)
- [App Groups](https://developer.apple.com/documentation/xcode/configuring-app-groups)
- [Ghostty CLI configuration](https://ghostty.org/docs/config)

原草图“无后台常驻”指主程序不常驻；Finder 扩展的进程寿命由 macOS 决定，不承诺系统中不存在扩展进程。
