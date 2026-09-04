import SwiftUI

private enum AppInformation {
    static var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.4.0"
    }

    static var build: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "Development"
    }
}

struct AboutSettingsView: View {
    @Environment(AppUpdater.self) private var updater

    private var automaticChecks: Binding<Bool> {
        Binding(
            get: { updater.automaticallyChecksForUpdates },
            set: { updater.automaticallyChecksForUpdates = $0 }
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                VStack(spacing: 10) {
                    PrayerCalBrand()
                        .scaleEffect(1.35)
                        .padding(.bottom, 8)
                    Text("Version \(AppInformation.version) · Build \(AppInformation.build)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Prayer times, reminders, and live calendar planning—right from your Mac menu bar.")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                    HStack {
                        Link("Open PrayerCal Web App", destination: URL(string: "https://app.prayercal.com/")!)
                            .buttonStyle(.bordered)
                        Link("View on GitHub", destination: URL(string: "https://github.com/hjeewa/prayercal-macos-app")!)
                            .buttonStyle(.bordered)
                    }
                    Text("© 2026 PrayerCal")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(30)
                .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12))

                Text("Updates")
                    .font(.headline)
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Check for updates automatically", isOn: automaticChecks)
                    Divider()
                    HStack {
                        Button("Check Now") { updater.checkForUpdates() }
                            .disabled(!updater.canCheckForUpdates)
                        Spacer()
                        if let date = updater.lastUpdateCheckDate {
                            Text("Last checked \(date.formatted(date: .abbreviated, time: .shortened))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(14)
                .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}

struct WhatsNewSettingsView: View {
    private let added = [
        "Next-prayer menu-bar status and a branded schedule popover with seven-day navigation.",
        "Current-location refresh and searchable city selection for travel.",
        "PrayerCal-compatible calculation methods and Standard or Hanafi Asr times.",
        "Per-prayer reminders, durations, and optional full-screen alerts with snooze.",
        "A pre-filled handoff to the PrayerCal web app for live Webcal subscriptions.",
        "Optional Hijri dates, significant Sunni events, and Hijri birthday tracking.",
        "Signed Sparkle update feeds and universal Apple Silicon and Intel builds."
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("What’s new in this version")
                    .font(.title2.weight(.bold))
                Text("v\(AppInformation.version) · 2026-09-04")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("SUMMARY")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                    .tracking(1.3)
                Text("PrayerCal 0.4 makes prayer times the primary experience and brings the Mac app into the wider PrayerCal ecosystem.")
                Text("ADDED")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                    .tracking(1.3)
                    .padding(.top, 8)
                ForEach(added, id: \.self) { item in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(Color.accentColor)
                            .padding(.top, 2)
                        Text(item)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
