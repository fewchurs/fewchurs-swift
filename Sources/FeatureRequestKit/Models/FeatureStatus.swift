import SwiftUI

enum FeatureStatus: String, Codable, Sendable, Equatable {
    case open
    case planned
    case inProgress = "in_progress"
    case done
    case declined

    var displayName: String {
        switch self {
        case .open: return "Open"
        case .planned: return "Planned"
        case .inProgress: return "In Progress"
        case .done: return "Done"
        case .declined: return "Declined"
        }
    }

    var color: Color {
        switch self {
        case .open: return .secondary
        case .planned: return .blue
        case .inProgress: return .orange
        case .done: return .green
        case .declined: return .red
        }
    }
}
