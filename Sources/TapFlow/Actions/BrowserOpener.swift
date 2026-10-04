import AppKit

enum BrowserOpener {
    static func openInChrome(_ address: String) {
        let normalized = address.hasPrefix("http") ? address : "https://\(address)"
        guard let url = URL(string: normalized) else { return }

        if let chrome = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.google.Chrome") {
            NSWorkspace.shared.open([url], withApplicationAt: chrome, configuration: NSWorkspace.OpenConfiguration())
        } else {
            NSWorkspace.shared.open(url)
        }
    }

    static func launchApp(_ app: String) {
        if app == "Google Chrome",
           let chrome = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.google.Chrome") {
            NSWorkspace.shared.openApplication(at: chrome, configuration: .init())
            return
        }
        if FileManager.default.fileExists(atPath: app) {
            NSWorkspace.shared.openApplication(at: URL(fileURLWithPath: app), configuration: .init())
        } else if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: app) {
            NSWorkspace.shared.openApplication(at: appURL, configuration: .init())
        }
    }

    static func runShortcut(_ name: String) {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/shortcuts")
            process.arguments = ["run", name]
            process.standardOutput = FileHandle.nullDevice
            process.standardError = FileHandle.nullDevice
            do {
                try process.run()
                process.waitUntilExit()
            } catch {
                NSLog("TapFlow could not run shortcut: %@", error.localizedDescription)
            }
        }
    }
}
