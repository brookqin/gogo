import Foundation

public enum AppLanguage: String, Codable, CaseIterable, Sendable {
    case system, zhHans = "zh-Hans", en
}

public enum LaunchMethod: String, Codable, CaseIterable, Sendable {
    case documents, application, executable, iTerm
}

public struct Launcher: Codable, Identifiable, Equatable, Sendable {
    public var id: UUID
    public var name: String
    public var bundleID: String?
    public var program: String
    public var method: LaunchMethod
    public var arguments: [String]
    public var workingDirectory: String
    public var directoriesOnly: Bool
    public var acceptsFiles: Bool
    public var acceptsFolders: Bool
    public var enabled: Bool
    public var builtIn: Bool

    public init(id: UUID = UUID(), name: String, bundleID: String? = nil,
                program: String = "", method: LaunchMethod = .documents,
                arguments: [String] = ["{paths}"], workingDirectory: String = "{directory}",
                directoriesOnly: Bool = false, acceptsFiles: Bool = true,
                acceptsFolders: Bool = true, enabled: Bool = true, builtIn: Bool = false) {
        self.id = id; self.name = name; self.bundleID = bundleID
        self.program = program; self.method = method; self.arguments = arguments
        self.workingDirectory = workingDirectory; self.directoriesOnly = directoriesOnly
        self.acceptsFiles = acceptsFiles; self.acceptsFolders = acceptsFolders
        self.enabled = enabled; self.builtIn = builtIn
    }

    public static let presets: [Launcher] = [
        Launcher(id: UUID(uuidString: "A0000000-0000-4000-8000-000000000001")!, name: "Terminal", bundleID: "com.apple.Terminal", directoriesOnly: true, builtIn: true),
        Launcher(id: UUID(uuidString: "A0000000-0000-4000-8000-000000000002")!, name: "iTerm2", bundleID: "com.googlecode.iterm2", method: .iTerm, directoriesOnly: true, enabled: false, builtIn: true),
        Launcher(id: UUID(uuidString: "A0000000-0000-4000-8000-000000000003")!, name: "Ghostty", bundleID: "com.mitchellh.ghostty", method: .application, arguments: ["--working-directory={directory}"], directoriesOnly: true, enabled: false, builtIn: true),
        Launcher(id: UUID(uuidString: "A0000000-0000-4000-8000-000000000004")!, name: "Visual Studio Code", bundleID: "com.microsoft.VSCode", builtIn: true),
        Launcher(id: UUID(uuidString: "A0000000-0000-4000-8000-000000000005")!, name: "Cursor", bundleID: "com.todesktop.230313mzl4w4u92", enabled: false, builtIn: true),
        Launcher(id: UUID(uuidString: "A0000000-0000-4000-8000-000000000006")!, name: "Xcode", bundleID: "com.apple.dt.Xcode", enabled: false, builtIn: true)
    ]

    public func validate() throws {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw GogoError.invalidName }
        guard acceptsFiles || acceptsFolders else { throw GogoError.invalidScope }
        if bundleID == nil || !program.isEmpty {
            guard program.hasPrefix("/"), !program.contains("\0") else { throw GogoError.invalidProgram }
        }
        if method == .documents && arguments != ["{paths}"] {
            throw GogoError.documentArguments
        }
        for argument in arguments {
            guard !argument.contains("\0") else { throw GogoError.invalidArguments }
            if argument.contains("{paths}") && argument != "{paths}" { throw GogoError.pathsMustBeWholeArgument }
        }
        guard !workingDirectory.contains("\0"),
              workingDirectory == "{directory}" || workingDirectory.hasPrefix("/") else { throw GogoError.invalidDirectory }
    }
}

public struct Configuration: Codable, Equatable, Sendable {
    public var version = 1
    public var language: AppLanguage = .system
    public var showContextMenu = true
    public var showToolbarLaunchers = true
    public var launchers: [Launcher] = Launcher.presets
    public init() {}

    public func validate() throws {
        guard version == 1 else { throw GogoError.unsupportedVersion }
        guard Set(launchers.map(\.id)).count == launchers.count else { throw GogoError.duplicateIdentifier }
        for launcher in launchers { try launcher.validate() }
    }
}

public enum GogoError: String, Error, LocalizedError {
    case invalidName, invalidScope, invalidProgram, invalidArguments, invalidDirectory
    case pathsMustBeWholeArgument, unsupportedVersion, duplicateIdentifier, documentArguments
    case noSelection, mixedDirectories, invalidRequest, missingApplication, unavailableSharedContainer
    public var errorDescription: String? { rawValue }
}

/// The host is the sole writer. The Finder extension only reads snapshots.
public struct ConfigurationFile: Sendable {
    public let url: URL
    public init(url: URL) { self.url = url }
    public func read() throws -> Configuration {
        guard FileManager.default.fileExists(atPath: url.path) else { return Configuration() }
        let configuration = try JSONDecoder().decode(Configuration.self, from: Data(contentsOf: url))
        try configuration.validate()
        return configuration
    }
    public func write(_ configuration: Configuration) throws {
        try configuration.validate()
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(configuration).write(to: url, options: .atomic)
    }
}
