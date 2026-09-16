// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "GogoCore",
    platforms: [.macOS(.v15)],
    products: [.library(name: "GogoCore", targets: ["GogoCore"])],
    targets: [
        .target(name: "GogoCore"),
        .target(name: "GogoAppSupport", dependencies: ["GogoCore"], path: "Sources",
                exclude: ["GogoCore", "GogoFinder", "Gogo/main.swift", "Gogo/SettingsView.swift", "Gogo/PermissionGuide.swift"],
                sources: ["Platform.swift", "Gogo/AppModel.swift", "Gogo/LauncherEngine.swift", "Gogo/Permissions.swift"]),
        .testTarget(name: "GogoCoreTests", dependencies: ["GogoCore"]),
        .testTarget(name: "GogoAppSupportTests", dependencies: ["GogoAppSupport", "GogoCore"])
    ]
)
