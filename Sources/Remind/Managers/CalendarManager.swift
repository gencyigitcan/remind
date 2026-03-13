import Foundation
import EventKit

class CalendarManager {
    static let shared = CalendarManager()
    private let eventStore = EKEventStore()
    
    private init() {}
    
    func requestAccess(completion: @escaping (Bool, Error?) -> Void) {
        if #available(macOS 14.0, *) {
            eventStore.requestFullAccessToEvents(completion: completion)
        } else {
            eventStore.requestAccess(to: .event, completion: completion)
        }
    }
    
    func fetchTodaysEvents() -> [EKEvent] {
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = eventStore.predicateForEvents(withStart: startOfDay, end: endOfDay, calendars: nil)
        let events = eventStore.events(matching: predicate)
        
        // Filter out all-day events if they are not relevant, or keep them. 
        // For reminders, we probably want timed events mostly, but let's keep all and let the user decide.
        // Also filter out cancelled events.
        return events.filter { $0.status != .canceled }
    }
    
    func convertToNote(_ event: EKEvent) -> Note {
        // Map event properties to Note
        // Meetings are usually high risk (3 or 4)
        let risk: RiskLevel = .three 
        
        return Note(
            text: event.title ?? "Untitled Event",
            risk: risk,
            status: .active,
            source: .calendar,
            externalId: event.eventIdentifier,
            dueDate: event.startDate
        )
    }
    
    func addEvent(title: String, startDate: Date) -> String? {
        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = startDate
        event.endDate = startDate.addingTimeInterval(1800) // Default 30 min duration
        event.calendar = eventStore.defaultCalendarForNewEvents
        
        do {
            try eventStore.save(event, span: .thisEvent)
            return event.eventIdentifier
        } catch {
            print("Failed to save event to calendar: \(error)")
            return nil
        }
    }
}
