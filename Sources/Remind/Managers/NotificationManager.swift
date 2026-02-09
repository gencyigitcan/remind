import Foundation
import UserNotifications

class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    weak var noteStore: NoteStore?

    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        requestAuthorization()
        setupCategories()
    }
    
    private func setupCategories() {
        let completeAction = UNNotificationAction(identifier: "COMPLETE_ACTION", title: "Complete", options: [.foreground])
        let snoozeAction = UNNotificationAction(identifier: "SNOOZE_ACTION", title: "Snooze 15m", options: [])
        let cancelAction = UNNotificationAction(identifier: "CANCEL_ACTION", title: "Dismiss", options: [.destructive])
        
        let dueCategory = UNNotificationCategory(identifier: "DUE_REMINDER", actions: [completeAction, snoozeAction, cancelAction], intentIdentifiers: [], options: .customDismissAction)
        
        UNUserNotificationCenter.current().setNotificationCategories([dueCategory])
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
    
    // Handle Actions
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let identifier = response.notification.request.identifier
        
        // Extract note UUID from identifier (format: "due_suffix_UUID" or "high_risk_UUID" or just "UUID")
        // We know most identifiers end with the UUID string.
        // It's safer to extract it properly.
        // Let's assume the last component after the last underscore is the UUID, OR the whole thing is the UUID.
        
        // However, standard identifiers I used: "due_15m_UUID", "high_risk_UUID", "UUID"
        var uuidString = identifier
        if let range = identifier.range(of: "_", options: .backwards) {
               uuidString = String(identifier[range.upperBound...])
        }
        
        guard let noteId = UUID(uuidString: uuidString) else {
            completionHandler()
            return
        }
        
        switch response.actionIdentifier {
        case "COMPLETE_ACTION":
            DispatchQueue.main.async {
                self.noteStore?.completeNote(id: noteId)
            }
        case "SNOOZE_ACTION":
            DispatchQueue.main.async {
                let snoozeDate = Date().addingTimeInterval(15 * 60)
                self.noteStore?.snoozeNote(id: noteId, until: snoozeDate)
            }
        case "CANCEL_ACTION", UNNotificationDismissActionIdentifier:
             // Just dismiss/cancel associated notifications if needed? 
             // Actually if they dismiss, we do nothing usually.
             break
        default:
            break
        }
        
        completionHandler()
    }
    
    // Show notification even if app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .list])
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
        content.categoryIdentifier = "DUE_REMINDER"

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
                content.categoryIdentifier = "DUE_REMINDER"
                
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
