import AppKit
import SwiftUI
import FinderSync
#if SWIFT_PACKAGE
import GogoCore
#endif

@MainActor
final class AppModel: ObservableObject {
    @Published var configuration = Configuration()
    @Published var error: String?
    @Published var readOnly = false
    @Published var extensionEnabled = false
    let file: ConfigurationFile?
    let preview: Bool

    init(preview: Bool, configurationFile: ConfigurationFile? = nil) {
        self.preview = preview
        do {
            let file = try configurationFile ?? (preview
                ? ConfigurationFile(url: URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("gogo-preview/configuration.json"))
                : SharedConfiguration.file())
            let loaded = try file.read()
            self.file = file
            configuration = loaded
        } catch {
            file = nil
            readOnly = true
            self.error = error is GogoError ? Texts.error(error, language: .system) : Texts.get("configuration.readOnly")
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
            self.error = error is GogoError ? Texts.error(error, language: configuration.language) : t("settings.saveFailed")
            return false
        }
    }
    @discardableResult
    func update(_ body: (inout Configuration) -> Void) -> Bool {
        var next = configuration
        body(&next)
        return save(next)
    }
    func saveLauncher(_ launcher: Launcher) -> Bool {
        var next = configuration
        if let index = next.launchers.firstIndex(where: { $0.id == launcher.id }) { next.launchers[index] = launcher }
        else { next.launchers.append(launcher) }
        return save(next)
    }

    @discardableResult
    func moveLaunchers(from source: IndexSet, to destination: Int) -> Bool {
        guard !readOnly, !source.isEmpty, source.allSatisfy(configuration.launchers.indices.contains),
              (0...configuration.launchers.count).contains(destination) else { return false }
        var next = configuration
        next.launchers.move(fromOffsets: source, toOffset: destination)
        guard next != configuration else { return true }
        return save(next)
    }
}
