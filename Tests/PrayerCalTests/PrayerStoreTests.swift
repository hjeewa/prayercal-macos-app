import XCTest
@testable import PrayerCal

@MainActor
final class PrayerStoreTests: XCTestCase {
    private func makeStore() -> PrayerStore {
        let suite = "PrayerStoreTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        let store = PrayerStore(defaults: defaults)
        store.setLocation(latitude: 51.5074, longitude: -0.1278, name: "London", timeZone: TimeZone(identifier: "Europe/London"))
        return store
    }

    func testCalculatesSixOrderedTimes() throws {
        let store = makeStore()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/London")!
        let date = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 9, day: 4, hour: 12)))
        let moments = store.moments(on: date)

        XCTAssertEqual(moments.map(\.name), PrayerName.allCases)
        XCTAssertEqual(moments.map(\.date), moments.map(\.date).sorted())
    }

    func testMoonsightingTimesMatchPrayerCalReference() throws {
        let store = makeStore()
        var calendar = Calendar(identifier: .gregorian)
        let timeZone = try XCTUnwrap(TimeZone(identifier: "Europe/London"))
        calendar.timeZone = timeZone
        let date = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 9, day: 4, hour: 12)))
        let values = Dictionary(uniqueKeysWithValues: store.moments(on: date).map { moment in
            let parts = calendar.dateComponents([.hour, .minute], from: moment.date)
            return (moment.name, String(format: "%02d:%02d", parts.hour ?? 0, parts.minute ?? 0))
        })

        XCTAssertEqual(values[.fajr], "04:40")
        XCTAssertEqual(values[.sunrise], "06:18")
        XCTAssertEqual(values[.dhuhr], "13:05")
        XCTAssertEqual(values[.asr], "16:41")
        XCTAssertEqual(values[.maghrib], "19:43")
        XCTAssertEqual(values[.isha], "20:53")
    }

    func testNextPrayerExcludesSunrise() throws {
        let store = makeStore()
        let moments = store.moments(on: Date(timeIntervalSince1970: 1_788_500_000))
        let fajr = try XCTUnwrap(moments.first { $0.name == .fajr })
        let next = try XCTUnwrap(store.nextPrayer(asOf: fajr.date.addingTimeInterval(60)))
        XCTAssertEqual(next.name, .dhuhr)
    }

    func testCalculationMethodsMapToPrayerCalServerIDs() {
        XCTAssertEqual(PrayerCalculationMethod.moonsightingCommittee.prayerCalMethodID, 15)
        XCTAssertEqual(PrayerCalculationMethod.muslimWorldLeague.prayerCalMethodID, 3)
        XCTAssertEqual(PrayerCalculationMethod.northAmerica.prayerCalMethodID, 2)
        XCTAssertEqual(PrayerCalculationMethod.ummAlQura.prayerCalMethodID, 4)
        XCTAssertEqual(PrayerCalculationMethod.turkey.prayerCalMethodID, 13)
        XCTAssertEqual(PrayerCalculationMethod.dubai.prayerCalMethodID, 16)
    }

    func testCalendarHandoffPrefillsPrayerCalWebsite() throws {
        let store = makeStore()
        let url = try XCTUnwrap(PrayerCalCalendarLink.url(using: store))
        let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
        let values = Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).compactMap { item in
            item.value.map { (item.name, $0) }
        })

        XCTAssertEqual(url.host, "app.prayercal.com")
        XCTAssertEqual(values["source"], "macos")
        XCTAssertEqual(values["city"], "London")
        XCTAssertEqual(values["method"], "15")
        XCTAssertEqual(values["school"], "shafi")
        XCTAssertEqual(values["fajr"], "1,15,0,10")
    }
}
