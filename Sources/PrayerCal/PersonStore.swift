import Foundation
import Observation

struct Person: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var gregorianBirthday: Date
}

@MainActor
@Observable
final class PersonStore {
    private(set) var people: [Person] = []
    private let defaults: UserDefaults
    private let storageKey = "people.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        load()
    }

    func add(name: String, birthday: Date) {
        people.append(Person(name: name.trimmingCharacters(in: .whitespacesAndNewlines), gregorianBirthday: birthday))
        people.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        save()
    }

    func remove(at offsets: IndexSet) {
        people.remove(atOffsets: offsets)
        save()
    }

    func update(_ person: Person) {
        guard let index = people.firstIndex(where: { $0.id == person.id }) else { return }
        people[index] = person
        save()
    }

    private func load() {
        guard let data = defaults.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([Person].self, from: data) else { return }
        people = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(people) else { return }
        defaults.set(data, forKey: storageKey)
    }
}
