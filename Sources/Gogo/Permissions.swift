import AppKit
import Combine
import CoreServices

enum AutomationAccess: Equatable, Sendable {
    case unknown, allowed, notRequested, denied, notRunning, notInstalled, failed(Int32)
    var key: String {
        switch self {
        case .unknown: return "permissions.unchecked"
        case .allowed: return "permissions.automation.allowed"
        case .notRequested: return "permissions.automation.notRequested"
        case .denied: return "permissions.automation.denied"
        case .notRunning: return "permissions.automation.notRunning"
        case .notInstalled: return "permissions.automation.notInstalled"
        case .failed: return "permissions.automation.failed"
        }
    }
}

protocol PermissionService: Sendable {
    func automation(request: Bool) async -> AutomationAccess
}

struct SystemPermissionService: PermissionService {
    func automation(request: Bool) async -> AutomationAccess {
        let bundleID = "com.googlecode.iterm2"
        let installed = await MainActor.run { NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) }
        guard let installed else { return .notInstalled }
        if request {
            // The public permission API requires a running target. Launching it
            // is disclosed in the UI; no script or shell command is executed.
            do { try await Self.startApplication(installed) }
            catch { return .failed(Int32(clamping: (error as NSError).code)) }
        }
        return await Task.detached(priority: .userInitiated) {
            let target = NSAppleEventDescriptor(bundleIdentifier: bundleID)
            let code = AEDeterminePermissionToAutomateTarget(target.aeDesc, typeWildCard, typeWildCard, request)
            switch code {
            case noErr: return AutomationAccess.allowed
            case OSStatus(errAEEventWouldRequireUserConsent): return .notRequested
            case OSStatus(errAEEventNotPermitted): return .denied
            case OSStatus(procNotFound): return .notRunning
            default: return .failed(code)
            }
        }.value
    }

    @MainActor private static func startApplication(_ url: URL) async throws {
        let options = NSWorkspace.OpenConfiguration()
        options.activates = false
        _ = try await NSWorkspace.shared.openApplication(at: url, configuration: options)
    }
}

@MainActor
final class PermissionsModel: ObservableObject {
    @Published private(set) var automation: AutomationAccess = .unknown
    @Published private(set) var activeRequest: String?
    @Published private(set) var refreshing = false
    private let service: any PermissionService
    let preview: Bool

    init(preview: Bool, service: any PermissionService = SystemPermissionService()) {
        self.preview = preview
        self.service = service
    }

    var busy: Bool { activeRequest != nil || refreshing }

    func refresh() async {
        guard !preview, !busy else { return }
        refreshing = true
        automation = .unknown
        defer { refreshing = false; activeRequest = nil }
        automation = await service.automation(request: false)
    }

    func requestAutomation() async {
        guard !preview, !busy else { return }
        activeRequest = "automation"
        automation = .unknown
        defer { activeRequest = nil }
        automation = await service.automation(request: true)
    }

}
