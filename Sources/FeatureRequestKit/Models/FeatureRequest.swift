import Foundation

struct FeatureRequest: Identifiable, Decodable, Equatable, Sendable {
    let id: String
    var title: String
    var description: String?
    var status: FeatureStatus
    var upvoteCount: Int
    var hasVoted: Bool
    let createdAt: Date

    private enum CodingKeys: String, CodingKey {
        case id, title, description, status, upvoteCount, hasVoted, createdAt
    }

    init(id: String, title: String, description: String?, status: FeatureStatus, upvoteCount: Int, hasVoted: Bool, createdAt: Date) {
        self.id = id
        self.title = title
        self.description = description
        self.status = status
        self.upvoteCount = upvoteCount
        self.hasVoted = hasVoted
        self.createdAt = createdAt
    }

    /// `upvoteCount` and `hasVoted` default to 0/false when absent, since some backends
    /// return a partial representation on creation (a brand-new feature has no votes yet).
    /// Every other field must be present — those can't be safely guessed.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        status = try container.decode(FeatureStatus.self, forKey: .status)
        upvoteCount = try container.decodeIfPresent(Int.self, forKey: .upvoteCount) ?? 0
        hasVoted = try container.decodeIfPresent(Bool.self, forKey: .hasVoted) ?? false
        createdAt = try container.decode(Date.self, forKey: .createdAt)
    }
}
