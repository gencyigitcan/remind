import Foundation
import Combine

class NoteStore: ObservableObject {
    @Published var notes: [Note] = [] {
        didSet {
            save()
        }
    }
    @Published var showCountOnly: Bool = false {
        didSet { UserDefaults.standard.set(showCountOnly, forKey: "remind.settings.showCountOnly") }
    }

    private let persistenceKey = "remind.notes.v1"

    init() {
        load()
        showCountOnly = UserDefaults.standard.bool(forKey: "remind.settings.showCountOnly")
    }

    var activeNotes: [Note] {
        notes.filter { $0.status == .active }
             .sorted { $0.risk.rawValue > $1.risk.rawValue } // Highest risk first
    }

    var highestRiskNote: Note? {
        activeNotes.first // Already sorted by risk
    }

    func updateNote(id: UUID, text: String, risk: RiskLevel, dueDate: Date? = nil) {
        if let index = notes.firstIndex(where: { $0.id == id }) {
            notes[index].text = text
            notes[index].risk = risk
            notes[index].dueDate = dueDate
            
            // Re-schedule notifications
            NotificationManager.shared.cancelNotification(for: notes[index])
            
            if risk.rawValue >= 4 {
                NotificationManager.shared.scheduleHighRiskReminder(for: notes[index])
            }
            
            if let _ = dueDate {
                NotificationManager.shared.scheduleDueDateReminders(for: notes[index])
            }
        }
    }

    func addNote(_ text: String, risk: RiskLevel, dueDate: Date? = nil, source: NoteSource = .manual, externalId: String? = nil) -> Bool {
        // If it's a calendar note, check if it already exists by externalId
        if let extId = externalId, notes.contains(where: { $0.externalId == extId }) {
            return false
        }
        
        if activeNotes.count >= 10 { return false } // Increased limit for calendar events
        
        let newNote = Note(text: text, risk: risk, status: .active, source: source, externalId: externalId, dueDate: dueDate)
        notes.append(newNote)
        
        if risk.rawValue >= 4 {
            NotificationManager.shared.scheduleHighRiskReminder(for: newNote)
        }
        
        if let _ = dueDate {
            NotificationManager.shared.scheduleDueDateReminders(for: newNote)
        }
        
        return true
    }

    func syncWithCalendar() {
        CalendarManager.shared.requestAccess { granted, error in
            if granted {
                let events = CalendarManager.shared.fetchTodaysEvents()
                DispatchQueue.main.async {
                    var addedAny = false
                    for event in events {
                        let note = CalendarManager.shared.convertToNote(event)
                        if self.addNote(note.text, risk: note.risk, dueDate: note.dueDate, source: .calendar, externalId: note.externalId) {
                            addedAny = true
                        }
                    }
                    if addedAny {
                        self.save()
                    }
                }
            } else {
                print("Calendar access denied or error: \(String(describing: error))")
            }
        }
    }

    func completeNote(id: UUID) {
        if let index = notes.firstIndex(where: { $0.id == id }) {
            let note = notes[index]
            notes[index].status = .completed
            notes[index].completedAt = Date()
            
            NotificationManager.shared.cancelNotification(for: note)
        }
    }

    func snoozeNote(id: UUID, until date: Date) {
        if let index = notes.firstIndex(where: { $0.id == id }) {
            let note = notes[index]
            notes[index].status = .snoozed
            notes[index].snoozeUntil = date
            
            NotificationManager.shared.cancelNotification(for: note) // Cancel any existing notification
            NotificationManager.shared.scheduleSnooze(for: notes[index])
        }
    }

    func deleteNote(id: UUID) {
        if let note = notes.first(where: { $0.id == id }) {
            NotificationManager.shared.cancelNotification(for: note)
            notes.removeAll { $0.id == id }
        }
    }

    // Check for snoozed notes that should wake up
    func refreshSnoozedNotes() {
        let now = Date()
        var changed = false
        for index in notes.indices {
            if notes[index].status == .snoozed,
               let wakeTime = notes[index].snoozeUntil,
               now >= wakeTime {
                notes[index].status = .active
                notes[index].snoozeUntil = nil
                changed = true
            }
        }
        if changed {
            save()
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(notes) {
            UserDefaults.standard.set(data, forKey: persistenceKey)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: persistenceKey),
           let savedNotes = try? JSONDecoder().decode([Note].self, from: data) {
            self.notes = savedNotes
        }
    }
}
