import AppKit
import Foundation

enum TapActionKind: String, CaseIterable, Codable, Identifiable {
    case launchApp
    case openWebsite
    case playSound
    case runShortcut

    var id: String { rawValue }
    var title: String {
        switch self {
        case .launchApp: "Launch app"
        case .openWebsite: "Open webpage"
        case .playSound: "Play sound"
        case .runShortcut: "Run Shortcut"
        }
    }
    var symbol: String {
        switch self {
        case .launchApp: "square.grid.2x2"
        case .openWebsite: "link"
        case .playSound: "music.note"
        case .runShortcut: "arrow.trianglehead.2.clockwise.rotate.90"
        }
    }
}

struct TapGestureAction: Codable, Identifiable, Equatable {
    var tapCount: Int
    var kind: TapActionKind
    var value: String
    var isEnabled: Bool

    var id: Int { tapCount }
    var gestureTitle: String {
        switch tapCount {
        case 1: "Single tap"
        case 2: "Double tap"
        default: "Triple tap"
        }
    }

    static let soundNames = ["Glass", "Ping", "Pop", "Purr", "Submarine", "Funk", "Hero"]

    static let defaults = [
        TapGestureAction(tapCount: 1, kind: .launchApp, value: "Google Chrome", isEnabled: false),
        TapGestureAction(tapCount: 2, kind: .openWebsite, value: "", isEnabled: false),
        TapGestureAction(tapCount: 3, kind: .playSound, value: "Glass", isEnabled: false)
    ]

    func perform() {
        guard isEnabled else { return }
        switch kind {
        case .openWebsite:
            BrowserOpener.openInChrome(value)
        case .launchApp:
            BrowserOpener.launchApp(value)
        case .playSound:
            if FileManager.default.fileExists(atPath: value) {
                NSSound(contentsOfFile: value, byReference: false)?.play()
            } else {
                NSSound(named: NSSound.Name(value))?.play()
            }
        case .runShortcut:
            BrowserOpener.runShortcut(value)
        }
    }
}

@MainActor
final class TapActionSettings: ObservableObject {
    @Published var selectedSection: AppSection = .tapActions
    @Published var actions: [TapGestureAction] {
        didSet { saveActions() }
    }
    @Published var sensitivity: Double {
        didSet { UserDefaults.standard.set(sensitivity, forKey: "tapSensitivityV4") }
    }
    @Published var sequenceWindow: Double {
        didSet { UserDefaults.standard.set(sequenceWindow, forKey: "tapSequenceWindowV1") }
    }

    private let actionsKey = "gestureActions"

    init() {
        if let data = UserDefaults.standard.data(forKey: actionsKey),
           let stored = try? JSONDecoder().decode([TapGestureAction].self, from: data),
           stored.count == 3 {
            let cleanedActions = stored.sorted { $0.tapCount < $1.tapCount }.map { action in
                var action = action
                if action.kind == .playSound && action.value == "Mourn" {
                    action.value = "Glass"
                }
                return action
            }
            actions = cleanedActions
            if stored.contains(where: { $0.kind == .playSound && $0.value == "Mourn" }) {
                if let cleanedData = try? JSONEncoder().encode(cleanedActions) {
                    UserDefaults.standard.set(cleanedData, forKey: actionsKey)
                }
            }
        } else {
            actions = TapGestureAction.defaults
        }
        let storedSensitivity = UserDefaults.standard.double(forKey: "tapSensitivityV4")
        sensitivity = storedSensitivity == 0 ? 0.16 : storedSensitivity
        let storedSequenceWindow = UserDefaults.standard.double(forKey: "tapSequenceWindowV1")
        sequenceWindow = storedSequenceWindow == 0 ? 0.72 : storedSequenceWindow
    }

    private func saveActions() {
        guard let data = try? JSONEncoder().encode(actions) else { return }
        UserDefaults.standard.set(data, forKey: actionsKey)
    }
}
