import AppKit
import SwiftUI
import FinderSync

@MainActor
final class AppModel: ObservableObject {
    @Published var configuration = Configuration()
    @Published var error: String?
    @Published var readOnly = false
    @Published var extensionEnabled = false
    let file: ConfigurationFile?
    let preview: Bool

    init(preview: Bool) {
        self.preview = preview
        do {
            let file = try preview
                ? ConfigurationFile(url: URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("gogo-preview/configuration.json"))
                : SharedConfiguration.file()
            let loaded = try file.read()
            self.file = file
            configuration = loaded
        } catch {
            file = nil
            readOnly = true
            self.error = Texts.error(error, language: .system)
        }
        refreshExtension()
    }

    func t(_ key: String) -> String { Texts.get(key, language: configuration.language) }
    func refreshExtension() { extensionEnabled = FIFinderSyncController.isExtensionEnabled }
    func save(_ next: Configuration) -> Bool {
        do {
            guard !readOnly, let file else { throw GogoError.unavailableSharedContainer }
            try file.write(next)
            configuration = next
            return true
        } catch {
            self.error = Texts.error(error, language: configuration.language)
            return false
        }
    }
    func update(_ body: (inout Configuration) -> Void) {
        var next = configuration
        body(&next)
        _ = save(next)
    }
    func saveLauncher(_ launcher: Launcher) -> Bool {
        var next = configuration
        if let index = next.launchers.firstIndex(where: { $0.id == launcher.id }) { next.launchers[index] = launcher }
        else { next.launchers.append(launcher) }
        return save(next)
    }
}
