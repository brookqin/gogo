import Foundation
import Testing
import GogoCore
@testable import GogoAppSupport

private func temporaryDirectory() throws -> URL {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("gogo-tests-" + UUID().uuidString)
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}

@MainActor @Test func newSettingsFollowSystemAndPersistAnExplicitChoice() throws {
    let directory = try temporaryDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }
    let file = ConfigurationFile(url: directory.appendingPathComponent("configuration.json"))
    let model = AppModel(preview: true, configurationFile: file)
    #expect(model.configuration.language == .system)
    #expect(model.update { $0.language = .zhHans })
    #expect(AppModel(preview: true, configurationFile: file).configuration.language == .zhHans)
    #expect(model.update { $0.language = .en })
    #expect(AppModel(preview: true, configurationFile: file).configuration.language == .en)
}

@MainActor @Test func launcherEditingOrderingAndRemovalSurviveReload() throws {
    let directory = try temporaryDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }
    let file = ConfigurationFile(url: directory.appendingPathComponent("configuration.json"))
    let model = AppModel(preview: true, configurationFile: file)
    var launcher = Launcher(name: "My Tool", program: "/usr/bin/true", method: .executable)
    #expect(model.saveLauncher(launcher))
    launcher.name = "Renamed Tool"
    #expect(model.saveLauncher(launcher))
    #expect(model.configuration.launchers.filter { $0.id == launcher.id }.count == 1)
    #expect(model.update { configuration in
        configuration.launchers.swapAt(0, configuration.launchers.count - 1)
        configuration.launchers[0].enabled = false
    })
    let reloaded = AppModel(preview: true, configurationFile: file)
    #expect(reloaded.configuration.launchers[0].name == "Renamed Tool")
    #expect(reloaded.configuration.launchers[0].enabled == false)
    #expect(reloaded.update { $0.launchers.removeAll { $0.id == launcher.id } })
    #expect(try file.read().launchers.allSatisfy { $0.id != launcher.id })
}

@MainActor @Test func failedSaveDoesNotPublishUnsavedChanges() throws {
    let directory = try temporaryDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }
    let file = ConfigurationFile(url: directory.appendingPathComponent("configuration.json"))
    let model = AppModel(preview: true, configurationFile: file)
    let initial = model.configuration
    // A directory at the destination forces a real atomic-write failure, even when running as root.
    try FileManager.default.createDirectory(at: file.url, withIntermediateDirectories: true)
    #expect(!model.update { $0.launchers.removeFirst() })
    #expect(model.configuration == initial)
    #expect(model.error != nil)
}

@MainActor @Test func corruptConfigurationRemainsReadOnlyAndUnmodified() throws {
    let directory = try temporaryDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }
    let file = ConfigurationFile(url: directory.appendingPathComponent("configuration.json"))
    let bytes = Data("{broken".utf8)
    try bytes.write(to: file.url)
    let model = AppModel(preview: true, configurationFile: file)
    #expect(model.readOnly)
    #expect(!model.update { $0.language = .en })
    #expect(try Data(contentsOf: file.url) == bytes)
}

@MainActor @Test func executableReceivesLiteralArgumentsAndWorkingDirectory() async throws {
    let directory = try temporaryDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }
    let script = directory.appendingPathComponent("capture.sh")
    let output = directory.appendingPathComponent("arguments.txt")
    let cwd = directory.appendingPathComponent("cwd.txt")
    try Data("printf '%s' \"$2\" > \"$1\"\npwd -P > \"$3\"\n".utf8).write(to: script)
    let literal = "space 'quote' \"double\" $(touch SHOULD_NOT_EXIST) `whoami`\n中文"
    let launcher = Launcher(name: "Argument fixture", program: "/bin/sh", method: .executable,
                            arguments: [script.path, output.path, literal, cwd.path])
    var configuration = Configuration(); configuration.launchers = [launcher]
    try await LauncherEngine.run(LaunchRequest(launcherID: launcher.id, selection: LaunchSelection(paths: [directory.path])), configuration: configuration)
    for _ in 0..<100 {
        if FileManager.default.fileExists(atPath: cwd.path), (try? Data(contentsOf: cwd).isEmpty) == false { break }
        try await Task.sleep(for: .milliseconds(20))
    }
    #expect(try String(contentsOf: output, encoding: .utf8) == literal)
    let actualDirectory = try String(contentsOf: cwd, encoding: .utf8).trimmingCharacters(in: .newlines)
    // Foundation may preserve /var while pwd resolves it to /private/var.
    // Compare the actual filesystem identity rather than two spellings of that directory.
    let actual = try FileManager.default.attributesOfItem(atPath: actualDirectory)
    let expected = try FileManager.default.attributesOfItem(atPath: directory.path)
    #expect(actual[.systemNumber] as? NSNumber == expected[.systemNumber] as? NSNumber)
    #expect(actual[.systemFileNumber] as? NSNumber == expected[.systemFileNumber] as? NSNumber)
    #expect(!FileManager.default.fileExists(atPath: directory.appendingPathComponent("SHOULD_NOT_EXIST").path))
}

@MainActor @Test func disabledLaunchersAreRejectedBeforeExecution() async throws {
    let launcher = Launcher(name: "Disabled", program: "/usr/bin/true", method: .executable, enabled: false)
    var configuration = Configuration(); configuration.launchers = [launcher]
    await #expect(throws: GogoError.invalidRequest) {
        try await LauncherEngine.run(LaunchRequest(launcherID: launcher.id, selection: LaunchSelection(paths: ["/tmp"])), configuration: configuration)
    }
}

@MainActor @Test func dragReorderingMovesRatherThanSwapsAndPersists() throws {
    let directory = try temporaryDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }
    let file = ConfigurationFile(url: directory.appendingPathComponent("configuration.json"))
    let model = AppModel(preview: true, configurationFile: file)
    let initial = model.configuration.launchers
    #expect(model.moveLaunchers(from: IndexSet(integer: 0), to: initial.count))
    #expect(model.configuration.launchers == Array(initial.dropFirst()) + [initial[0]])
    #expect(try file.read().launchers == model.configuration.launchers)
    #expect(model.moveLaunchers(from: IndexSet(integer: initial.count - 1), to: 0))
    #expect(try file.read().launchers == initial)
    #expect(model.moveLaunchers(from: IndexSet([0, 2]), to: initial.count))
    #expect(model.configuration.launchers == [initial[1]] + Array(initial.dropFirst(3)) + [initial[0], initial[2]])
}

@MainActor @Test func failedOrInvalidDragDoesNotChangeOrder() throws {
    let directory = try temporaryDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }
    let file = ConfigurationFile(url: directory.appendingPathComponent("configuration.json"))
    let model = AppModel(preview: true, configurationFile: file)
    let initial = model.configuration
    #expect(!model.moveLaunchers(from: IndexSet(integer: 999), to: 0))
    #expect(!model.moveLaunchers(from: IndexSet(integer: 0), to: -1))
    try FileManager.default.createDirectory(at: file.url, withIntermediateDirectories: true)
    #expect(!model.moveLaunchers(from: IndexSet(integer: 0), to: 3))
    #expect(model.configuration == initial)
}

@MainActor @Test func removedPresetsRestoreWithoutChangingExistingLaunchers() throws {
    let directory = try temporaryDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }
    let file = ConfigurationFile(url: directory.appendingPathComponent("configuration.json"))
    let model = AppModel(preview: true, configurationFile: file)
    let preset = try #require(Launcher.presets.first { $0.method == .iTerm })
    let custom = Launcher(name: preset.name, program: "/usr/bin/true", method: .executable)
    #expect(model.update {
        $0.launchers.removeAll { $0.id == preset.id }
        $0.launchers.reverse()
        $0.launchers[0].name = "Renamed preset"
        $0.launchers.append(custom)
    })
    let existing = model.configuration.launchers
    #expect(model.availablePresets.map(\.id) == [preset.id])
    let restored = try #require(model.restorePreset(id: preset.id))
    var expected = preset; expected.enabled = true
    #expect(restored == expected)
    #expect(model.configuration.launchers == existing + [expected])
    #expect(model.availablePresets.isEmpty)
    #expect(model.restorePreset(id: preset.id) == nil)
    #expect(model.restorePreset(id: UUID()) == nil)
    #expect(AppModel(preview: true, configurationFile: file).configuration == model.configuration)
}

@MainActor @Test func failedPresetRestoreRemainsAvailableAndPreservesConfiguration() throws {
    let directory = try temporaryDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }
    let file = ConfigurationFile(url: directory.appendingPathComponent("configuration.json"))
    var configuration = Configuration()
    let preset = configuration.launchers.removeFirst()
    try file.write(configuration)
    let model = AppModel(preview: true, configurationFile: file)
    try FileManager.default.removeItem(at: file.url)
    try FileManager.default.createDirectory(at: file.url, withIntermediateDirectories: true)
    #expect(model.restorePreset(id: preset.id) == nil)
    #expect(model.configuration == configuration)
    #expect(model.availablePresets.map(\.id) == [preset.id])
    #expect(model.error != nil)
}

@MainActor @Test func sharedPreferencesPersistCompleteSnapshotsAndRejectCorruption() throws {
    let domain = "cn.053x.gogo.test." + UUID().uuidString
    let store = PreferencesConfiguration(domain: domain)
    defer { UserDefaults.standard.removePersistentDomain(forName: domain) }
    let model = AppModel(preview: false, configurationFile: store)
    #expect(model.configuration == Configuration())
    #expect(model.update { $0.launchers[1].enabled = true; $0.language = .en })
    let reloaded = AppModel(preview: false, configurationFile: PreferencesConfiguration(domain: domain))
    #expect(reloaded.configuration == model.configuration)
    let corrupt = Data("invalid JSON".utf8)
    CFPreferencesSetValue("configuration" as CFString, corrupt as CFData, domain as CFString,
                          kCFPreferencesCurrentUser, kCFPreferencesAnyHost)
    #expect(CFPreferencesSynchronize(domain as CFString, kCFPreferencesCurrentUser, kCFPreferencesAnyHost))
    let broken = AppModel(preview: false, configurationFile: store)
    #expect(broken.readOnly)
    #expect(!broken.update { $0.language = .zhHans })
    #expect(CFPreferencesCopyValue("configuration" as CFString, domain as CFString,
                                  kCFPreferencesCurrentUser, kCFPreferencesAnyHost) as? Data == corrupt)
}

@Test func handoffDocumentsAreValidatedAndConsumedOnce() throws {
    let directory = try temporaryDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }
    let url = directory.appendingPathComponent(UUID().uuidString + ".gogorequest")
    let request = LaunchRequest(launcherID: Launcher.presets[0].id,
                                selection: LaunchSelection(paths: ["/Volumes/Drive with spaces/中文"]))
    try Data(request.encoded().utf8).write(to: url)
    let decoded = try LaunchHandoff.consume(url, directory: directory)
    #expect(decoded.launcherID == request.launcherID)
    #expect(decoded.selection == request.selection)
    #expect(!FileManager.default.fileExists(atPath: url.path))
    #expect(throws: GogoError.invalidRequest) { try LaunchHandoff.consume(url, directory: directory) }
}

@Test func handoffRejectsOutsidePathsSymlinksExpiredAndOversizedFiles() throws {
    let directory = try temporaryDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }
    let outside = directory.appendingPathComponent(UUID().uuidString + ".gogorequest")
    let insideDirectory = directory.appendingPathComponent("requests")
    try FileManager.default.createDirectory(at: insideDirectory, withIntermediateDirectories: true)
    let request = LaunchRequest(launcherID: Launcher.presets[0].id, selection: LaunchSelection(paths: ["/tmp"]))
    try Data(request.encoded().utf8).write(to: outside)
    #expect(throws: GogoError.invalidRequest) { try LaunchHandoff.consume(outside, directory: insideDirectory) }
    let url = insideDirectory.appendingPathComponent(UUID().uuidString + ".gogorequest")
    try FileManager.default.createSymbolicLink(at: url, withDestinationURL: outside)
    #expect(throws: GogoError.invalidRequest) { try LaunchHandoff.consume(url, directory: insideDirectory) }
    try FileManager.default.removeItem(at: url)
    try Data(request.encoded().utf8).write(to: url)
    try FileManager.default.setAttributes([.modificationDate: Date(timeIntervalSinceNow: -600)], ofItemAtPath: url.path)
    #expect(throws: GogoError.invalidRequest) { try LaunchHandoff.consume(url, directory: insideDirectory) }
    try Data(repeating: 65, count: 128 * 1024 + 1).write(to: url)
    #expect(throws: GogoError.invalidRequest) { try LaunchHandoff.consume(url, directory: insideDirectory) }
    #expect(FileManager.default.fileExists(atPath: outside.path))
}
