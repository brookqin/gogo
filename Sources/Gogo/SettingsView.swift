import SwiftUI
import AppKit
import FinderSync
import UniformTypeIdentifiers

struct SettingsView: View {
    @ObservedObject var model: AppModel
    @State private var section = "launchers"
    @State private var draft: Launcher?
    @State private var original: Launcher?
    @State private var pending: Launcher?
    @State private var pendingPresetID: UUID?
    @State private var discard = false
    @State private var delete = false

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            Divider()
            VStack(spacing: 0) {
                if model.readOnly {
                    Label(model.t("configuration.readOnly"), systemImage: "exclamationmark.triangle")
                        .font(.callout).foregroundStyle(.orange).padding()
                }
                switch section {
                case "finder": finder
                case "general": general
                case "about": about
                default: launchers
                }
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .alert(model.t("error.title"), isPresented: Binding(get: { model.error != nil }, set: { if !$0 { model.error = nil } })) {
            Button(model.t("ok")) { model.error = nil }
        } message: { Text(model.error ?? "") }
        .confirmationDialog(model.t("discard.title"), isPresented: $discard) {
            Button(model.t("discard"), role: .destructive) {
                if let id = pendingPresetID { restorePreset(id) }
                else { setDraft(pending) }
                pending = nil; pendingPresetID = nil
            }
            Button(model.t("cancel"), role: .cancel) { pending = nil; pendingPresetID = nil }
        }
        .confirmationDialog(model.t("delete.title"), isPresented: $delete) {
            Button(model.t("delete"), role: .destructive) {
                if let id = draft?.id {
                    if model.update({ $0.launchers.removeAll { $0.id == id } }) {
                        draft = nil; original = nil
                    }
                }
            }
            Button(model.t("cancel"), role: .cancel) {}
        }
        .onAppear { if draft == nil { choose(model.configuration.launchers.first) } }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 9) {
                Image(nsImage: NSImage(named: "AppIcon") ?? NSImage()).resizable().frame(width: 34, height: 34)
                Text("gogo").font(.title3.weight(.semibold))
            }.padding(.horizontal, 10).padding(.top, 20).padding(.bottom, 20)
            ForEach([("launchers", "gearshape"), ("finder", "folder"), ("general", "slider.horizontal.3"), ("about", "info.circle")], id: \.0) { key, symbol in
                Button { section = key } label: {
                    Label(model.t(key), systemImage: symbol)
                        .font(.system(size: 14, weight: section == key ? .medium : .regular))
                        .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 12).padding(.vertical, 12)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(section == key ? Color.white : .primary)
                .background(section == key ? Color.accentColor : .clear, in: RoundedRectangle(cornerRadius: 8))
            }
            Spacer()
            Text(model.t("sidebar.note")).font(.caption).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true).padding(10)
        }
        .padding(.horizontal, 12).padding(.bottom, 12).frame(width: 170)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.45))
    }

    private var launchers: some View {
        HStack(alignment: .top, spacing: 0) {
            VStack(alignment: .leading, spacing: 16) {
                Text(model.t("launchers")).font(.title2.weight(.semibold))
                Text(model.t("launchers.description")).font(.callout).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                List(selection: Binding<UUID?>(get: { draft?.id }, set: { id in
                    if let launcher = model.configuration.launchers.first(where: { $0.id == id }) {
                        choose(launcher)
                    }
                })) {
                    ForEach(model.configuration.launchers) { launcher in
                        HStack(spacing: 12) {
                            AppIcon(launcher: launcher).frame(width: 30, height: 30)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(launcher.name).lineLimit(1)
                                if Applications.url(for: launcher) == nil {
                                    Text(model.t("application.notInstalled")).font(.caption).foregroundStyle(.secondary)
                                }
                            }
                            Spacer(minLength: 4)
                            Toggle(model.t("enabled"), isOn: Binding(get: {
                                model.configuration.launchers.first { $0.id == launcher.id }?.enabled ?? false
                            }, set: { enabled in
                                let saved = model.update { config in
                                    if let index = config.launchers.firstIndex(where: { $0.id == launcher.id }) {
                                        config.launchers[index].enabled = enabled
                                    }
                                }
                                if saved && draft?.id == launcher.id { draft?.enabled = enabled; original?.enabled = enabled }
                            })).labelsHidden().toggleStyle(.switch).controlSize(.small).disabled(model.readOnly)
                        }
                        .padding(.horizontal, 12).padding(.vertical, 12)
                        .contentShape(Rectangle())
                        .tag(launcher.id)
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .moveDisabled(model.readOnly)
                    }
                    .onMove { source, destination in
                        _ = model.moveLaunchers(from: source, to: destination)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 9))
                .clipShape(RoundedRectangle(cornerRadius: 9))
                .overlay(RoundedRectangle(cornerRadius: 9).stroke(.primary.opacity(0.08)))
                .accessibilityIdentifier("launcher.list")
                HStack(spacing: 0) {
                    Button {
                        choose(Launcher(name: model.t("custom.default"), method: .application))
                    } label: {
                        Label(model.t("launcher.add"), systemImage: "plus")
                            .padding(.horizontal, 10).frame(height: 28).contentShape(Rectangle())
                    }
                    .buttonStyle(.plain).accessibilityIdentifier("launcher.add")
                    Divider().frame(height: 16)
                    Menu {
                        ForEach(model.availablePresets) { preset in
                            Button(preset.name) {
                                if draft != original {
                                    pending = nil; pendingPresetID = preset.id; discard = true
                                } else { restorePreset(preset.id) }
                            }
                        }
                    } label: {
                        Image(systemName: "chevron.down").font(.system(size: 10, weight: .semibold))
                            .frame(width: 28, height: 28).contentShape(Rectangle())
                    }
                    .menuStyle(.borderlessButton).menuIndicator(.hidden)
                    .disabled(model.availablePresets.isEmpty)
                    .accessibilityLabel(model.t("launcher.restore"))
                    .accessibilityIdentifier("launcher.restore")
                    .help(model.t(model.availablePresets.isEmpty ? "launcher.restore.none" : "launcher.restore"))
                }
                .fixedSize()
                .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 6))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(.primary.opacity(0.15)))
                .disabled(model.readOnly)
                Text(model.t("launchers.hint")).font(.caption).foregroundStyle(.secondary)
                Spacer(minLength: 0)
            }.padding(24).frame(minWidth: 340, idealWidth: 400, maxWidth: .infinity)
            Divider()
            VStack {
                if let value = draft {
                    LauncherInspector(model: model, launcher: Binding(get: { draft ?? value }, set: { draft = $0 }),
                                      canDelete: model.configuration.launchers.contains { $0.id == value.id },
                                      save: {
                        if let draft, model.saveLauncher(draft) { original = draft }
                    }, cancel: { draft = original }, remove: { delete = true })
                } else {
                    Spacer()
                    Image(systemName: "slider.horizontal.3").font(.system(size: 36)).foregroundStyle(.tertiary)
                    Text(model.t("launcher.select")).foregroundStyle(.secondary)
                    Spacer()
                }
            }.frame(minWidth: 340, idealWidth: 400, maxWidth: .infinity)
        }
    }

    private func choose(_ value: Launcher?) {
        guard value?.id != draft?.id else { return }
        pendingPresetID = nil
        if draft != original { pending = value; discard = true }
        else { setDraft(value) }
    }
    private func restorePreset(_ id: UUID) {
        if let preset = model.restorePreset(id: id) { setDraft(preset) }
    }
    private func setDraft(_ value: Launcher?) {
        draft = value
        original = model.configuration.launchers.first { $0.id == value?.id }
    }
    private var finder: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Finder").font(.title2.weight(.semibold))
                VStack(alignment: .leading, spacing: 12) {
                    Label(model.t(model.extensionEnabled ? "extension.enabled" : "extension.disabled"),
                          systemImage: model.extensionEnabled ? "checkmark.circle.fill" : "exclamationmark.circle")
                        .foregroundStyle(model.extensionEnabled ? .green : .orange)
                    Text(model.t("extension.instructions")).foregroundStyle(.secondary)
                    HStack {
                        Button(model.t("extension.manage")) { FIFinderSyncController.showExtensionManagementInterface() }
                        Button(model.t("refresh")) { model.refreshExtension() }
                    }
                }
                Divider()
                Toggle(model.t("finder.context"), isOn: configBinding(\.showContextMenu))
                Toggle(model.t("finder.toolbar"), isOn: configBinding(\.showToolbarLaunchers))
                Text(model.t("finder.toolbar.help")).font(.callout).foregroundStyle(.secondary)
                Divider()
                Text(model.t("finder.behavior.title")).font(.headline)
                Text(model.t("finder.behavior")).foregroundStyle(.secondary).lineSpacing(6)
                Spacer()
            }.padding(32).frame(maxWidth: 660, alignment: .leading)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }

    private func configBinding(_ path: WritableKeyPath<Configuration, Bool>) -> Binding<Bool> {
        Binding(get: { model.configuration[keyPath: path] }, set: { value in model.update { $0[keyPath: path] = value } })
    }

    private var general: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text(model.t("general")).font(.title2.weight(.semibold))
            HStack {
                Text(model.t("language"))
                Spacer()
                Picker(model.t("language"), selection: Binding(get: { model.configuration.language }, set: { language in model.update { $0.language = language } })) {
                    Text(model.t("language.system")).tag(AppLanguage.system)
                    Text("简体中文").tag(AppLanguage.zhHans)
                    Text("English").tag(AppLanguage.en)
                }.labelsHidden().frame(width: 220)
            }
            Text(model.t("language.hint")).font(.callout).foregroundStyle(.secondary)
            Spacer()
        }.padding(32).frame(maxWidth: 660, alignment: .leading).frame(maxWidth: .infinity, alignment: .leading)
    }

    private var about: some View {
        VStack(spacing: 18) {
            Spacer(minLength: 20)
            Image(nsImage: NSImage(named: "AppIcon") ?? NSImage()).resizable().frame(width: 130, height: 130)
            Text("gogo").font(.system(size: 32, weight: .bold))
            Text(model.t("about.description")).font(.title3)
            Text(model.t("about.status")).foregroundStyle(.secondary)
            Link(model.t("about.github"), destination: URL(string: "https://github.com/brookqin/gogo")!)
            Spacer()
        }.frame(maxWidth: .infinity).padding(32)
    }
}

private struct AppIcon: View {
    let launcher: Launcher
    var body: some View {
        if let url = Applications.url(for: launcher) {
            Image(nsImage: NSWorkspace.shared.icon(forFile: url.path)).resizable().scaledToFit()
        } else {
            Image(systemName: launcher.builtIn ? "app.dashed" : "wrench.and.screwdriver")
                .font(.system(size: 24)).foregroundStyle(.secondary)
        }
    }
}

private struct LauncherInspector: View {
    @ObservedObject var model: AppModel
    @Binding var launcher: Launcher
    let canDelete: Bool
    let save: () -> Void
    let cancel: () -> Void
    let remove: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 17) {
                Text(model.t("launcher.edit")).font(.headline)
                field("name") { TextField(model.t("name"), text: $launcher.name) }
                field("program") {
                    HStack {
                        TextField(model.t("program.placeholder"), text: $launcher.program)
                        Button(model.t("choose")) { chooseProgram() }
                    }
                    if launcher.program.isEmpty, let url = Applications.url(for: launcher) {
                        Text(url.path).font(.caption).foregroundStyle(.secondary).lineLimit(2).textSelection(.enabled)
                    }
                }
                field("method") {
                    Picker(model.t("method"), selection: $launcher.method) {
                        Text(model.t("method.documents")).tag(LaunchMethod.documents)
                        Text(model.t("method.application")).tag(LaunchMethod.application)
                        Text(model.t("method.executable")).tag(LaunchMethod.executable)
                        if launcher.builtIn && launcher.bundleID == "com.googlecode.iterm2" {
                            Text(model.t("method.iTerm")).tag(LaunchMethod.iTerm)
                        }
                    }.labelsHidden()
                }
                if launcher.method == .application || launcher.method == .executable {
                    field("arguments") {
                        TextEditor(text: Binding(get: { launcher.arguments.joined(separator: "\n") }, set: { text in
                            launcher.arguments = text.isEmpty ? [] : text.components(separatedBy: "\n")
                        }))
                        .font(.system(.body, design: .monospaced)).frame(height: 90)
                        .padding(5).background(Color(nsColor: .textBackgroundColor), in: RoundedRectangle(cornerRadius: 5))
                        .overlay(RoundedRectangle(cornerRadius: 5).stroke(.primary.opacity(0.15)))
                        Text(model.t("arguments.help")).font(.caption).foregroundStyle(.secondary)
                        Text(model.t("arguments.tokens")).font(.caption).foregroundStyle(.secondary)
                    }
                }
                if launcher.method == .executable {
                    field("directory") { TextField("{directory}", text: $launcher.workingDirectory) }
                }
                if launcher.method == .documents {
                    Toggle(model.t("documents.directories"), isOn: $launcher.directoriesOnly).font(.callout)
                }
                Text(model.t("method.help." + launcher.method.rawValue)).font(.caption).foregroundStyle(.secondary)
                field("scope") {
                    HStack(spacing: 20) {
                        Toggle(model.t("files"), isOn: $launcher.acceptsFiles)
                        Toggle(model.t("folders"), isOn: $launcher.acceptsFolders)
                    }.toggleStyle(.checkbox)
                    Text(model.t("scope.help"))
                        .font(.caption).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                HStack {
                    if canDelete {
                        Button(role: .destructive, action: remove) { Image(systemName: "trash") }.help(model.t("delete"))
                    }
                    Spacer()
                    Button(model.t("cancel"), action: cancel)
                    Button(model.t("save"), action: save).buttonStyle(.borderedProminent)
                }.padding(.top, 8)
            }.textFieldStyle(.roundedBorder).padding(24)
        }
        .disabled(model.readOnly)
        .onChange(of: launcher.method) { _, new in
            if new == .documents { launcher.arguments = ["{paths}"] }
        }
    }
    private func field<Content: View>(_ key: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(model.t(key)).font(.callout.weight(.medium))
            content()
        }
    }
    private func chooseProgram() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.treatsFilePackagesAsDirectories = false
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.prompt = model.t("choose")
        if panel.runModal() == .OK, let url = panel.url {
            launcher.program = url.path
            if url.pathExtension != "app" { launcher.method = .executable }
            else if launcher.method == .executable { launcher.method = .application }
        }
    }
}
