import Foundation

public struct LaunchSelection: Codable, Equatable, Sendable {
    public var paths: [String]
    public init(paths: [String]) { self.paths = paths }

    public func urls() throws -> [URL] {
        guard !paths.isEmpty, paths.count <= 256,
              paths.allSatisfy({ $0.hasPrefix("/") && !$0.contains("\0") && $0.utf8.count <= 16384 }) else { throw GogoError.invalidRequest }
        return paths.map { URL(fileURLWithPath: $0) }
    }
}

public struct LaunchRequest: Codable, Sendable {
    public var launcherID: UUID
    public var selection: LaunchSelection
    public init(launcherID: UUID, selection: LaunchSelection) {
        self.launcherID = launcherID; self.selection = selection
    }
    public func encoded() throws -> String {
        try JSONEncoder().encode(self).base64EncodedString()
    }
    public static func decode(_ value: String) throws -> LaunchRequest {
        guard value.utf8.count <= 128 * 1024, let data = Data(base64Encoded: value) else { throw GogoError.invalidRequest }
        let result = try JSONDecoder().decode(Self.self, from: data)
        _ = try result.selection.urls()
        return result
    }
}

public struct LaunchPlan: Equatable, Sendable {
    public var documents: [URL]
    public var arguments: [String]
    public var directory: URL

    /// No shell evaluation. A path containing quotes, spaces or command syntax stays one argument.
    public static func make(launcher: Launcher, selection: LaunchSelection,
                            isDirectory: (URL) -> Bool) throws -> LaunchPlan {
        try launcher.validate()
        let urls = try selection.urls()
        guard urls.allSatisfy({ isDirectory($0) ? launcher.acceptsFolders : launcher.acceptsFiles }) else { throw GogoError.invalidScope }
        var directories: [URL] = []
        for url in urls {
            let directory = isDirectory(url) ? url : url.deletingLastPathComponent()
            if !directories.contains(directory) { directories.append(directory) }
        }
        // A single working directory cannot represent multiple unrelated folders.
        // Document launchers can open all selected paths; argument-based launchers ask for a narrower selection.
        if launcher.method != .documents && directories.count > 1 { throw GogoError.mixedDirectories }
        let directory = launcher.workingDirectory == "{directory}"
            ? directories[0] : URL(fileURLWithPath: launcher.workingDirectory, isDirectory: true)
        let documents = launcher.directoriesOnly ? directories : urls
        let arguments = launcher.arguments.flatMap { argument -> [String] in
            if argument == "{paths}" { return documents.map(\.path) }
            return [argument.replacingOccurrences(of: "{directory}", with: directory.path)]
        }
        return LaunchPlan(documents: documents, arguments: arguments, directory: directory)
    }
}
