import Foundation

struct Comment: Identifiable, Decodable, Equatable, Sendable {
    let id: String
    var text: String
    var authorName: String?
    var isDeveloper: Bool
    /// Written from this device. Only present when the request carried `X-Device-Id`, and
    /// never on the create response, so `postComment` sets it locally. The comment's own
    /// `deviceId` is deliberately not decoded: it is another user's device ID.
    var isMine: Bool
    let createdAt: Date

    private enum CodingKeys: String, CodingKey {
        case id, text, authorName, isDeveloper, isMine, createdAt
    }

    init(id: String, text: String, authorName: String?, isDeveloper: Bool, isMine: Bool = false, createdAt: Date) {
        self.id = id
        self.text = text
        self.authorName = authorName
        self.isDeveloper = isDeveloper
        self.isMine = isMine
        self.createdAt = createdAt
    }

    /// `isDeveloper` and `isMine` default to false when absent — a safe assumption for any
    /// comment a backend doesn't explicitly mark.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        text = try container.decode(String.self, forKey: .text)
        authorName = try container.decodeIfPresent(String.self, forKey: .authorName)
        isDeveloper = try container.decodeIfPresent(Bool.self, forKey: .isDeveloper) ?? false
        isMine = try container.decodeIfPresent(Bool.self, forKey: .isMine) ?? false
        createdAt = try container.decode(Date.self, forKey: .createdAt)
    }
}
