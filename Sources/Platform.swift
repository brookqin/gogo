import AppKit
import Foundation

enum SharedConfiguration {
    static let groupID = "group.cn.053x.gogo"
    static func file() throws -> ConfigurationFile {
        guard let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupID) else {
            throw GogoError.unavailableSharedContainer
        }
        return ConfigurationFile(url: container.appendingPathComponent("configuration.json"))
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
