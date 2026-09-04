import XCTest
@testable import HijriBar

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
        let events = HijriEvents.upcoming(after: HijriDate(year: 1445, month: 12, day: 10), limit: 2)
        XCTAssertEqual(events.map(\.title), ["Islamic New Year", "Ashura"])
    }
}
