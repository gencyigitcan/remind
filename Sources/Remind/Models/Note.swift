import SwiftUI

// Risk levels define urgency and visual priority
enum RiskLevel: Int, Codable, CaseIterable, Identifiable {
    case one = 1
    case two = 2
    case three = 3
    case four = 4
    case five = 5

    var id: Int { rawValue }

    var color: Color {
        switch self {
        case .one: return .green
        case .two: return .yellow
        case .three: return .orange
        case .four: return .red
        case .five: return .purple
        }
    }
    
    var description: String {
        switch self {
        case .one: return "Low Risk"
        case .two: return "Moderate"
        case .three: return "High"
        case .four: return "Urgent"
        case .five: return "Critical"
        }
    }
}

// Status tracks the lifecycle of a note
enum NoteStatus: String, Codable {
    case active
    case completed
    case snoozed
}

// Main Note Model
struct Note: Identifiable, Codable, Equatable {
    let id: UUID
    var text: String
    var risk: RiskLevel
    var status: NoteStatus
    let createdAt: Date
    var completedAt: Date?
    var snoozeUntil: Date?

    init(id: UUID = UUID(), text: String, risk: RiskLevel, status: NoteStatus = .active, createdAt: Date = Date(), completedAt: Date? = nil, snoozeUntil: Date? = nil) {
        self.id = id
        self.text = text
        self.risk = risk
        self.status = status
        self.createdAt = createdAt
        self.completedAt = completedAt
        self.snoozeUntil = snoozeUntil
    }
}

extension Note {
    static var mockData: [Note] {
        [
            Note(text: "Review sprint goals", risk: .three),
            Note(text: "Email the design team", risk: .two),
            Note(text: "Prepare weekly update", risk: .one),
            Note(text: "Urgent bug fix #492", risk: .five)
        ]
    }
}
