import AppKit
import Foundation
import Observation
import Sparkle

extension Notification.Name {
    static let showPrayerCalWhatsNew = Notification.Name("showPrayerCalWhatsNew")
}

@MainActor
@Observable
final class AppUpdater: NSObject, SPUStandardUserDriverDelegate {
    @ObservationIgnored
    private lazy var controller = SPUStandardUpdaterController(
        startingUpdater: true,
        updaterDelegate: nil,
        userDriverDelegate: self
    )

    var canCheckForUpdates: Bool { controller.updater.canCheckForUpdates }
    var automaticallyChecksForUpdates: Bool {
        get { controller.updater.automaticallyChecksForUpdates }
        set { controller.updater.automaticallyChecksForUpdates = newValue }
    }
    var lastUpdateCheckDate: Date? { controller.updater.lastUpdateCheckDate }

    func checkForUpdates() {
        controller.checkForUpdates(nil)
    }

    nonisolated func standardUserDriverShowVersionHistory(for _: SUAppcastItem) {
        Task { @MainActor in
            NSApplication.shared.activate(ignoringOtherApps: true)
            NSApplication.shared.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            try? await Task.sleep(for: .milliseconds(150))
            NotificationCenter.default.post(name: .showPrayerCalWhatsNew, object: nil)
            let settingsWindow = NSApplication.shared.windows.first {
                $0.title.localizedCaseInsensitiveContains("settings")
            }
            settingsWindow?.makeKeyAndOrderFront(nil)
            settingsWindow?.orderFrontRegardless()
        }
    }
}
