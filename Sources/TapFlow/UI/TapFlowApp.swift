import AppKit
import SwiftUI
import UniformTypeIdentifiers

@main
struct TapFlowApp: App {
    @StateObject private var detector = TapDetector()
    @StateObject private var settings = TapActionSettings()

    var body: some Scene {
        WindowGroup("TapFlow", id: "main") {
            TapFlowWindow(detector: detector, settings: settings)
                .frame(minWidth: 820, minHeight: 620)
                .onAppear {
                    syncActions()
                    detector.sequenceWindow = settings.sequenceWindow
                    if !detector.isRunning { detector.start(sensitivity: settings.sensitivity) }
                }
                .onChange(of: settings.actions) { _, _ in syncActions() }
                .onChange(of: settings.sensitivity) { _, value in detector.sensitivity = value }
                .onChange(of: settings.sequenceWindow) { _, value in detector.sequenceWindow = value }
        }
        .defaultSize(width: 940, height: 720)

        MenuBarExtra {
            MenuBarPanel(detector: detector, settings: settings)
        } label: {
            Image(systemName: detector.isRunning ? "hand.tap.fill" : "hand.tap")
        }
        .menuBarExtraStyle(.window)
    }

    private func syncActions() {
        detector.configure(actions: Dictionary(uniqueKeysWithValues: settings.actions.filter(\.isEnabled).map { action in
            (action.tapCount, { action.perform() })
        }))
    }
}

private struct MenuBarPanel: View {
    @ObservedObject var detector: TapDetector
    @ObservedObject var settings: TapActionSettings
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 9) {
                Image(systemName: detector.isRunning ? "checkmark.circle.fill" : "exclamationmark.circle")
                    .foregroundStyle(detector.isRunning ? .green : .secondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text("TapFlow").font(.headline)
                    Text(detector.statusText).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                }
            }
            Divider()
            Button("Open TapFlow Settings") { openWindow(id: "main") }
            Toggle("Listen for taps", isOn: Binding(
                get: { detector.isRunning },
                set: { $0 ? detector.start(sensitivity: settings.sensitivity) : detector.stop() }
            ))
            Button("Quit TapFlow") { NSApplication.shared.terminate(nil) }
        }
        .padding(14)
        .frame(width: 270)
        .onAppear(perform: startIfNeeded)
    }

    private func startIfNeeded() {
        if !detector.isRunning { detector.start(sensitivity: settings.sensitivity) }
    }
}

private struct TapFlowWindow: View {
    @ObservedObject var detector: TapDetector
    @ObservedObject var settings: TapActionSettings

    var body: some View {
        NavigationSplitView {
            List(AppSection.allCases, selection: $settings.selectedSection) { section in
                Label(section.title, systemImage: section.symbol)
                    .tag(section)
            }
            .listStyle(.sidebar)
            .navigationTitle("TapFlow")
            .frame(minWidth: 180)
        } detail: {
            Group {
                switch settings.selectedSection {
                case .tapActions:
                    TapActionsView(detector: detector, settings: settings)
                case .settings:
                    DetectionSettingsView(detector: detector, settings: settings)
                case .about:
                    AboutView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .navigationTitle(settings.selectedSection.title)
        }
        .navigationSplitViewStyle(.balanced)
    }
}

enum AppSection: String, CaseIterable, Identifiable {
    case tapActions
    case settings
    case about

    var id: String { rawValue }
    var title: String {
        switch self {
        case .tapActions: "Tap actions"
        case .settings: "Settings"
        case .about: "About"
        }
    }
    var symbol: String {
        switch self {
        case .tapActions: "hand.tap"
        case .settings: "gearshape"
        case .about: "info.circle"
        }
    }
}

private struct TapActionsView: View {
    @ObservedObject var detector: TapDetector
    @ObservedObject var settings: TapActionSettings

    var body: some View {
        Form {
            Section {
                ForEach(settings.actions.indices, id: \.self) { index in
                    TapActionRow(action: $settings.actions[index])
                }
            } header: {
                Text("Tap actions")
            } footer: {
                Text("Choose an action for each gesture. Disabled gestures are ignored.")
            }
            Section("Tap sensor") {
                LabeledContent("Status") {
                    Label(detector.isRunning ? "Listening" : "Unavailable", systemImage: detector.isRunning ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                        .foregroundStyle(detector.isRunning ? .green : .secondary)
                }
                LabeledContent("Activity", value: detector.statusText)
                    .lineLimit(1)
                VStack(alignment: .leading, spacing: 6) {
                    LabeledContent("Sensitivity", value: settings.sensitivity.formatted(.number.precision(.fractionLength(2))))
                    Slider(value: $settings.sensitivity, in: 0.06...0.6, step: 0.01)
                    HStack {
                        Text("Gentler taps")
                        Spacer()
                        Text("Firmer taps")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                HStack {
                    Button(detector.isCalibrating ? "Calibrating…" : "Calibrate") {
                        detector.calibrate { settings.sensitivity = $0 }
                    }
                    .disabled(!detector.isRunning || detector.isCalibrating)
                    Spacer()
                    Button("Test double tap") {
                        settings.actions.first(where: { $0.tapCount == 2 })?.perform()
                    }
                    .disabled(!(settings.actions.first(where: { $0.tapCount == 2 })?.isEnabled ?? false))
                }
            }
        }
        .formStyle(.grouped)
        .padding(.horizontal, 18)
        .frame(maxWidth: 820, alignment: .topLeading)
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

private struct TapActionRow: View {
    @Binding var action: TapGestureAction

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(action.gestureTitle).font(.headline)
                Spacer()
                Toggle("Enable \(action.gestureTitle)", isOn: $action.isEnabled)
                    .labelsHidden()
                    .help(action.isEnabled ? "Disable this gesture" : "Enable this gesture")
            }
            HStack(spacing: 10) {
                Picker("Action", selection: $action.kind) {
                    ForEach(TapActionKind.allCases) { kind in
                        Label(kind.title, systemImage: kind.symbol).tag(kind)
                    }
                }
                .labelsHidden()
                .accessibilityLabel("Action for \(action.gestureTitle)")
                .frame(width: 175)
                actionEditor.frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var actionEditor: some View {
        switch action.kind {
        case .openWebsite:
            TextField("URL", text: $action.value)
                .textFieldStyle(.roundedBorder)
                .accessibilityLabel("Website address for \(action.gestureTitle)")
        case .launchApp:
            HStack(spacing: 7) {
                TextField("Choose an application", text: $action.value)
                Button("Choose…", action: chooseApp)
                    .help("Choose an app")
            }
        case .playSound:
            soundPicker
        case .runShortcut:
            TextField("Shortcut name", text: $action.value)
                .textFieldStyle(.roundedBorder)
                .accessibilityLabel("Shortcut name for \(action.gestureTitle)")
        }
    }

    private static let chooseSoundOption = "__choose_sound_file__"

    private var soundPicker: some View {
        Picker("Sound", selection: Binding(
            get: { action.value },
            set: { selection in
                if selection == Self.chooseSoundOption {
                    chooseSound()
                } else {
                    action.value = selection
                }
            }
        )) {
            ForEach(TapGestureAction.soundNames, id: \.self) { name in
                Text(name).tag(name)
            }
            Divider()
            if !TapGestureAction.soundNames.contains(action.value) {
                Text(URL(fileURLWithPath: action.value).lastPathComponent)
                    .tag(action.value)
            }
            Text("Choose Sound File…")
                .tag(Self.chooseSoundOption)
        }
        .labelsHidden()
        .accessibilityLabel("Sound for \(action.gestureTitle)")
    }

    private func chooseApp() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.application]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.prompt = "Choose App"
        if panel.runModal() == .OK, let url = panel.url {
            action.value = url.path
        }
    }

    private func chooseSound() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.audio]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.prompt = "Choose Sound"
        if panel.runModal() == .OK, let url = panel.url {
            action.value = url.path
        }
    }
}

private struct DetectionSettingsView: View {
    @ObservedObject var detector: TapDetector
    @ObservedObject var settings: TapActionSettings

    var body: some View {
        Form {
            Section("Tap detection") {
                Toggle("Listen for taps", isOn: Binding(
                    get: { detector.isRunning },
                    set: { $0 ? detector.start(sensitivity: settings.sensitivity) : detector.stop() }
                ))
                VStack(alignment: .leading, spacing: 7) {
                    HStack {
                        Text("Tap sensitivity")
                        Spacer()
                        Text(settings.sensitivity, format: .number.precision(.fractionLength(2)))
                            .monospacedDigit().foregroundStyle(.secondary)
                    }
                    Slider(value: $settings.sensitivity, in: 0.06...0.6, step: 0.01)
                }
                Button(detector.isCalibrating ? "Calibrating…" : "Calibrate while Mac is still") {
                    detector.calibrate { settings.sensitivity = $0 }
                }
                .disabled(!detector.isRunning || detector.isCalibrating)
                LabeledContent("Status", value: detector.statusText)
            }
            Section("Gesture timing") {
                VStack(alignment: .leading, spacing: 6) {
                    LabeledContent("Tap sequence delay", value: "\(settings.sequenceWindow.formatted(.number.precision(.fractionLength(2)))) seconds")
                    Slider(value: $settings.sequenceWindow, in: 0.25...1.5, step: 0.05)
                    HStack {
                        Text("Faster recognition")
                        Spacer()
                        Text("More time between taps")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                Text("TapFlow waits briefly after your final tap to distinguish a single, double, or triple tap.")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding(22)
        .frame(maxWidth: 700, alignment: .topLeading)
    }
}

private struct AboutView: View {
    var body: some View {
        Form {
            Section("TapFlow") {
                LabeledContent("Version", value: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.1.0")
                Text("Turn gentle taps on your MacBook into useful actions.")
                    .foregroundStyle(.secondary)
            }
            Section("Developer") {
                LabeledContent("Name", value: "Adhithya Pandiri")
                LabeledContent("Email") {
                    Link("adhithyapandiri@gmail.com", destination: URL(string: "mailto:adhithyapandiri@gmail.com")!)
                }
            }
            Section("Gestures") {
                LabeledContent("Available", value: "Single, double, and triple tap")
            }
        }
        .formStyle(.grouped)
        .padding(.horizontal, 18)
        .frame(maxWidth: 700, alignment: .topLeading)
        .frame(maxWidth: .infinity, alignment: .center)
    }
}
