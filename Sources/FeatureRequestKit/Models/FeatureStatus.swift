import SwiftUI

enum FeatureStatus: String, Codable, Sendable, Equatable {
    case open
    case planned
    case inProgress = "in_progress"
    case done
    case declined
    /// Any status this version of the SDK doesn't know about. Without this, a single new
    /// status added server-side would throw during decoding and take down the whole board
    /// response, not just the one row — every already-shipped app, all at once.
    case unknown

    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = FeatureStatus(rawValue: raw) ?? .unknown
    }

    /// `open` is the default state and carries no information worth a badge; `unknown`
    /// has no name this version can render honestly. Both stay unlabelled.
    var showsBadge: Bool {
        self != .open && self != .unknown
    }

    var displayName: String {
        switch self {
        case .open: return "Open"
        case .planned: return "Planned"
        case .inProgress: return "In Progress"
        case .done: return "Done"
        case .declined: return "Declined"
        case .unknown: return ""
        }
    }

    var color: Color {
        switch self {
        case .open: return .secondary
        case .planned: return .blue
        case .inProgress: return .orange
        case .done: return .green
        case .declined: return .red
        case .unknown: return .secondary
        }
    }
}
