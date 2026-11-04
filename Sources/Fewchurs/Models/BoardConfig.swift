import Foundation

struct BoardConfig: Decodable, Equatable, Sendable {
    var showBranding: Bool
    /// The owner turned vote counts off in the dashboard. `/features` still sends
    /// `upvoteCount`, so hiding is the SDK's job. Voting itself keeps working.
    var hideVoteCounts: Bool
    var appName: String?

    init(showBranding: Bool, hideVoteCounts: Bool = false, appName: String?) {
        self.showBranding = showBranding
        self.hideVoteCounts = hideVoteCounts
        self.appName = appName
    }

    /// Used until the real config loads, and kept if the config call fails — a failed
    /// fetch must never hide the board or make branding disappear for a free account.
    static let fallback = BoardConfig(showBranding: true, hideVoteCounts: false, appName: nil)

    private enum CodingKeys: String, CodingKey {
        case showBranding, hideVoteCounts, appName
    }

    /// Every field is optional on the wire, so an older or newer server never breaks the
    /// config call. Missing values fall back to the same safe defaults as `.fallback`.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        showBranding = try container.decodeIfPresent(Bool.self, forKey: .showBranding) ?? true
        hideVoteCounts = try container.decodeIfPresent(Bool.self, forKey: .hideVoteCounts) ?? false
        appName = try container.decodeIfPresent(String.self, forKey: .appName)
    }
}
