import SwiftUI
import AppKit
import FinderSync

struct PermissionGuide: View {
    @ObservedObject var model: AppModel
    @ObservedObject var permissions: PermissionsModel

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Label(model.t("permissions.title"), systemImage: "lock.shield").font(.headline)
                Spacer()
                Button(model.t("refresh")) { refresh() }
                    .disabled(permissions.busy || model.preview)
            }
            Text(model.t("permissions.description")).font(.callout).foregroundStyle(.secondary)
            if model.preview {
                Text(model.t("permissions.preview")).font(.callout).foregroundStyle(.secondary)
            }
            GroupBox {
                HStack(alignment: .top, spacing: 16) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(model.t("permissions.finder.title")).fontWeight(.medium)
                        Text(model.t("permissions.finder.description")).foregroundStyle(.secondary)
                        Label(model.t(model.extensionEnabled ? "extension.enabled" : "extension.disabled"),
                              systemImage: model.extensionEnabled ? "checkmark.circle" : "circle")
                            .foregroundStyle(model.extensionEnabled ? Color.green : .secondary)
                    }.frame(maxWidth: .infinity, alignment: .leading)
                    Button(model.t("extension.manage")) { FIFinderSyncController.showExtensionManagementInterface() }
                        .disabled(model.preview)
                }.padding(10)
            }
            GroupBox {
                HStack(alignment: .top, spacing: 16) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(model.t("permissions.files.title")).fontWeight(.medium)
                        Text(model.t("permissions.files.description")).foregroundStyle(.secondary)
                    }.frame(maxWidth: .infinity, alignment: .leading)
                    Button(model.t("permissions.files.settings")) { openPrivacy("Privacy_FilesAndFolders") }
                        .disabled(model.preview)
                        .accessibilityIdentifier("permissions.files.settings")
                }.padding(10)
            }
            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top, spacing: 16) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(model.t("permissions.automation.title")).fontWeight(.medium)
                            Text(model.t("permissions.automation.description")).foregroundStyle(.secondary)
                        }.frame(maxWidth: .infinity, alignment: .leading)
                        Button(model.t("permissions.authorize")) { Task { await permissions.requestAutomation() } }
                            .disabled(model.preview || permissions.busy || permissions.automation == .notInstalled || permissions.automation == .allowed)
                            .accessibilityIdentifier("permissions.automation.request")
                    }
                    status(model.t(permissions.automation.key), success: permissions.automation == .allowed,
                           waiting: permissions.activeRequest == "automation")
                    Button(model.t("permissions.automation.settings")) { openPrivacy("Privacy_Automation") }
                        .disabled(model.preview)
                }.padding(10)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
        .task { model.refreshExtension(); await permissions.refresh() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in refresh() }
    }

    private func status(_ message: String, success: Bool, waiting: Bool) -> some View {
        HStack(spacing: 6) {
            if waiting { ProgressView().controlSize(.small) }
            else { Image(systemName: success ? "checkmark.circle" : "info.circle") }
            Text(waiting ? model.t("permissions.waiting") : message)
        }.font(.caption).foregroundStyle(success && !waiting ? Color.green : .secondary)
    }

    private func refresh() {
        model.refreshExtension()
        Task { await permissions.refresh() }
    }

    private func openPrivacy(_ anchor: String) {
        // System Settings anchors vary by OS; always provide the manual route in UI.
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?" + anchor)!
        if !NSWorkspace.shared.open(url) {
            model.error = model.t("permissions.settings.failed")
        }
    }
}
