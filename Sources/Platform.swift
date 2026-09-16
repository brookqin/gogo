import AppKit
import Foundation
#if SWIFT_PACKAGE
import GogoCore
#endif

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
