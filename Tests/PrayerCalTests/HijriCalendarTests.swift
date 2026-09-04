import XCTest
@testable import PrayerCal

final class HijriCalendarTests: XCTestCase {
    private var utcGregorian: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    func testKnownRamadanDate() throws {
        let date = try XCTUnwrap(utcGregorian.date(from: DateComponents(year: 2024, month: 3, day: 11, hour: 12)))
        let hijri = HijriCalendar.hijriDate(from: date, timeZone: TimeZone(secondsFromGMT: 0)!)
        XCTAssertEqual(hijri, HijriDate(year: 1445, month: 9, day: 1))
    }

    func testUpcomingEventsWrapIntoNextYear() {
        let events = HijriEvents.upcoming(after: HijriDate(year: 1445, month: 12, day: 10), in: HijriEvents.defaults, limit: 2)
        XCTAssertEqual(events.map(\.title), ["Days of Tashreeq", "Islamic New Year"])
    }

    func testBirthdayCountdownOnBirthday() throws {
        let timeZone = try XCTUnwrap(TimeZone(secondsFromGMT: 0))
        var hijri = Calendar(identifier: .islamicUmmAlQura)
        hijri.timeZone = timeZone
        let birthday = try XCTUnwrap(hijri.date(from: DateComponents(year: 1400, month: 9, day: 1)))
        let today = try XCTUnwrap(hijri.date(from: DateComponents(year: 1445, month: 9, day: 1)))

        XCTAssertEqual(HijriCalendar.daysUntilNextBirthday(bornOn: birthday, asOf: today, timeZone: timeZone), 0)
        XCTAssertEqual(HijriCalendar.birthdayCountdownText(bornOn: birthday, asOf: today, timeZone: timeZone), "today")
    }

    func testBirthdayCountdownWithinMonth() throws {
        let timeZone = try XCTUnwrap(TimeZone(secondsFromGMT: 0))
        var hijri = Calendar(identifier: .islamicUmmAlQura)
        hijri.timeZone = timeZone
        let birthday = try XCTUnwrap(hijri.date(from: DateComponents(year: 1400, month: 9, day: 11)))
        let today = try XCTUnwrap(hijri.date(from: DateComponents(year: 1445, month: 9, day: 1)))

        XCTAssertEqual(HijriCalendar.daysUntilNextBirthday(bornOn: birthday, asOf: today, timeZone: timeZone), 10)
        XCTAssertEqual(HijriCalendar.birthdayCountdownText(bornOn: birthday, asOf: today, timeZone: timeZone), "10 days")
    }
}
