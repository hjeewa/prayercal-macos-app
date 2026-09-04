import Foundation

struct HijriDate: Equatable, Codable {
    let year: Int
    let month: Int
    let day: Int

    var formatted: String {
        "\(day) \(HijriCalendar.monthName(month)) \(year) AH"
    }

    var shortFormatted: String {
        "\(day) \(HijriCalendar.shortMonthName(month))"
    }
}

enum HijriCalendar {
    static let calendar: Calendar = {
        var calendar = Calendar(identifier: .islamicUmmAlQura)
        calendar.locale = Locale(identifier: "en_GB")
        return calendar
    }()

    static func hijriDate(from date: Date, timeZone: TimeZone = .current) -> HijriDate {
        var calendar = calendar
        calendar.timeZone = timeZone
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return HijriDate(
            year: components.year ?? 0,
            month: components.month ?? 0,
            day: components.day ?? 0
        )
    }

    static func hijriAge(bornOn birthday: Date, asOf date: Date = .now) -> Int {
        let birth = hijriDate(from: birthday)
        let current = hijriDate(from: date)
        var age = current.year - birth.year
        if (current.month, current.day) < (birth.month, birth.day) {
            age -= 1
        }
        return max(0, age)
    }

    static func gregorianAge(bornOn birthday: Date, asOf date: Date = .now) -> Int {
        max(0, Calendar.current.dateComponents([.year], from: birthday, to: date).year ?? 0)
    }

    static func daysUntilNextBirthday(
        bornOn birthday: Date,
        asOf date: Date = .now,
        timeZone: TimeZone = .current
    ) -> Int {
        var hijriCalendar = calendar
        hijriCalendar.timeZone = timeZone
        var gregorianCalendar = Calendar(identifier: .gregorian)
        gregorianCalendar.timeZone = timeZone

        let birth = hijriDate(from: birthday, timeZone: timeZone)
        let current = hijriDate(from: date, timeZone: timeZone)
        let today = gregorianCalendar.startOfDay(for: date)

        for year in current.year...(current.year + 2) {
            guard let firstOfBirthMonth = hijriCalendar.date(from: DateComponents(
                calendar: hijriCalendar,
                timeZone: timeZone,
                year: year,
                month: birth.month,
                day: 1
            )), let validDays = hijriCalendar.range(of: .day, in: .month, for: firstOfBirthMonth) else {
                continue
            }

            // A birthday on day 30 falls on the last day in 29-day occurrences of that month.
            let birthdayDay = min(birth.day, validDays.count)
            guard let candidate = hijriCalendar.date(from: DateComponents(
                calendar: hijriCalendar,
                timeZone: timeZone,
                year: year,
                month: birth.month,
                day: birthdayDay
            )) else { continue }

            let candidateDay = gregorianCalendar.startOfDay(for: candidate)
            if candidateDay >= today {
                return gregorianCalendar.dateComponents([.day], from: today, to: candidateDay).day ?? 0
            }
        }

        return 0
    }

    static func birthdayCountdownText(
        bornOn birthday: Date,
        asOf date: Date = .now,
        timeZone: TimeZone = .current
    ) -> String {
        let days = daysUntilNextBirthday(bornOn: birthday, asOf: date, timeZone: timeZone)
        switch days {
        case 0: return "today"
        case 1: return "1 day"
        default: return "\(days) days"
        }
    }

    static func monthName(_ month: Int) -> String {
        guard (1...monthNames.count).contains(month) else { return "" }
        return monthNames[month - 1]
    }

    static func shortMonthName(_ month: Int) -> String {
        guard (1...shortMonthNames.count).contains(month) else { return "" }
        return shortMonthNames[month - 1]
    }

    static let monthNames = [
        "Muharram", "Safar", "Rabi al-Awwal", "Rabi al-Thani",
        "Jumada al-Awwal", "Jumada al-Thani", "Rajab", "Sha'ban",
        "Ramadan", "Shawwal", "Dhu al-Qi'dah", "Dhu al-Hijjah"
    ]

    static let shortMonthNames = [
        "Muh", "Saf", "Rab I", "Rab II", "Jum I", "Jum II",
        "Raj", "Sha", "Ram", "Shaw", "Dhu Q", "Dhu H"
    ]
}

struct HijriEvent: Identifiable, Equatable, Codable {
    var id = UUID()
    let month: Int
    let day: Int
    var title: String
    var note: String
}

enum HijriEvents {
    // Common Sunni observances and selected historical anniversaries. Exact historical
    // dates are labelled where reports vary; local moon sighting can shift dates by a day.
    static let defaults: [HijriEvent] = [
        .init(month: 1, day: 1, title: "Islamic New Year", note: "First day of Muharram"),
        .init(month: 1, day: 9, title: "Tasu'a", note: "Commonly paired with the fast of Ashura"),
        .init(month: 1, day: 10, title: "Ashura", note: "A recommended day of fasting; also the anniversary of Karbala (61 AH)"),
        .init(month: 3, day: 12, title: "Mawlid al-Nabi", note: "Observed by many Sunni communities"),
        .init(month: 3, day: 12, title: "Arrival in Madinah", note: "Traditional date reported for the Hijrah arrival (1 AH)"),
        .init(month: 7, day: 27, title: "Al-Isra wal-Mi'raj", note: "Observed by many communities"),
        .init(month: 8, day: 15, title: "Mid-Sha'ban", note: "Observed by many communities"),
        .init(month: 9, day: 1, title: "Beginning of Ramadan", note: "Subject to local moon sighting"),
        .init(month: 9, day: 17, title: "Battle of Badr", note: "Historical anniversary (2 AH)"),
        .init(month: 9, day: 20, title: "Conquest of Makkah", note: "Commonly reported historical date (8 AH)"),
        .init(month: 9, day: 21, title: "Last ten nights of Ramadan", note: "Seek Laylat al-Qadr throughout the odd nights"),
        .init(month: 9, day: 27, title: "Laylat al-Qadr", note: "Commonly marked on the 27th night; sought in the last ten nights"),
        .init(month: 10, day: 1, title: "Eid al-Fitr", note: "Subject to local moon sighting"),
        .init(month: 10, day: 7, title: "Battle of Uhud", note: "Often reported as 7 Shawwal 3 AH; the precise date differs in historical reports"),
        .init(month: 12, day: 1, title: "First ten days of Dhu al-Hijjah", note: "Beginning of ten especially virtuous days"),
        .init(month: 12, day: 8, title: "Hajj begins", note: "Beginning of the main Hajj rites"),
        .init(month: 12, day: 9, title: "Day of Arafah", note: "A recommended day of fasting for non-pilgrims"),
        .init(month: 12, day: 10, title: "Eid al-Adha", note: "Festival of sacrifice"),
        .init(month: 12, day: 11, title: "Days of Tashreeq", note: "11–13 Dhu al-Hijjah")
    ]

    static func on(_ date: HijriDate, in events: [HijriEvent]) -> [HijriEvent] {
        events.filter { $0.month == date.month && $0.day == date.day }
    }

    static func upcoming(after date: HijriDate, in events: [HijriEvent], limit: Int = 3) -> [HijriEvent] {
        let sorted = events.sorted {
            ($0.month, $0.day, $0.title) < ($1.month, $1.day, $1.title)
        }
        let laterThisYear = sorted.filter { ($0.month, $0.day) > (date.month, date.day) }
        let nextYear = sorted.filter { ($0.month, $0.day) <= (date.month, date.day) }
        return Array((laterThisYear + nextYear).prefix(limit))
    }
}
