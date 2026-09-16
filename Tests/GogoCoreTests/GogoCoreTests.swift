import Foundation
import Testing
@testable import GogoCore

@Test func adversarialPathsRemainIndividualArguments() throws {
    let path = "/tmp/a b/'\";$(touch bad)`whoami`\n中文"
    let launcher = Launcher(name: "Tool", program: "/usr/bin/true", method: .executable,
                            arguments: ["--flag", "{paths}", "--cwd={directory}"])
    let plan = try LaunchPlan.make(launcher: launcher, selection: LaunchSelection(paths: [path]), isDirectory: { _ in true })
    #expect(plan.arguments == ["--flag", path, "--cwd=" + path])
}

@Test func documentsSupportMultipleDirectoriesButWorkingDirectoryLaunchersRejectAmbiguity() throws {
    let selection = LaunchSelection(paths: ["/tmp/one", "/tmp/two"])
    var launcher = Launcher(name: "Tool", program: "/Applications/Tool.app")
    let plan = try LaunchPlan.make(launcher: launcher, selection: selection, isDirectory: { _ in true })
    #expect(plan.documents.map(\.path) == selection.paths)
    launcher.method = .application
    #expect(throws: GogoError.mixedDirectories) {
        try LaunchPlan.make(launcher: launcher, selection: selection, isDirectory: { _ in true })
    }
}

@Test func terminalFilesUseDeduplicatedParentDirectories() throws {
    let launcher = Launcher.presets[0]
    let plan = try LaunchPlan.make(launcher: launcher, selection: LaunchSelection(paths: ["/tmp/a.txt", "/tmp/b.txt"]), isDirectory: { _ in false })
    #expect(plan.documents.map(\.path) == ["/tmp"])
}

@Test func partialPathsTokenIsRejected() {
    let launcher = Launcher(name: "Tool", program: "/usr/bin/true", method: .executable, arguments: ["--files={paths}"])
    #expect(throws: GogoError.pathsMustBeWholeArgument) { try launcher.validate() }
}

@Test func configurationRoundTripAndCorruptionPreservation() throws {
    let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: dir) }
    let file = ConfigurationFile(url: dir.appendingPathComponent("config.json"))
    var config = Configuration()
    config.language = .zhHans
    config.launchers[0].enabled = false
    try file.write(config)
    #expect(try file.read() == config)
    let corrupt = Data("{not json".utf8)
    try corrupt.write(to: file.url)
    #expect(throws: (any Error).self) { try file.read() }
    #expect(try Data(contentsOf: file.url) == corrupt)
}

@Test func futureVersionIsRejected() throws {
    var configuration = Configuration(); configuration.version = 2
    #expect(throws: GogoError.unsupportedVersion) { try configuration.validate() }
}

@Test func requestRoundTripAndUntrustedInput() throws {
    let selection = LaunchSelection(paths: ["/tmp/hello 世界"])
    let request = LaunchRequest(launcherID: UUID(), selection: selection)
    let decoded = try LaunchRequest.decode(request.encoded())
    #expect(decoded.launcherID == request.launcherID)
    #expect(decoded.selection == selection)
    #expect(throws: GogoError.invalidRequest) { try LaunchRequest.decode("!invalid!") }
    #expect(throws: GogoError.invalidRequest) { try LaunchSelection(paths: ["https://example.com"]).urls() }
    #expect(throws: GogoError.invalidRequest) { try LaunchSelection(paths: []).urls() }
}

@Test func defaultPresetsValidate() throws { try Configuration().validate() }
