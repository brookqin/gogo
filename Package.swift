// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "GogoCore",
    platforms: [.macOS(.v15)],
    products: [.library(name: "GogoCore", targets: ["GogoCore"])],
    targets: [
        .target(name: "GogoCore"),
        .testTarget(name: "GogoCoreTests", dependencies: ["GogoCore"])
    ]
)
