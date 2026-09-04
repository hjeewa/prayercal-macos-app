import Foundation
import Observation
import Sparkle

@MainActor
@Observable
final class AppUpdater {
    private let controller = SPUStandardUpdaterController(
        startingUpdater: true,
        updaterDelegate: nil,
        userDriverDelegate: nil
    )

    var canCheckForUpdates: Bool { controller.updater.canCheckForUpdates }

    func checkForUpdates() {
        controller.checkForUpdates(nil)
    }
}
