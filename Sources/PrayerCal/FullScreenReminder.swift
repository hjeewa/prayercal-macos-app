import AppKit
import SwiftUI

@MainActor
final class FullScreenReminderCoordinator {
    private var timer: Timer?
    private var panels: [NSPanel] = []
    private var delivered = Set<String>()
    private weak var store: PrayerStore?

    func start(using store: PrayerStore) {
        self.store = store
        timer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.check() }
        }
        check()
    }

    private func check(now: Date = .now) {
        guard let store, store.settings.fullScreenRemindersEnabled else { return }
        for moment in store.moments(on: now) where moment.name.isPrayer {
            let option = store.settings.option(for: moment.name)
            guard option.reminderEnabled else { continue }
            let alertDate = moment.date.addingTimeInterval(TimeInterval(-option.reminderMinutes * 60))
            let key = "\(moment.name.rawValue)-\(Int(moment.date.timeIntervalSince1970))"
            guard now >= alertDate, now.timeIntervalSince(alertDate) < 120, !delivered.contains(key) else { continue }
            delivered.insert(key)
            show(moment: moment, location: store.settings.locationName)
            break
        }
    }

    private func show(moment: PrayerMoment, location: String) {
        dismiss()
        NSApplication.shared.activate(ignoringOtherApps: true)
        panels = NSScreen.screens.map { screen in
            let panel = NSPanel(contentRect: screen.frame, styleMask: .borderless, backing: .buffered, defer: false)
            panel.level = .screenSaver
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            panel.backgroundColor = NSColor(red: 0.12, green: 0.08, blue: 0.22, alpha: 1)
            panel.isOpaque = true
            panel.hidesOnDeactivate = false
            panel.contentView = NSHostingView(rootView: FullScreenPrayerAlert(
                moment: moment,
                location: location,
                dismiss: { [weak self] in self?.dismiss() },
                snooze: { [weak self] in self?.snooze(moment: moment, location: location) }
            ))
            panel.makeKeyAndOrderFront(nil)
            return panel
        }
    }

    private func dismiss() {
        panels.forEach { $0.close() }
        panels.removeAll()
    }

    private func snooze(moment: PrayerMoment, location: String) {
        dismiss()
        Timer.scheduledTimer(withTimeInterval: 300, repeats: false) { [weak self] _ in
            Task { @MainActor in self?.show(moment: moment, location: location) }
        }
    }
}

private struct FullScreenPrayerAlert: View {
    let moment: PrayerMoment
    let location: String
    let dismiss: () -> Void
    let snooze: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.12, green: 0.08, blue: 0.22), Color(red: 0.33, green: 0.20, blue: 0.55)], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            VStack(spacing: 26) {
                PrayerCalBrand(scale: 1.5)
                Text(moment.name.displayName)
                    .font(.system(size: 70, weight: .bold, design: .rounded))
                Text("It’s nearly time to pray")
                    .font(.system(size: 28, weight: .medium))
                Text(location)
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.7))
                HStack(spacing: 14) {
                    Button("Snooze 5 minutes", action: snooze)
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                    Button("I’m ready", action: dismiss)
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .tint(.white)
                        .foregroundStyle(.purple)
                }
            }
            .foregroundStyle(.white)
        }
    }
}
