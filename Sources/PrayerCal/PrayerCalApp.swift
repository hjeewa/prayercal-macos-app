import AppKit
import SwiftUI
import Observation

@MainActor
@Observable
final class Clock {
    var now = Date.now
    private var timer: Timer?

    init() {
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.now = .now }
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let reminderCoordinator = FullScreenReminderCoordinator()
    private var onboardingWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.accessory)
        reminderCoordinator.start(using: PrayerStore.shared)
        guard !UserDefaults.standard.bool(forKey: "onboardingCompleted.v1") else { return }
        showOnboarding()
    }

    private func showOnboarding() {
        let view = OnboardingView(store: PrayerStore.shared) { [weak self] in
            UserDefaults.standard.set(true, forKey: "onboardingCompleted.v1")
            self?.onboardingWindow?.close()
            self?.onboardingWindow = nil
        }
        let controller = NSHostingController(rootView: view)
        let window = NSWindow(contentViewController: controller)
        window.title = "Welcome to PrayerCal"
        window.setContentSize(NSSize(width: 720, height: 570))
        window.styleMask = [.titled, .closable, .miniaturizable, .fullSizeContentView]
        window.titlebarAppearsTransparent = true
        window.center()
        window.isReleasedWhenClosed = false
        onboardingWindow = window
        NSApplication.shared.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }
}

@main
struct PrayerCalApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var store = PersonStore()
    @State private var eventStore = EventStore()
    @State private var prayerStore = PrayerStore.shared
    @State private var clock = Clock()
    private let updater = AppUpdater()

    var body: some Scene {
        MenuBarExtra {
            MenuContentView()
                .environment(store)
                .environment(eventStore)
                .environment(prayerStore)
                .environment(clock)
                .environment(updater)
        } label: {
            Group {
                if let next = prayerStore.nextPrayer(asOf: clock.now) {
                    Text("\(next.name.displayName) \(PrayerFormatting.time(next.date, in: prayerStore.timeZone))")
                } else {
                    Text("PrayerCal")
                }
            }
            .monospacedDigit()
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environment(store)
                .environment(eventStore)
                .environment(prayerStore)
                .environment(updater)
        }
    }
}
