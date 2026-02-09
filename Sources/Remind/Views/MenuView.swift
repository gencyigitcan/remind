import SwiftUI
import ServiceManagement

struct MenuView: View {
    @EnvironmentObject var store: NoteStore
    // We instantiate LaunchAtLoginManager inside @StateObject if available
    // But since #available cannot be used as an expression for properties, 
    // we use a workaround or conditionally initialize.
    // For simplicity, we just use the manager, which handles availability checks implicitly if we make it conditional, 
    // OR we can make it safe.
    // Wait, the manager class itself has @available(macOS 13.0, *).
    // So we need to conditionally instantiate it or wrap it.
    
    // Simplest way: A wrapper
    @StateObject private var launchWrapper = LaunchWrapper()
    
    @State private var showingAddNote = false
    @State private var editingNote: Note? // Track note being edited
    @State private var newNoteText = ""
    @State private var newNoteRisk = RiskLevel.three
    @State private var newNoteDueDate = Date()
    @State private var hasDueDate = false
    @State private var showHistory = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Remind")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                
                Button(action: { 
                    prepareAddNote()
                    showingAddNote.toggle() 
                }) {
                    Image(systemName: "plus")
                        .font(.title3)
                }
                .disabled(store.activeNotes.count >= 5)
                .help(store.activeNotes.count >= 5 ? "Max 5 notes reached" : "Add Note")
                .buttonStyle(.plain)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            // Main Content Area
            if showingAddNote, editingNote == nil {
                // Add Mode
                AddNoteView(
                    text: $newNoteText,
                    risk: $newNoteRisk,
                    hasDueDate: $hasDueDate,
                    dueDate: $newNoteDueDate,
                    isEditing: false,
                    onSave: {
                        let finalDate = hasDueDate ? newNoteDueDate : nil
                        if store.addNote(newNoteText, risk: newNoteRisk, dueDate: finalDate) {
                            resetForm()
                        }
                    },
                    onCancel: {
                        resetForm()
                    }
                )
                .padding()
                .transition(.opacity.combined(with: .move(edge: .top)))
            } else if let noteToEdit = editingNote {
                // Edit Mode
                AddNoteView(
                    text: $newNoteText,
                    risk: $newNoteRisk,
                    hasDueDate: $hasDueDate,
                    dueDate: $newNoteDueDate,
                    isEditing: true,
                    onSave: {
                        let finalDate = hasDueDate ? newNoteDueDate : nil
                        store.updateNote(id: noteToEdit.id, text: newNoteText, risk: newNoteRisk, dueDate: finalDate)
                        resetForm()
                    },
                    onCancel: {
                        resetForm()
                    }
                )
                .padding()
                .transition(.opacity.combined(with: .move(edge: .top)))
            } else if store.activeNotes.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "list.bullet.clipboard")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("No active reminders")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.vertical, 40)
            } else {
                List(store.activeNotes) { note in
                    NoteRow(note: note, onComplete: {
                        withAnimation {
                            store.completeNote(id: note.id)
                        }
                    }, onSnooze: {
                        let oneHour = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
                        withAnimation {
                            store.snoozeNote(id: note.id, until: oneHour)
                        }
                    }, onEdit: {
                        prepareEditNote(note)
                    })
                    .listRowInsets(EdgeInsets()) 
                    .padding(.vertical, 4)
                }
                .listStyle(.plain)
            }
            
            Spacer()

            Divider()

            // Footer
            HStack {
                Text("\(store.activeNotes.count)/5 Active")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Menu {
                    if #available(macOS 13.0, *) {
                        Toggle("🚀 Launch at Login", isOn: $launchWrapper.isEnabled)
                    } else {
                        Text("Update macOS to enable Launch at Login")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Toggle("🔢 Show Active Count", isOn: $store.showCountOnly)
                    Divider()
                    Button("🚪 Quit") {
                        NSApplication.shared.terminate(nil)
                    }
                } label: {
                    Image(systemName: "gearshape")
                        .font(.subheadline)
                }
                .menuStyle(.borderlessButton)
                .foregroundColor(.secondary)
            }
            .padding(10)
            .background(Color(NSColor.controlBackgroundColor))
        }
        .frame(width: 300, height: 400)
    }
    
    private func prepareAddNote() {
        newNoteText = ""
        newNoteRisk = .three
        newNoteDueDate = Date()
        hasDueDate = false
        editingNote = nil
    }
    
    private func prepareEditNote(_ note: Note) {
        newNoteText = note.text
        newNoteRisk = note.risk
        if let due = note.dueDate {
            newNoteDueDate = due
            hasDueDate = true
        } else {
            newNoteDueDate = Date()
            hasDueDate = false
        }
        editingNote = note
        showingAddNote = false // Hide adding view if open
    }
    
    private func resetForm() {
        newNoteText = ""
        hasDueDate = false
        showingAddNote = false
        editingNote = nil
    }
}

// Wrapper to handle availability
class LaunchWrapper: ObservableObject {
    @Published var isEnabled: Bool = false {
        didSet {
            if #available(macOS 13.0, *) {
                toggle()
            }
        }
    }
    
    init() {
        if #available(macOS 13.0, *) {
            self.isEnabled = SMAppService.mainApp.status == .enabled
        }
    }
    
    @available(macOS 13.0, *)
    private func toggle() {
        do {
            if isEnabled {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                }
            } else {
                if SMAppService.mainApp.status == .enabled {
                    try SMAppService.mainApp.unregister()
                }
            }
        } catch {
            print("Failed to toggle: \(error)")
        }
    }
}

// Inline helper for adding a note
struct AddNoteView: View {
    @Binding var text: String
    @Binding var risk: RiskLevel
    @Binding var hasDueDate: Bool
    @Binding var dueDate: Date
    var isEditing: Bool = false
    var onSave: () -> Void
    var onCancel: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(isEditing ? "Edit Reminder" : "New Reminder")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            TextField("Enter note...", text: $text)
                .textFieldStyle(.roundedBorder)
                .onSubmit(onSave) // Allow Enter to save
            
            Picker("Priority", selection: $risk) {
                ForEach(RiskLevel.allCases) { level in
                    HStack {
                        Circle().fill(level.color).frame(width: 8, height: 8)
                        Text(level.description)
                    }.tag(level)
                }
            }
            .pickerStyle(.menu) // Menu style saves space vs segmented
            .labelsHidden()

            HStack {
                if hasDueDate {
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.accentColor)
                        DatePicker("", selection: $dueDate, displayedComponents: [.hourAndMinute])
                            .labelsHidden()
                        
                        Button(action: { withAnimation { hasDueDate = false } }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                        .help("Remove Time")
                    }
                    .padding(6)
                    .background(Color.primary.opacity(0.05))
                    .cornerRadius(8)
                } else {
                    Button(action: { withAnimation { hasDueDate = true } }) {
                        HStack {
                            Image(systemName: "clock")
                            Text("Add Time")
                        }
                        .font(.caption)
                        .padding(6)
                        .padding(.horizontal, 4)
                        .background(RoundedRectangle(cornerRadius: 8).stroke(Color.primary.opacity(0.2), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                }
                Spacer()
            }

            HStack {
                Button("❌ Cancel", action: onCancel)
                Spacer()
                Button(isEditing ? "💾 Save" : "✨ Add", action: onSave)
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 10).fill(Color(NSColor.controlBackgroundColor)))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
        )
    }
}
