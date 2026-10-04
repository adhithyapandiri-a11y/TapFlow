import Foundation
import ServiceManagement

@MainActor
final class LoginItemController: ObservableObject {
    @Published private(set) var isEnabled = false
    @Published private(set) var statusMessage: String?

    private let service = SMAppService.mainApp

    init() {
        refreshStatus()
    }

    func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                try service.register()
            } else {
                try service.unregister()
            }
            statusMessage = nil
        } catch {
            statusMessage = error.localizedDescription
        }
        refreshStatus()
    }

    private func refreshStatus() {
        switch service.status {
        case .enabled:
            isEnabled = true
            if statusMessage == nil { statusMessage = "TapFlow opens when you log in." }
        case .requiresApproval:
            isEnabled = true
            statusMessage = "Allow TapFlow in System Settings > General > Login Items."
        case .notRegistered, .notFound:
            isEnabled = false
            if statusMessage == "TapFlow opens when you log in." || statusMessage?.hasPrefix("Allow TapFlow") == true {
                statusMessage = nil
            }
        @unknown default:
            isEnabled = false
            statusMessage = "Login item status is unavailable."
        }
    }
}
