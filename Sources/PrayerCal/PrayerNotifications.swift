import Foundation
import UserNotifications

enum PrayerNotifications {
    static func reschedule(using store: PrayerStore, days: Int = 7) async throws -> Int {
        let center = UNUserNotificationCenter.current()
        let granted = try await center.requestAuthorization(options: [.alert, .sound])
        guard granted else { return 0 }
        center.removePendingNotificationRequests(withIdentifiers: await pendingPrayerIdentifiers(center: center))

        var requests: [UNNotificationRequest] = []
        let now = Date.now
        for dayOffset in 0..<days {
            guard let day = Calendar.current.date(byAdding: .day, value: dayOffset, to: now) else { continue }
            for moment in await store.moments(on: day) where moment.name.isPrayer {
                let option = await store.settings.option(for: moment.name)
                guard option.reminderEnabled else { continue }
                let fireDate = moment.date.addingTimeInterval(TimeInterval(-option.reminderMinutes * 60))
                guard fireDate > now else { continue }

                let content = UNMutableNotificationContent()
                content.title = option.reminderMinutes == 0 ? "Time for \(moment.name.displayName)" : "\(moment.name.displayName) in \(option.reminderMinutes) minutes"
                content.body = "PrayerCal · \(await store.settings.locationName)"
                content.sound = .default
                let trigger = UNCalendarNotificationTrigger(
                    dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate),
                    repeats: false
                )
                let identifier = "prayercal-\(moment.name.rawValue)-\(Int(moment.date.timeIntervalSince1970))"
                requests.append(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger))
            }
        }
        for request in requests { try await center.add(request) }
        return requests.count
    }

    private static func pendingPrayerIdentifiers(center: UNUserNotificationCenter) async -> [String] {
        await center.pendingNotificationRequests().map(\.identifier).filter { $0.hasPrefix("prayercal-") }
    }
}
