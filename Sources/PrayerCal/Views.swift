import SwiftUI

struct MenuContentView: View {
    @Environment(PersonStore.self) private var store
    @Environment(EventStore.self) private var eventStore
    @Environment(PrayerStore.self) private var prayerStore
    @Environment(AppUpdater.self) private var updater
    @Environment(Clock.self) private var clock

    private var today: HijriDate { HijriCalendar.hijriDate(from: clock.now) }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            PrayerCalBrand(compact: true)
            Divider()
            PrayerSummaryView()

            if prayerStore.settings.showHijriFeatures {
                Divider()

                VStack(alignment: .leading, spacing: 3) {
                    Text(today.formatted)
                        .font(.title2.weight(.semibold))
                    Text(clock.now.formatted(date: .complete, time: .omitted))
                        .foregroundStyle(.secondary)
                }

                Divider()
                eventsSection

                if !store.people.isEmpty {
                    Divider()
                    peopleSection
                }
            }

            Divider()

            HStack {
                SettingsLink { Label("Settings", systemImage: "gear") }
                Button("Check for Updates…") { updater.checkForUpdates() }
                    .disabled(!updater.canCheckForUpdates)
                Spacer()
                Button("Quit") { NSApplication.shared.terminate(nil) }
            }
        }
        .padding(16)
        .frame(width: 390)
        .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder
    private var eventsSection: some View {
        let eventsToday = HijriEvents.on(today, in: eventStore.events)
        if eventsToday.isEmpty {
            Text("Upcoming")
                .font(.headline)
            ForEach(HijriEvents.upcoming(after: today, in: eventStore.events)) { event in
                EventRow(event: event)
            }
            Text("Dates may vary by local moon sighting.")
                .font(.caption)
                .foregroundStyle(.secondary)
        } else {
            Text("Today")
                .font(.headline)
            ForEach(eventsToday) { event in
                EventRow(event: event)
            }
        }
    }

    private var peopleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Birthdays")
                .font(.headline)
            ForEach(store.people) { person in
                let birthday = HijriCalendar.hijriDate(from: person.gregorianBirthday)
                HStack {
                    Text(person.name)
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("\(birthday.shortFormatted) (\(HijriCalendar.birthdayCountdownText(bornOn: person.gregorianBirthday, asOf: clock.now)))")
                        Text("\(HijriCalendar.hijriAge(bornOn: person.gregorianBirthday, asOf: clock.now)) Hijri years")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

private struct EventRow: View {
    let event: HijriEvent

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text("\(event.day)")
                .font(.headline.monospacedDigit())
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                Text(event.note.isEmpty ? HijriCalendar.monthName(event.month) : "\(HijriCalendar.monthName(event.month)) · \(event.note)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct SettingsView: View {
    @Environment(PrayerStore.self) private var prayerStore
    @State private var selection = SettingsSection.prayerTimes

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 5) {
                SettingsSidebarRow(
                    title: "Prayer Times",
                    systemImage: "clock",
                    isSelected: selection == .prayerTimes
                ) { selection = .prayerTimes }
                SettingsSidebarRow(
                    title: "Hijri Dates",
                    systemImage: "calendar",
                    isSelected: selection == .hijriDates
                ) { selection = .hijriDates }
                if prayerStore.settings.showHijriFeatures {
                    SettingsSidebarRow(
                        title: "Hijri Birthdays",
                        systemImage: "gift",
                        isSelected: selection == .hijriBirthdays
                    ) { selection = .hijriBirthdays }
                }

                Spacer()
                SettingsSidebarRow(
                    title: "About",
                    systemImage: "info.circle",
                    isSelected: selection == .about
                ) { selection = .about }
                SettingsSidebarRow(
                    title: "What’s New",
                    systemImage: "sparkles",
                    isSelected: selection == .whatsNew
                ) { selection = .whatsNew }
                Link(destination: URL(string: "https://app.prayercal.com/")!) {
                    Label("PrayerCal Web App", systemImage: "questionmark.circle")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 10)
                .padding(.bottom, 8)
            }
            .padding(10)
            .frame(width: 190)
            .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            settingsContent
                .padding(20)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 860, height: 680)
        .onChange(of: prayerStore.settings.showHijriFeatures) { _, enabled in
            if !enabled && selection == .hijriBirthdays { selection = .hijriDates }
        }
    }

    @ViewBuilder
    private var settingsContent: some View {
        switch selection {
        case .prayerTimes:
            PrayerSettingsView()
        case .hijriDates:
            CalendarSettingsView()
        case .hijriBirthdays:
            PeopleSettingsView()
        case .about:
            AboutSettingsView()
        case .whatsNew:
            WhatsNewSettingsView()
        }
    }
}

private enum SettingsSection {
    case prayerTimes, hijriDates, hijriBirthdays, about, whatsNew
}

private struct SettingsSidebarRow: View {
    let title: String
    let systemImage: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(isSelected ? Color.accentColor.opacity(0.22) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 7))
    }
}

private struct PeopleSettingsView: View {
    @Environment(PersonStore.self) private var store
    @State private var name = ""
    @State private var birthday = Calendar.current.date(byAdding: .year, value: -30, to: .now) ?? .now

    var body: some View {
        @Bindable var store = store
        VStack(alignment: .leading, spacing: 16) {
            Text("Hijri Birthdays")
                .font(.title2.weight(.semibold))

            GroupBox("Add a person") {
                Form {
                    TextField("Name", text: $name)
                    DatePicker("Gregorian birthday", selection: $birthday, in: ...Date.now, displayedComponents: .date)
                    LabeledContent("Hijri birthday", value: HijriCalendar.hijriDate(from: birthday).formatted)
                    Button("Add Person", action: addPerson)
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(8)
            }

            if store.people.isEmpty {
                ContentUnavailableView("No people yet", systemImage: "person.crop.circle.badge.plus", description: Text("Add someone above to track their Hijri birthday and age."))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(store.people) { person in
                        PersonRow(person: person)
                    }
                    .onDelete(perform: store.remove)
                }
            }
        }
    }

    private func addPerson() {
        store.add(name: name, birthday: birthday)
        name = ""
    }
}

private struct CalendarSettingsView: View {
    @Environment(EventStore.self) private var eventStore
    @Environment(PrayerStore.self) private var prayerStore
    @State private var title = ""
    @State private var month = 1
    @State private var day = 1
    @State private var note = ""
    @State private var showingResetConfirmation = false

    private var showHijriFeatures: Binding<Bool> {
        Binding(
            get: { prayerStore.settings.showHijriFeatures },
            set: { value in
                var settings = prayerStore.settings
                settings.showHijriFeatures = value
                prayerStore.update(settings)
            }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Significant Hijri Dates")
                    .font(.title2.weight(.semibold))
                Spacer()
                Button("Restore Defaults") { showingResetConfirmation = true }
            }

            GroupBox("Menu-bar display") {
                VStack(alignment: .leading, spacing: 5) {
                    Toggle("Show Hijri date, events, and birthdays", isOn: showHijriFeatures)
                    Text("This controls the optional Hijri sections in the PrayerCal popover.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(8)
            }

            GroupBox("Add a date") {
                Form {
                    TextField("Event name", text: $title)
                    HStack {
                        Picker("Month", selection: $month) {
                            ForEach(1...12, id: \.self) { value in
                                Text(HijriCalendar.monthName(value)).tag(value)
                            }
                        }
                        Stepper("Day \(day)", value: $day, in: 1...30)
                            .frame(width: 120)
                    }
                    TextField("Note (optional)", text: $note)
                    Button("Add Date", action: addEvent)
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(8)
            }

            List {
                ForEach(eventStore.events) { event in
                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Text(event.title)
                                .font(.headline)
                            Spacer()
                            Text("\(event.day) \(HijriCalendar.monthName(event.month))")
                                .foregroundStyle(.secondary)
                        }
                        if !event.note.isEmpty {
                            Text(event.note)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .onDelete(perform: eventStore.remove)
            }

            Text("Swipe left or press Delete to remove a date. Historical dates with differing reports are labelled in their notes.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .confirmationDialog("Restore the seeded calendar dates?", isPresented: $showingResetConfirmation) {
            Button("Restore Defaults", role: .destructive) { eventStore.resetToDefaults() }
        } message: {
            Text("This removes any dates you added manually.")
        }
    }

    private func addEvent() {
        eventStore.add(title: title, month: month, day: day, note: note)
        title = ""
        note = ""
    }
}

private struct PersonRow: View {
    @Environment(PersonStore.self) private var store
    @State var person: Person

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                TextField("Name", text: $person.name)
                    .textFieldStyle(.plain)
                    .font(.headline)
                Spacer()
                Text("Age \(HijriCalendar.hijriAge(bornOn: person.gregorianBirthday)) AH")
                    .foregroundStyle(.secondary)
            }
            HStack {
                DatePicker("", selection: $person.gregorianBirthday, in: ...Date.now, displayedComponents: .date)
                    .labelsHidden()
                Text("→ \(HijriCalendar.hijriDate(from: person.gregorianBirthday).formatted)")
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 5)
        .onChange(of: person) { _, updated in store.update(updated) }
    }
}
