import AppKit
import Foundation
import Darwin
#if SWIFT_PACKAGE
import GogoCore
#endif

enum LaunchHandoff {
    static func directory() throws -> URL {
        // NSHomeDirectory() is the extension's sandbox, not the user's home.
        guard let home = getpwuid(getuid())?.pointee.pw_dir else { throw GogoError.invalidRequest }
        return URL(fileURLWithPath: String(cString: home), isDirectory: true)
            .appendingPathComponent("Library/Application Support/cn.053x.gogo/Requests", isDirectory: true)
    }

    static func write(_ request: LaunchRequest) throws -> URL {
        let data = Data(try request.encoded().utf8)
        let directory = try directory()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true,
                                               attributes: [.posixPermissions: 0o700])
        let url = directory.appendingPathComponent(UUID().uuidString).appendingPathExtension("gogorequest")
        try data.write(to: url, options: [.withoutOverwriting])
        return url
    }

    static func consume(_ url: URL, directory: URL? = nil) throws -> LaunchRequest {
        let expectedDirectory = try directory ?? self.directory()
        guard url.isFileURL, url.deletingLastPathComponent().standardizedFileURL == expectedDirectory.standardizedFileURL,
              url.pathExtension == "gogorequest", UUID(uuidString: url.deletingPathExtension().lastPathComponent) != nil else {
            throw GogoError.invalidRequest
        }
        let descriptor = Darwin.open(url.path, O_RDONLY | O_NOFOLLOW | O_NONBLOCK)
        guard descriptor >= 0 else { throw GogoError.invalidRequest }
        let handle = FileHandle(fileDescriptor: descriptor, closeOnDealloc: true)
        defer { try? handle.close() }
        var info = stat()
        guard fstat(descriptor, &info) == 0, info.st_mode & S_IFMT == S_IFREG,
              info.st_uid == getuid(), info.st_size > 0, info.st_size <= 128 * 1024,
              abs(Date().timeIntervalSince1970 - Double(info.st_mtimespec.tv_sec)) < 300 else {
            throw GogoError.invalidRequest
        }
        guard let data = try handle.read(upToCount: 128 * 1024 + 1), data.count <= 128 * 1024,
              let encoded = String(data: data, encoding: .utf8) else { throw GogoError.invalidRequest }
        let request = try LaunchRequest.decode(encoded)
        // Consume before dispatch; a stale document cannot replay the action.
        try FileManager.default.removeItem(at: url)
        return request
    }
}

enum SharedConfiguration {
    static func file() -> PreferencesConfiguration {
        PreferencesConfiguration(domain: "cn.053x.gogo.settings")
    }
}

/// One versioned JSON value is published as a complete snapshot through cfprefsd.
/// The extension has read-only access to this exact preference domain.
struct PreferencesConfiguration: ConfigurationStorage {
    let domain: String
    private var appID: CFString { domain as CFString }
    private var key: CFString { "configuration" as CFString }

    func read() throws -> Configuration {
        guard CFPreferencesSynchronize(appID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost) else {
            throw CocoaError(.fileReadUnknown)
        }
        guard let value = CFPreferencesCopyValue(key, appID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost) else {
            return Configuration()
        }
        guard let data = value as? Data else { throw CocoaError(.fileReadCorruptFile) }
        let configuration = try JSONDecoder().decode(Configuration.self, from: data)
        try configuration.validate()
        return configuration
    }

    func write(_ configuration: Configuration) throws {
        try configuration.validate()
        let data = try JSONEncoder().encode(configuration)
        let previous = CFPreferencesCopyValue(key, appID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost)
        CFPreferencesSetValue(key, data as CFData, appID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost)
        guard CFPreferencesSynchronize(appID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost) else {
            CFPreferencesSetValue(key, previous, appID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost)
            throw CocoaError(.fileWriteUnknown)
        }
    }
}

enum Texts {
    static func get(_ key: String, language: AppLanguage = .system) -> String {
        let languageCode: String
        switch language {
        case .system:
            languageCode = Bundle.preferredLocalizations(from: ["en", "zh-Hans"]).first ?? "en"
        case .en: languageCode = "en"
        case .zhHans: languageCode = "zh-Hans"
        }
        let bundle = Bundle.main.path(forResource: languageCode, ofType: "lproj").flatMap(Bundle.init(path:)) ?? .main
        return bundle.localizedString(forKey: key, value: key, table: nil)
    }
    static func error(_ error: Error, language: AppLanguage) -> String {
        if error is DecodingError { return get("configuration.readOnly", language: language) }
        if let known = error as? GogoError { return get("error." + known.rawValue, language: language) }
        return error.localizedDescription
    }
}

enum Applications {
    static func url(for launcher: Launcher) -> URL? {
        if !launcher.program.isEmpty {
            let url = URL(fileURLWithPath: launcher.program)
            return FileManager.default.fileExists(atPath: url.path) ? url : nil
        }
        return launcher.bundleID.flatMap { NSWorkspace.shared.urlForApplication(withBundleIdentifier: $0) }
    }
    static func isDirectory(_ url: URL) -> Bool {
        (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
    }
}
