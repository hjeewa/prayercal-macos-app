import AppKit
import Foundation

struct PrayerCalSubscription: Codable, Equatable {
    let calendarId: String
    let httpsUrl: String
    let webcalUrl: String
    let googleUrl: String
    let outlookUrl: String
}

enum PrayerCalSubscriptionError: LocalizedError {
    case invalidEmail, invalidResponse, server(String)

    var errorDescription: String? {
        switch self {
        case .invalidEmail: "Enter a valid email address."
        case .invalidResponse: "PrayerCal returned an invalid response."
        case .server(let message): message
        }
    }
}

enum PrayerCalSubscriptionService {
    static let endpoint = URL(string: "https://prayercal.com/api/v1/macos-calendar")!

    @MainActor
    static func create(using store: PrayerStore, email: String) async throws -> PrayerCalSubscription {
        guard email.contains("@"), email.contains(".") else { throw PrayerCalSubscriptionError.invalidEmail }
        let settings = store.settings
        let prayerOptions = Dictionary(uniqueKeysWithValues: PrayerName.allCases.map { prayer in
            let option = settings.option(for: prayer)
            return (prayer.rawValue, [
                "enabled": option.includeInCalendar,
                "duration": option.durationMinutes,
                "alarm_enabled": option.reminderEnabled,
                "alarm_minutes": option.reminderMinutes
            ] as [String: Any])
        })
        let body: [String: Any] = [
            "email": email,
            "latitude": settings.latitude,
            "longitude": settings.longitude,
            "city": settings.locationName,
            "method_id": settings.calculationMethod.prayerCalMethodID,
            "school": settings.asrMethod == .hanafi ? "hanafi" : "shafi",
            "prayers": prayerOptions
        ]
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("PrayerCal-macOS/0.4", forHTTPHeaderField: "User-Agent")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw PrayerCalSubscriptionError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else {
            let message = (try? JSONDecoder().decode(ServerError.self, from: data).error) ?? "PrayerCal could not create the subscription."
            throw PrayerCalSubscriptionError.server(message)
        }
        return try JSONDecoder().decode(PrayerCalSubscription.self, from: data)
    }

    @MainActor
    static func open(_ value: String) {
        guard let url = URL(string: value) else { return }
        NSWorkspace.shared.open(url)
    }

    private struct ServerError: Decodable { let error: String }
}
