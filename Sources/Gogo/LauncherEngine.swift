import AppKit

@MainActor
enum LauncherEngine {
    static func run(_ request: LaunchRequest, configuration: Configuration) async throws {
        guard let launcher = configuration.launchers.first(where: { $0.id == request.launcherID && $0.enabled }) else {
            throw GogoError.invalidRequest
        }
        guard let application = Applications.url(for: launcher) else { throw GogoError.missingApplication }
        let plan = try LaunchPlan.make(launcher: launcher, selection: request.selection, isDirectory: Applications.isDirectory)
        guard FileManager.default.fileExists(atPath: plan.directory.path), Applications.isDirectory(plan.directory) else {
            throw GogoError.invalidDirectory
        }
        let options = NSWorkspace.OpenConfiguration()
        options.activates = true
        switch launcher.method {
        case .documents:
            _ = try await NSWorkspace.shared.open(plan.documents, withApplicationAt: application, configuration: options)
        case .application:
            // LaunchServices only delivers argv at process creation.
            options.createsNewApplicationInstance = true
            options.arguments = plan.arguments
            _ = try await NSWorkspace.shared.openApplication(at: application, configuration: options)
        case .executable:
            guard FileManager.default.isExecutableFile(atPath: application.path), !Applications.isDirectory(application) else {
                throw GogoError.invalidProgram
            }
            let process = Process()
            process.executableURL = application
            process.arguments = plan.arguments
            process.currentDirectoryURL = plan.directory
            process.standardInput = FileHandle.nullDevice
            process.standardOutput = FileHandle.nullDevice
            process.standardError = FileHandle.nullDevice
            try process.run()
            // This launches a user-selected process; it may intentionally be long-lived.
        case .iTerm:
            // The script is constant. Paths arrive through argv and AppleScript's quoted form,
            // never through source interpolation. Automation permission is requested by macOS.
            let script = """
            on run argv
                tell application id "com.googlecode.iterm2"
                    activate
                    set newWindow to (create window with default profile)
                    tell current session of newWindow
                        write text ("cd -- " & quoted form of (item 1 of argv))
                    end tell
                end tell
            end run
            """
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
                process.arguments = ["-e", script, "--", plan.directory.path]
                process.standardOutput = FileHandle.nullDevice
                process.standardError = FileHandle.nullDevice
                process.terminationHandler = { task in
                    if task.terminationStatus == 0 { continuation.resume() }
                    else { continuation.resume(throwing: NSError(domain: "gogo.Automation", code: Int(task.terminationStatus), userInfo: [NSLocalizedDescriptionKey: Texts.get("automation.failed", language: configuration.language)])) }
                }
                do { try process.run() } catch { continuation.resume(throwing: error) }
            }
        }
    }
}
