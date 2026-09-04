import AppKit
import Foundation

enum PrayerCalCalendarLink {
    @MainActor
    static func url(using store: PrayerStore) -> URL? {
        let settings = store.settings
        var components = URLComponents(string: "https://prayercal.com/")
        var items = [
            URLQueryItem(name: "source", value: "macos"),
            URLQueryItem(name: "lat", value: String(settings.latitude)),
            URLQueryItem(name: "lng", value: String(settings.longitude)),
            URLQueryItem(name: "city", value: settings.locationName),
            URLQueryItem(name: "method", value: String(settings.calculationMethod.prayerCalMethodID)),
            URLQueryItem(name: "school", value: settings.asrMethod == .hanafi ? "hanafi" : "shafi")
        ]
        for prayer in PrayerName.allCases {
            let option = settings.option(for: prayer)
            let value = [
                option.includeInCalendar ? "1" : "0",
                String(option.durationMinutes),
                option.reminderEnabled ? "1" : "0",
                String(option.reminderMinutes)
            ].joined(separator: ",")
            items.append(URLQueryItem(name: prayer.rawValue, value: value))
        }
        components?.queryItems = items
        return components?.url
    }

    @MainActor
    static func open(using store: PrayerStore) {
        guard let url = url(using: store) else { return }
        NSWorkspace.shared.open(url)
    }
}
