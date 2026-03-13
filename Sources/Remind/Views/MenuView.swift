import SwiftUI
import ServiceManagement

struct MenuView: View {
    @EnvironmentObject var store: NoteStore
    @StateObject private var launchWrapper = LaunchWrapper()
    
    @State private var showingAddNote = false
    @State private var editingNote: Note?
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
                .disabled(store.activeNotes.count >= 10)
                .help(store.activeNotes.count >= 10 ? "Max 10 notes reached" : "Add Note")
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
                VStack(spacing: 8) {
                    Text("☕️")
                        .font(.largeTitle)
                    Text("Bugün bir program yok")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    Text("Dinlenmek için harika bir gün!")
                        .font(.caption2)
                        .foregroundColor(.secondary.opacity(0.8))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.vertical, 20)
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
            
            Divider()

            // Footer
            HStack {
                Text("\(store.activeNotes.count)/10 Active")
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
        .frame(minWidth: 320, maxWidth: 320)
        .frame(minHeight: 150, maxHeight: 800)
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
        showingAddNote = false
    }
    
    private func resetForm() {
        newNoteText = ""
        hasDueDate = false
        showingAddNote = false
        editingNote = nil
    }
}

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
                .onSubmit(onSave)
            
            Picker("Priority", selection: $risk) {
                ForEach(RiskLevel.allCases) { level in
                    HStack {
                        Circle().fill(level.color).frame(width: 8, height: 8)
                        Text(level.description)
                    }.tag(level)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()

            VStack(alignment: .leading, spacing: 0) {
                DatePicker("Tarih Seçin", selection: $dueDate, displayedComponents: [.date])
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, -5) // Stretch slightly to fill container
                
                Divider()
                    .padding(.horizontal, -10)
                
                HStack {
                    Toggle(isOn: $hasDueDate) {
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(hasDueDate ? .accentColor : .secondary)
                            Text("Saat Ekle")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                    }
                    .toggleStyle(.checkbox)
                    
                    if hasDueDate {
                        DatePicker("", selection: $dueDate, displayedComponents: [.hourAndMinute])
                            .labelsHidden()
                            .transition(.opacity)
                    }
                }
                .padding(.top, 10)
            }
            .padding(10)
            .background(Color(NSColor.alternatingContentBackgroundColors[1]).opacity(0.5))
            .cornerRadius(8)

            HStack {
                Button("❌ İptal", action: onCancel)
                Spacer()
                Button(isEditing ? "💾 Kaydet" : "✨ Ekle", action: onSave)
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(NSColor.controlBackgroundColor)))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
        )
    }
}
