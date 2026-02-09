import Foundation
import UserNotifications

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    init() {
        requestAuthorization()
    }

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted.")
            } else if let error = error {
                print("Notification permission denied: \(error.localizedDescription)")
            }
        }
    }

    func scheduleSnooze(for note: Note) {
        guard let fireDate = note.snoozeUntil else { return }

        let content = UNMutableNotificationContent()
        content.title = "Reminder Snooze Ended"
        content.body = note.text
        content.sound = .default

        // Trigger on specific date
        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)

        let request = UNNotificationRequest(identifier: note.id.uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }

    // Schedule periodic reminders for high-risk notes (Risk >= 4)
    func scheduleHighRiskReminder(for note: Note) {
        guard note.risk.rawValue >= 4 else { return }

        let content = UNMutableNotificationContent()
        content.title = "⚠️ High Priority Reminder"
        content.body = note.text
        content.sound = .defaultCritical
        content.interruptionLevel = .timeSensitive

        // Trigger every hour
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3600, repeats: true)

        let request = UNNotificationRequest(identifier: "high_risk_\(note.id.uuidString)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func cancelNotification(for note: Note) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [note.id.uuidString, "high_risk_\(note.id.uuidString)"])
    }
}
