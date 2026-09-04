import Adhan
import Foundation
import Observation

@MainActor
@Observable
final class PrayerStore {
    static let shared = PrayerStore()
    private(set) var settings: PrayerSettings
    private let defaults: UserDefaults
    private let storageKey = "prayerSettings.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode(PrayerSettings.self, from: data) {
            settings = decoded
        } else {
            settings = PrayerSettings()
        }
    }

    var timeZone: TimeZone {
        TimeZone(identifier: settings.timeZoneIdentifier) ?? .current
    }

    func update(_ newSettings: PrayerSettings) {
        settings = newSettings
        save()
    }

    func setLocation(latitude: Double, longitude: Double, name: String, timeZone: TimeZone?) {
        settings.hasLocation = true
        settings.latitude = latitude
        settings.longitude = longitude
        settings.locationName = name
        settings.timeZoneIdentifier = (timeZone ?? .current).identifier
        save()
    }

    func moments(on date: Date) -> [PrayerMoment] {
        guard settings.hasLocation else { return [] }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let coordinates = Coordinates(latitude: settings.latitude, longitude: settings.longitude)
        var parameters = settings.calculationMethod.adhanMethod.params
        parameters.madhab = settings.asrMethod.madhab
        // PrayerCal's PHP engine always uses its angle-based high-latitude default.
        parameters.highLatitudeRule = .twilightAngle
        parameters.adjustments = settings.calculationMethod.prayerCalAdjustments
        guard let times = PrayerTimes(coordinates: coordinates, date: components, calculationParameters: parameters) else { return [] }
        return [
            PrayerMoment(name: .fajr, date: times.fajr),
            PrayerMoment(name: .sunrise, date: times.sunrise),
            PrayerMoment(name: .dhuhr, date: times.dhuhr),
            PrayerMoment(name: .asr, date: times.asr),
            PrayerMoment(name: .maghrib, date: times.maghrib),
            PrayerMoment(name: .isha, date: times.isha)
        ]
    }

    func nextPrayer(asOf date: Date) -> PrayerMoment? {
        let today = moments(on: date).filter { $0.name.isPrayer && $0.date > date }
        if let next = today.first { return next }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: date) else { return nil }
        return moments(on: tomorrow).first { $0.name.isPrayer }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        defaults.set(data, forKey: storageKey)
    }
}
