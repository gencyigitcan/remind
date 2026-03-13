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
        VStack(spacing: 0) {
            // Header & Inputs (with padding)
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(isEditing ? "Hemen Düzenle" : "Yeni Hatırlatıcı")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                
                TextField("Ne hatırlatayım?", text: $text)
                    .textFieldStyle(.plain)
                    .font(.body)
                    .padding(8)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(6)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.primary.opacity(0.1), lineWidth: 1))
                    .onSubmit(onSave)
                
                HStack(spacing: 12) {
                    Picker("", selection: $risk) {
                        ForEach(RiskLevel.allCases) { level in
                            HStack {
                                Circle().fill(level.color).frame(width: 8, height: 8)
                                Text(level.description)
                            }.tag(level)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .frame(width: 120)
                    
                    Spacer()
                    
                    Toggle(isOn: $hasDueDate) {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                            Text("Saat")
                        }
                        .font(.caption)
                        .fontWeight(.medium)
                    }
                    .toggleStyle(.checkbox)
                    
                    if hasDueDate {
                        DatePicker("", selection: $dueDate, displayedComponents: [.hourAndMinute])
                            .labelsHidden()
                            .scaleEffect(0.9)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)

            Divider()

            // Calendar (FLUSH - No horizontal padding)
            DatePicker("", selection: $dueDate, displayedComponents: [.date])
                .datePickerStyle(.graphical)
                .labelsHidden()
                .padding(.horizontal, 0)
                .padding(.top, 0)
                .padding(.bottom, 8)
                .background(Color.primary.opacity(0.02))

            Divider()

            // Footer Actions (with padding)
            HStack(spacing: 12) {
                Button(action: onCancel) {
                    Text("İptal")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                
                Button(action: onSave) {
                    Text(isEditing ? "Kaydet" : "Ekle")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .keyboardShortcut(.defaultAction)
            }
            .padding(16)
        }
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}
