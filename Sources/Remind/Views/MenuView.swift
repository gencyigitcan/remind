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
                
                Button(action: { showingAddNote.toggle() }) {
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
            if showingAddNote {
                AddNoteView(
                    text: $newNoteText,
                    risk: $newNoteRisk,
                    hasDueDate: $hasDueDate,
                    dueDate: $newNoteDueDate,
                    onSave: {
                        let finalDate = hasDueDate ? newNoteDueDate : nil
                        if store.addNote(newNoteText, risk: newNoteRisk, dueDate: finalDate) {
                            newNoteText = ""
                            hasDueDate = false
                            showingAddNote = false
                        }
                    },
                    onCancel: {
                        showingAddNote = false
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
                        Toggle("Launch at Login", isOn: $launchWrapper.isEnabled)
                    } else {
                        Text("Update macOS to enable Launch at Login")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Toggle("Show Active Count", isOn: $store.showCountOnly)
                    Divider()
                    Button("Quit") {
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
    var onSave: () -> Void
    var onCancel: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("New Reminder")
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
                Toggle("Set Time", isOn: $hasDueDate)
                    .toggleStyle(.switch)
                    .labelsHidden()
                    .controlSize(.mini)
                
                if hasDueDate {
                    DatePicker("", selection: $dueDate, displayedComponents: [.hourAndMinute])
                        .labelsHidden()
                }
                Spacer()
            }

            HStack {
                Button("Cancel", action: onCancel)
                Spacer()
                Button("Add Note", action: onSave)
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
