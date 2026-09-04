import SwiftUI

struct MenuContentView: View {
    @Environment(PersonStore.self) private var store
    @Environment(Clock.self) private var clock

    private var today: HijriDate { HijriCalendar.hijriDate(from: clock.now) }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
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

            Divider()

            HStack {
                SettingsLink { Label("Settings", systemImage: "gear") }
                Spacer()
                Button("Quit") { NSApplication.shared.terminate(nil) }
            }
        }
        .padding(16)
        .frame(width: 360)
    }

    @ViewBuilder
    private var eventsSection: some View {
        let eventsToday = HijriEvents.on(today)
        if eventsToday.isEmpty {
            Text("Upcoming")
                .font(.headline)
            ForEach(HijriEvents.upcoming(after: today)) { event in
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
                Text("\(HijriCalendar.monthName(event.month)) · \(event.note)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct SettingsView: View {
    @Environment(PersonStore.self) private var store
    @State private var name = ""
    @State private var birthday = Calendar.current.date(byAdding: .year, value: -30, to: .now) ?? .now

    var body: some View {
        @Bindable var store = store
        VStack(alignment: .leading, spacing: 16) {
            Text("People")
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
        .padding(20)
        .frame(width: 540, height: 500)
    }

    private func addPerson() {
        store.add(name: name, birthday: birthday)
        name = ""
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
