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

    func scheduleDueDateReminders(for note: Note) {
        guard let dueDate = note.dueDate else { return }
        
        // Define intervals: 15 min, 1 hour, 3 hours
        let intervals: [(TimeInterval, String)] = [
            (15 * 60, "15m"),
            (60 * 60, "1h"),
            (3 * 60 * 60, "3h")
        ]
        
        for (secondsBefore, suffix) in intervals {
            let triggerDate = dueDate.addingTimeInterval(-secondsBefore)
            
            // Only schedule if the trigger time is in the future
            if triggerDate > Date() {
                let content = UNMutableNotificationContent()
                content.title = "Reminder Due Soon"
                content.body = "\(note.text) is due in \(suffix)."
                content.sound = .default
                content.interruptionLevel = .timeSensitive
                
                let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: triggerDate)
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                
                let identifier = "due_\(suffix)_\(note.id.uuidString)"
                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                
                UNUserNotificationCenter.current().add(request) { error in
                    if let error = error {
                        print("Error scheduling \(suffix) reminder: \(error)")
                    }
                }
            }
        }
    }

    func cancelNotification(for note: Note) {
        let identifiers = [
            note.id.uuidString,
            "high_risk_\(note.id.uuidString)",
            "due_15m_\(note.id.uuidString)",
            "due_1h_\(note.id.uuidString)",
            "due_3h_\(note.id.uuidString)"
        ]
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }
}
