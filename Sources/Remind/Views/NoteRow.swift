import SwiftUI

struct NoteRow: View {
    let note: Note
    let onComplete: () -> Void
    let onSnooze: () -> Void
    let onEdit: () -> Void
    
    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 12) {
            // Risk Indicator
            Circle()
                .fill(note.risk.color)
                .frame(width: 8, height: 8)
                .shadow(color: note.risk.color.opacity(0.5), radius: 2)

            // Text and Detail
            VStack(alignment: .leading, spacing: 2) {
                Text(note.text)
                    .font(.system(size: 13))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                
                if let due = note.dueDate {
                    Text("Due: \(due.formatted(date: .omitted, time: .shortened))")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Actions - visible on hover or if space permits
            if isHovering {
                HStack(spacing: 4) {
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .font(.system(size: 10))
                    }
                    .buttonStyle(.plain)
                    .help("✏️ Edit")
                    
                    Button(action: onSnooze) {
                        Image(systemName: "clock")
                            .font(.system(size: 10))
                    }
                    .buttonStyle(.plain)
                    .help("💤 Snooze 1h")

                    Button(action: onComplete) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10))
                    }
                    .buttonStyle(.plain)
                    .help("✅ Complete")
                }
                .transition(.opacity)
            }

        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(isHovering ? Color.primary.opacity(0.05) : Color.clear)
        .cornerRadius(6)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
    }
}
