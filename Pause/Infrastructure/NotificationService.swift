import Foundation
import UserNotifications

final class NotificationService {
    private let center = UNUserNotificationCenter.current()

    func requestAuthorization() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
    }

    func scheduleSessionEnd(at date: Date) async {
        cancelSessionNotifications()
        guard date > .now else { return }
        let content = UNMutableNotificationContent()
        content.title = "Your planned session is complete"
        content.body = "Return to Pause when you are ready to reflect."
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, date.timeIntervalSinceNow), repeats: false)
        let request = UNNotificationRequest(identifier: "pause.session.end", content: content, trigger: trigger)
        try? await center.add(request)
    }

    func cancelSessionNotifications() {
        center.removePendingNotificationRequests(withIdentifiers: ["pause.session.end"])
    }
}

