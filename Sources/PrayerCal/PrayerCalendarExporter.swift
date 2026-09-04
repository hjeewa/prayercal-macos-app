import AppKit
import Foundation

enum PrayerCalendarExporter {
    @MainActor
    static func export(using store: PrayerStore, days: Int = 365) throws -> URL {
        let contents = contents(using: store, days: days)
        let url = FileManager.default.temporaryDirectory.appending(path: "PrayerCal-Prayer-Times.ics")
        try contents.write(to: url, atomically: true, encoding: .utf8)
        NSWorkspace.shared.open(url)
        return url
    }

    @MainActor
    static func contents(using store: PrayerStore, days: Int = 365, startingAt startDate: Date = .now) -> String {
        var lines = [
            "BEGIN:VCALENDAR", "VERSION:2.0", "PRODID:-//PrayerCal//Prayer Times//EN",
            "CALSCALE:GREGORIAN", "METHOD:PUBLISH", "X-WR-CALNAME:PrayerCal"
        ]
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"

        for offset in 0..<days {
            guard let day = Calendar.current.date(byAdding: .day, value: offset, to: startDate) else { continue }
            for moment in store.moments(on: day) where moment.name.isPrayer {
                let option = store.settings.option(for: moment.name)
                guard option.includeInCalendar else { continue }
                let end = moment.date.addingTimeInterval(TimeInterval(max(1, option.durationMinutes) * 60))
                lines += [
                    "BEGIN:VEVENT",
                    "UID:\(moment.name.rawValue)-\(Int(moment.date.timeIntervalSince1970))@prayercal",
                    "DTSTAMP:\(formatter.string(from: .now))",
                    "DTSTART:\(formatter.string(from: moment.date))",
                    "DTEND:\(formatter.string(from: end))",
                    "SUMMARY:\(moment.name.displayName)",
                    "DESCRIPTION:Prayer time calculated by PrayerCal for \(escape(store.settings.locationName))"
                ]
                if option.reminderEnabled {
                    lines += [
                        "BEGIN:VALARM", "TRIGGER:-PT\(option.reminderMinutes)M", "ACTION:DISPLAY",
                        "DESCRIPTION:\(moment.name.displayName) reminder", "END:VALARM"
                    ]
                }
                lines.append("END:VEVENT")
            }
        }
        lines.append("END:VCALENDAR")

        return lines.joined(separator: "\r\n") + "\r\n"
    }

    private static func escape(_ value: String) -> String {
        value.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: ",", with: "\\,")
            .replacingOccurrences(of: ";", with: "\\;")
            .replacingOccurrences(of: "\n", with: "\\n")
    }
}
