import SwiftUI

private enum AppInformation {
    static var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.4.3"
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
    private let releases = [
        ReleaseNotes(
            version: "0.4.3",
            summary: "Restores the PrayerCal launcher icon and makes release history easier to review.",
            changes: [
                "Rebuilt the launcher icon from the original PrayerCal vector without cropping or distorting the mark.",
                "Added the latest four releases to What’s New."
            ]
        ),
        ReleaseNotes(
            version: "0.4.2",
            summary: "Makes Settings reliably visible when opened from the menu-bar popover.",
            changes: ["Settings now activates PrayerCal and opens in front of other applications."]
        ),
        ReleaseNotes(
            version: "0.4.1",
            summary: "Updates the macOS application icon treatment.",
            changes: ["Removed the unwanted outer inset from the launcher tile."]
        ),
        ReleaseNotes(
            version: "0.4.0",
            summary: "Makes prayer times the primary experience and brings the Mac app into the wider PrayerCal ecosystem.",
            changes: [
                "Added the next-prayer menu-bar status, daily schedule, and seven-day navigation.",
                "Added onboarding, current-location refresh, city search, and PrayerCal-compatible calculations.",
                "Added configurable reminders, full-screen alerts, and PrayerCal web calendar handoff.",
                "Added optional Hijri dates, events, birthdays, and Sparkle automatic updates."
            ]
        )
    ]

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 22) {
                Text("What’s New")
                    .font(.title2.weight(.bold))
                ForEach(Array(releases.enumerated()), id: \.element.version) { index, release in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(alignment: .firstTextBaseline) {
                            Text("PrayerCal \(release.version)")
                                .font(.headline)
                            if index == 0 {
                                Text("CURRENT")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(Color.accentColor)
                            }
                            Spacer()
                            Text("4 September 2026")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Text(release.summary)
                            .foregroundStyle(.secondary)
                        ForEach(release.changes, id: \.self) { item in
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(Color.accentColor)
                                    .padding(.top, 2)
                                Text(item)
                            }
                        }
                    }
                    .padding(16)
                    .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct ReleaseNotes {
    let version: String
    let summary: String
    let changes: [String]
}
