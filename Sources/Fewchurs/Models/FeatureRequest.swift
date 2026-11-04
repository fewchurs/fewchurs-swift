import Foundation

struct FeatureRequest: Identifiable, Decodable, Equatable, Sendable {
    let id: String
    var title: String
    var description: String?
    var status: FeatureStatus
    var upvoteCount: Int
    var hasVoted: Bool
    var commentCount: Int
    var followerCount: Int
    var isFollowing: Bool
    /// This device submitted the request. The server works it out, so the SDK never needs
    /// (and never decodes) `authorDeviceId`, which is another user's device ID.
    var isMine: Bool
    let createdAt: Date

    private enum CodingKeys: String, CodingKey {
        case id, title, description, status, upvoteCount, hasVoted
        case commentCount, followerCount, isFollowing, isMine, createdAt
    }

    init(
        id: String,
        title: String,
        description: String?,
        status: FeatureStatus,
        upvoteCount: Int,
        hasVoted: Bool,
        commentCount: Int,
        followerCount: Int,
        isFollowing: Bool,
        isMine: Bool = false,
        createdAt: Date
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.status = status
        self.upvoteCount = upvoteCount
        self.hasVoted = hasVoted
        self.commentCount = commentCount
        self.followerCount = followerCount
        self.isFollowing = isFollowing
        self.isMine = isMine
        self.createdAt = createdAt
    }

    /// Vote/follow/comment counts and flags default to 0/false when absent, since some
    /// backends return a partial representation on creation (a brand-new feature starts
    /// with no votes, followers, or comments). Every other field must be present — those
    /// can't be safely guessed.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        status = try container.decode(FeatureStatus.self, forKey: .status)
        upvoteCount = try container.decodeIfPresent(Int.self, forKey: .upvoteCount) ?? 0
        hasVoted = try container.decodeIfPresent(Bool.self, forKey: .hasVoted) ?? false
        commentCount = try container.decodeIfPresent(Int.self, forKey: .commentCount) ?? 0
        followerCount = try container.decodeIfPresent(Int.self, forKey: .followerCount) ?? 0
        isFollowing = try container.decodeIfPresent(Bool.self, forKey: .isFollowing) ?? false
        isMine = try container.decodeIfPresent(Bool.self, forKey: .isMine) ?? false
        createdAt = try container.decode(Date.self, forKey: .createdAt)
    }
}
