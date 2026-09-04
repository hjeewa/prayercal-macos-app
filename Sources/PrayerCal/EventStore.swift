import Foundation
import Observation

@MainActor
@Observable
final class EventStore {
    private(set) var events: [HijriEvent] = []
    private let defaults: UserDefaults
    private let storageKey = "calendarEvents.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        load()
    }

    func add(title: String, month: Int, day: Int, note: String) {
        events.append(HijriEvent(
            month: month,
            day: day,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            note: note.trimmingCharacters(in: .whitespacesAndNewlines)
        ))
        sortAndSave()
    }

    func remove(at offsets: IndexSet) {
        events.remove(atOffsets: offsets)
        save()
    }

    func resetToDefaults() {
        events = HijriEvents.defaults
        sortAndSave()
    }

    private func load() {
        if let data = defaults.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([HijriEvent].self, from: data) {
            events = decoded
        } else {
            events = HijriEvents.defaults
        }
        sort()
    }

    private func sortAndSave() {
        sort()
        save()
    }

    private func sort() {
        events.sort { ($0.month, $0.day, $0.title) < ($1.month, $1.day, $1.title) }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(events) else { return }
        defaults.set(data, forKey: storageKey)
    }
}
