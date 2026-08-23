import Foundation

struct Comment: Identifiable, Decodable, Equatable, Sendable {
    let id: String
    var text: String
    var authorName: String?
    var isDeveloper: Bool
    let createdAt: Date

    private enum CodingKeys: String, CodingKey {
        case id, text, authorName, isDeveloper, createdAt
    }

    init(id: String, text: String, authorName: String?, isDeveloper: Bool, createdAt: Date) {
        self.id = id
        self.text = text
        self.authorName = authorName
        self.isDeveloper = isDeveloper
        self.createdAt = createdAt
    }

    /// `isDeveloper` defaults to false when absent — a safe assumption for any comment
    /// a backend doesn't explicitly mark as coming from the developer.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        text = try container.decode(String.self, forKey: .text)
        authorName = try container.decodeIfPresent(String.self, forKey: .authorName)
        isDeveloper = try container.decodeIfPresent(Bool.self, forKey: .isDeveloper) ?? false
        createdAt = try container.decode(Date.self, forKey: .createdAt)
    }
}
