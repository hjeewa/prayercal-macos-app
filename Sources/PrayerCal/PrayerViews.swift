import SwiftUI

struct PrayerSummaryView: View {
    @Environment(PrayerStore.self) private var store
    @Environment(Clock.self) private var clock
    @State private var dayOffset = 0

    private var selectedDate: Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = store.timeZone
        return calendar.date(byAdding: .day, value: dayOffset, to: clock.now) ?? clock.now
    }

    var body: some View {
        if !store.settings.hasLocation {
            VStack(alignment: .leading, spacing: 6) {
                Label("Set your location for prayer times", systemImage: "location")
                    .font(.headline)
                SettingsLink { Text("Open Prayer Settings") }
            }
        } else {
            VStack(alignment: .leading, spacing: 9) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        if let next = store.nextPrayer(asOf: clock.now) {
                            Text("Next: \(next.name.displayName) · \(countdown(to: next.date))")
                                .font(.headline)
                        }
                        Text(store.settings.locationName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }

                HStack {
                    Button { dayOffset = max(0, dayOffset - 1) } label: {
                        Image(systemName: "chevron.left")
                    }
                    .disabled(dayOffset == 0)
                    Spacer()
                    Text(dayOffset == 0 ? "Today" : selectedDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.subheadline.weight(.medium))
                    Spacer()
                    Button { dayOffset = min(7, dayOffset + 1) } label: {
                        Image(systemName: "chevron.right")
                    }
                    .disabled(dayOffset == 7)
                }
                .buttonStyle(.borderless)

                ForEach(store.moments(on: selectedDate)) { moment in
                    HStack {
                        Text(moment.name.displayName)
                            .foregroundStyle(moment.name.isPrayer ? .primary : .secondary)
                        Spacer()
                        Text(PrayerFormatting.time(moment.date, in: store.timeZone))
                            .monospacedDigit()
                    }
                }
            }
        }
    }

    private func countdown(to date: Date) -> String {
        let seconds = max(0, Int(date.timeIntervalSince(clock.now)))
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        return hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
    }
}

struct PrayerSettingsView: View {
    @Environment(PrayerStore.self) private var store
    @State private var draft = PrayerSettings()
    @State private var locationService = LocationService()
    @State private var statusMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Prayer Times")
                    .font(.title2.weight(.semibold))

                GroupBox("Location") {
                    Form {
                        HStack {
                            TextField("Location name", text: $draft.locationName)
                            Button {
                                locationService.locate(for: store)
                            } label: {
                                if locationService.isLocating { ProgressView().controlSize(.small) }
                                else { Label("Use Current Location", systemImage: "location.fill") }
                            }
                            .disabled(locationService.isLocating)
                        }
                        HStack {
                            TextField("Latitude", value: $draft.latitude, format: .number.precision(.fractionLength(0...6)))
                            TextField("Longitude", value: $draft.longitude, format: .number.precision(.fractionLength(0...6)))
                            Button("Use Coordinates") {
                                draft.hasLocation = true
                                if draft.locationName == "Choose a location" { draft.locationName = "Custom location" }
                                store.update(draft)
                            }
                        }
                        TextField("Time zone", text: $draft.timeZoneIdentifier)
                        Text("Use an IANA name such as Europe/London or America/New_York for manually entered coordinates.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if let error = locationService.errorMessage {
                            Text(error).foregroundStyle(.red).font(.caption)
                        }
                    }
                    .padding(8)
                }

                GroupBox("Calculation") {
                    Form {
                        Picker("Calculation method", selection: $draft.calculationMethod) {
                            ForEach(PrayerCalculationMethod.allCases) { method in
                                Text(method.displayName).tag(method)
                            }
                        }
                        Picker("Asr method", selection: $draft.asrMethod) {
                            ForEach(AsrMethod.allCases) { method in
                                Text(method.displayName).tag(method)
                            }
                        }
                        Picker("High-latitude rule", selection: $draft.highLatitudeOption) {
                            ForEach(HighLatitudeOption.allCases) { option in
                                Text(option.displayName).tag(option)
                            }
                        }
                    }
                    .padding(8)
                }

                GroupBox("Calendar and reminders") {
                    VStack(spacing: 6) {
                        HStack {
                            Text("Prayer").frame(maxWidth: .infinity, alignment: .leading)
                            Text("Calendar").frame(width: 70)
                            Text("Duration").frame(width: 80)
                            Text("Notify").frame(width: 60)
                            Text("Before").frame(width: 80)
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)

                        ForEach(PrayerName.allCases) { prayer in
                            PrayerOptionRow(prayer: prayer, draft: $draft)
                        }

                        Divider()
                        Toggle("Full-screen prayer reminders", isOn: $draft.fullScreenRemindersEnabled)
                        Text("Shows a prominent alert over every display at the reminder time while PrayerCal is running.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        HStack {
                            Button("Schedule Reminders") { scheduleReminders() }
                                .disabled(!draft.hasLocation)
                            Button("Add Next Year to Calendar") { exportCalendar() }
                                .disabled(!draft.hasLocation)
                            Spacer()
                            if let statusMessage { Text(statusMessage).font(.caption).foregroundStyle(.secondary) }
                        }
                    }
                    .padding(8)
                }

                GroupBox("Optional Hijri features") {
                    Toggle("Show Hijri date, events, and birthdays", isOn: $draft.showHijriFeatures)
                        .padding(8)
                }
            }
        }
        .onAppear { draft = store.settings }
        .onChange(of: draft) { _, updated in store.update(updated) }
        .onChange(of: store.settings) { _, updated in draft = updated }
    }

    private func scheduleReminders() {
        store.update(draft)
        Task {
            do {
                let count = try await PrayerNotifications.reschedule(using: store)
                statusMessage = count == 0 ? "No reminders enabled or permission denied." : "Scheduled \(count) reminders."
            } catch {
                statusMessage = "Could not schedule reminders."
            }
        }
    }

    private func exportCalendar() {
        store.update(draft)
        do {
            _ = try PrayerCalendarExporter.export(using: store)
            statusMessage = "Opened calendar import."
        } catch {
            statusMessage = "Could not create calendar file."
        }
    }
}

private struct PrayerOptionRow: View {
    let prayer: PrayerName
    @Binding var draft: PrayerSettings

    private var option: Binding<PrayerOption> {
        Binding(
            get: { draft.option(for: prayer) },
            set: { draft.options[prayer.rawValue] = $0 }
        )
    }

    var body: some View {
        HStack {
            Text(prayer.displayName).frame(maxWidth: .infinity, alignment: .leading)
            Toggle("", isOn: option.includeInCalendar).labelsHidden().frame(width: 70)
            Stepper("\(option.wrappedValue.durationMinutes)m", value: option.durationMinutes, in: 1...60, step: 5)
                .frame(width: 80)
                .disabled(!option.wrappedValue.includeInCalendar || !prayer.isPrayer)
            Toggle("", isOn: option.reminderEnabled).labelsHidden().frame(width: 60)
                .disabled(!prayer.isPrayer)
            Stepper("\(option.wrappedValue.reminderMinutes)m", value: option.reminderMinutes, in: 0...60, step: 5)
                .frame(width: 80)
                .disabled(!option.wrappedValue.reminderEnabled || !prayer.isPrayer)
        }
    }
}
