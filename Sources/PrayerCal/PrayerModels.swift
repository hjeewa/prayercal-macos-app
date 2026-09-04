import Adhan
import Foundation

enum PrayerName: String, Codable, CaseIterable, Identifiable {
    case fajr, sunrise, dhuhr, asr, maghrib, isha

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .fajr: "Fajr"
        case .sunrise: "Sunrise"
        case .dhuhr: "Dhuhr"
        case .asr: "Asr"
        case .maghrib: "Maghrib"
        case .isha: "Isha"
        }
    }

    var isPrayer: Bool { self != .sunrise }
}

struct PrayerMoment: Identifiable, Equatable {
    let name: PrayerName
    let date: Date
    var id: String { "\(name.rawValue)-\(date.timeIntervalSince1970)" }
}

enum PrayerFormatting {
    static func time(_ date: Date, in timeZone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.timeZone = timeZone
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }
}

struct PrayerOption: Codable, Equatable {
    var includeInCalendar: Bool
    var durationMinutes: Int
    var reminderEnabled: Bool
    var reminderMinutes: Int
}

enum PrayerCalculationMethod: String, Codable, CaseIterable, Identifiable {
    case moonsightingCommittee, muslimWorldLeague, northAmerica, egyptian
    case ummAlQura, karachi, turkey, dubai, qatar, kuwait, singapore

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .moonsightingCommittee: "Moonsighting Committee Worldwide"
        case .muslimWorldLeague: "Muslim World League"
        case .northAmerica: "Islamic Society of North America (ISNA)"
        case .egyptian: "Egyptian General Authority of Survey"
        case .ummAlQura: "Umm al-Qura University, Makkah"
        case .karachi: "University of Islamic Sciences, Karachi"
        case .turkey: "Diyanet, Turkey"
        case .dubai: "Dubai"
        case .qatar: "Qatar"
        case .kuwait: "Kuwait"
        case .singapore: "Singapore"
        }
    }

    var adhanMethod: CalculationMethod {
        switch self {
        case .moonsightingCommittee: .moonsightingCommittee
        case .muslimWorldLeague: .muslimWorldLeague
        case .northAmerica: .northAmerica
        case .egyptian: .egyptian
        case .ummAlQura: .ummAlQura
        case .karachi: .karachi
        case .turkey: .turkey
        case .dubai: .dubai
        case .qatar: .qatar
        case .kuwait: .kuwait
        case .singapore: .singapore
        }
    }

    /// Final-minute corrections that reproduce PrayerCal.com's generated calendar.
    /// The website adds five minutes to Dhuhr and three to Maghrib after calculation;
    /// some Adhan presets already contain part of those adjustments.
    var prayerCalAdjustments: PrayerAdjustments {
        switch self {
        case .moonsightingCommittee:
            PrayerAdjustments(asr: 3)
        case .muslimWorldLeague:
            PrayerAdjustments(dhuhr: 4, asr: 3, maghrib: 3, isha: 1)
        case .northAmerica:
            PrayerAdjustments(fajr: 1, dhuhr: 4, asr: 3, maghrib: 3)
        case .egyptian:
            PrayerAdjustments(dhuhr: 4, asr: 3, maghrib: 3, isha: 1)
        case .ummAlQura, .qatar:
            PrayerAdjustments(dhuhr: 5, asr: 3, maghrib: 3)
        case .karachi:
            PrayerAdjustments(dhuhr: 4, asr: 3, maghrib: 3, isha: 1)
        case .turkey:
            PrayerAdjustments(sunrise: 7, asr: -1, maghrib: -4, isha: 1)
        case .dubai:
            PrayerAdjustments(sunrise: 3, dhuhr: 2)
        case .kuwait:
            PrayerAdjustments(dhuhr: 5, asr: 3, maghrib: 3, isha: 1)
        case .singapore:
            PrayerAdjustments(dhuhr: 4, asr: 2, maghrib: 2)
        }
    }
}

enum AsrMethod: String, Codable, CaseIterable, Identifiable {
    case standard, hanafi
    var id: String { rawValue }
    var displayName: String { self == .hanafi ? "Hanafi" : "Standard (Shafi, Maliki, Hanbali)" }
    var madhab: Madhab { self == .hanafi ? .hanafi : .shafi }
}

enum HighLatitudeOption: String, Codable, CaseIterable, Identifiable {
    case recommended, middleOfNight, seventhOfNight, twilightAngle
    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .recommended: "Automatic (recommended)"
        case .middleOfNight: "Middle of the night"
        case .seventhOfNight: "Seventh of the night"
        case .twilightAngle: "Twilight angle"
        }
    }

    var rule: HighLatitudeRule? {
        switch self {
        case .recommended: nil
        case .middleOfNight: .middleOfTheNight
        case .seventhOfNight: .seventhOfTheNight
        case .twilightAngle: .twilightAngle
        }
    }
}

struct PrayerSettings: Codable, Equatable {
    var hasLocation = false
    var locationName = "Choose a location"
    var latitude = 51.5074
    var longitude = -0.1278
    var timeZoneIdentifier = TimeZone.current.identifier
    var calculationMethod = PrayerCalculationMethod.moonsightingCommittee
    var asrMethod = AsrMethod.standard
    // PrayerCal.com uses its angle-based rule by default.
    var highLatitudeOption = HighLatitudeOption.twilightAngle
    var showHijriFeatures = false
    var fullScreenRemindersEnabled = false
    var options: [String: PrayerOption] = Dictionary(uniqueKeysWithValues: PrayerName.allCases.map {
        ($0.rawValue, PrayerOption(
            includeInCalendar: $0 != .sunrise,
            durationMinutes: $0 == .sunrise ? 0 : 15,
            reminderEnabled: false,
            reminderMinutes: $0 == .sunrise ? 0 : 10
        ))
    })

    init() {}

    private enum CodingKeys: String, CodingKey {
        case hasLocation, locationName, latitude, longitude, timeZoneIdentifier
        case calculationMethod, asrMethod, highLatitudeOption, showHijriFeatures
        case fullScreenRemindersEnabled, options
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        hasLocation = try values.decodeIfPresent(Bool.self, forKey: .hasLocation) ?? false
        locationName = try values.decodeIfPresent(String.self, forKey: .locationName) ?? "Choose a location"
        latitude = try values.decodeIfPresent(Double.self, forKey: .latitude) ?? 51.5074
        longitude = try values.decodeIfPresent(Double.self, forKey: .longitude) ?? -0.1278
        timeZoneIdentifier = try values.decodeIfPresent(String.self, forKey: .timeZoneIdentifier) ?? TimeZone.current.identifier
        calculationMethod = try values.decodeIfPresent(PrayerCalculationMethod.self, forKey: .calculationMethod) ?? .moonsightingCommittee
        asrMethod = try values.decodeIfPresent(AsrMethod.self, forKey: .asrMethod) ?? .standard
        highLatitudeOption = try values.decodeIfPresent(HighLatitudeOption.self, forKey: .highLatitudeOption) ?? .twilightAngle
        showHijriFeatures = try values.decodeIfPresent(Bool.self, forKey: .showHijriFeatures) ?? false
        fullScreenRemindersEnabled = try values.decodeIfPresent(Bool.self, forKey: .fullScreenRemindersEnabled) ?? false
        options = try values.decodeIfPresent([String: PrayerOption].self, forKey: .options) ?? Self().options
    }

    func option(for prayer: PrayerName) -> PrayerOption {
        options[prayer.rawValue] ?? PrayerOption(includeInCalendar: prayer != .sunrise, durationMinutes: 15, reminderEnabled: false, reminderMinutes: 10)
    }
}
