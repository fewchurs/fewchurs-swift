import Foundation

struct FeatureRequest: Identifiable, Decodable, Equatable, Sendable {
    let id: String
    var title: String
    var description: String?
    var status: FeatureStatus
    var upvoteCount: Int
    var hasVoted: Bool
    let createdAt: Date
}
