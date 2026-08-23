import Foundation

struct BoardConfig: Decodable, Equatable, Sendable {
    var showBranding: Bool
    var appName: String?

    /// Used until the real config loads, and kept if the config call fails — a failed
    /// fetch must never hide the board or make branding disappear for a free account.
    static let fallback = BoardConfig(showBranding: true, appName: nil)
}
