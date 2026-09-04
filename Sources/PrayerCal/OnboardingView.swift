import SwiftUI

struct OnboardingView: View {
    let store: PrayerStore
    let onComplete: () -> Void
    @State private var step = 0
    @State private var draft: PrayerSettings
    @State private var locationService = LocationService()
    @State private var enableNotifications = true
    @State private var reminderMinutes = 10
    @State private var cityQuery = ""

    init(store: PrayerStore, onComplete: @escaping () -> Void) {
        self.store = store
        self.onComplete = onComplete
        _draft = State(initialValue: store.settings)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                ForEach(0..<4, id: \.self) { index in
                    Capsule()
                        .fill(index <= step ? Color.purple : Color.secondary.opacity(0.2))
                        .frame(width: index == step ? 42 : 18, height: 5)
                }
            }
            .padding(.top, 24)

            Group {
                switch step {
                case 0: welcome
                case 1: location
                case 2: calculation
                default: preferences
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(40)

            Divider()
            HStack {
                if step > 0 { Button("Back") { step -= 1 } }
                Spacer()
                Button(step == 3 ? "Start Using PrayerCal" : "Continue") {
                    if step == 3 { finish() } else { step += 1 }
                }
                .buttonStyle(.borderedProminent)
                .tint(.purple)
                .disabled(step == 1 && !draft.hasLocation)
            }
            .padding(20)
        }
        .onChange(of: store.settings) { _, updated in draft = updated }
    }

    private var welcome: some View {
        VStack(spacing: 24) {
            PrayerCalBrand(scale: 1.25)
            Text("Never lose track of the next prayer")
                .font(.largeTitle.weight(.bold))
                .multilineTextAlignment(.center)
            Text("PrayerCal keeps accurate local prayer times in your menu bar, reminds you before each prayer, and can add your schedule to Calendar.")
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 540)
        }
    }

    private var location: some View {
        VStack(alignment: .leading, spacing: 18) {
            Label("Where are you?", systemImage: "location.circle.fill")
                .font(.largeTitle.weight(.bold))
            Text("Your location stays on this Mac and is used only to calculate prayer times.")
                .foregroundStyle(.secondary)
            Button {
                locationService.locate(for: store)
            } label: {
                HStack {
                    if locationService.isLocating { ProgressView().controlSize(.small) }
                    Label("Use My Current Location", systemImage: "location.fill")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(.purple)

            Text("Or choose a city")
                .font(.headline)
            HStack {
                TextField("City or town, e.g. Bradford, United Kingdom", text: $cityQuery)
                    .onSubmit { locationService.selectCity(cityQuery, for: store) }
                Button("Find City") {
                    locationService.selectCity(cityQuery, for: store)
                }
                .disabled(cityQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || locationService.isLocating)
            }
            if let error = locationService.errorMessage { Text(error).foregroundStyle(.red).font(.caption) }
        }
    }

    private var calculation: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Choose your calculation")
                .font(.largeTitle.weight(.bold))
            Text("These options mirror PrayerCal.com. You can change them later in Settings.")
                .foregroundStyle(.secondary)
            Picker("Prayer time method", selection: $draft.calculationMethod) {
                ForEach(PrayerCalculationMethod.allCases) { Text($0.displayName).tag($0) }
            }
            Picker("Asr method", selection: $draft.asrMethod) {
                ForEach(AsrMethod.allCases) { Text($0.displayName).tag($0) }
            }
        }
    }

    private var preferences: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Make it yours")
                .font(.largeTitle.weight(.bold))
            Toggle("Enable prayer reminders", isOn: $enableNotifications)
            if enableNotifications {
                Stepper("Remind me \(reminderMinutes) minutes before", value: $reminderMinutes, in: 0...60, step: 5)
                Toggle("Use full-screen reminders", isOn: $draft.fullScreenRemindersEnabled)
                Text("Full-screen alerts appear over your work and can be dismissed or snoozed.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Divider()
            Toggle("Enable optional Hijri dates and birthdays", isOn: $draft.showHijriFeatures)
            Text("The Hijri calendar tools are optional and remain available in Settings.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func finish() {
        for prayer in PrayerName.allCases where prayer.isPrayer {
            var option = draft.option(for: prayer)
            option.reminderEnabled = enableNotifications
            option.reminderMinutes = reminderMinutes
            draft.options[prayer.rawValue] = option
        }
        store.update(draft)
        if enableNotifications {
            Task { _ = try? await PrayerNotifications.reschedule(using: store) }
        }
        onComplete()
    }
}
