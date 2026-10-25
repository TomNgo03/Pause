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

    func scheduleDailyRoutine(_ routine: CareRoutine) async {
        guard routine.isEnabled else { return }
        _ = await requestAuthorization()
        let content = routineContent(routine)
        cancelRoutine(id: routine.id)
        for weekday in routine.repeatWeekdays {
            let components = DateComponents(hour: routine.reminderHour, minute: routine.reminderMinute, weekday: weekday)
            let request = UNNotificationRequest(identifier: routineID(routine.id, suffix: "day-\(weekday)"), content: content, trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: true))
            try? await center.add(request)
        }
    }

    func scheduleRoutine(_ routine: CareRoutine, at date: Date) async {
        _ = await requestAuthorization()
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, date.timeIntervalSinceNow), repeats: false)
        try? await center.add(UNNotificationRequest(identifier: routineID(routine.id, suffix: "snooze"), content: routineContent(routine), trigger: trigger))
    }

    func cancelRoutine(id: UUID) {
        let identifiers = (1...7).map { routineID(id, suffix: "day-\($0)") } + [routineID(id, suffix: "snooze")]
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    private func routineContent(_ routine: CareRoutine) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = "Ready for a quick check?"
        content.body = routine.title
        content.sound = .default
        return content
    }

    private func routineID(_ id: UUID, suffix: String) -> String { "pause.routine.\(id.uuidString).\(suffix)" }
}

