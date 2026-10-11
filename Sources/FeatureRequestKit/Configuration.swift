import Foundation

struct Configuration {
    var apiKey: String
    var baseURL: URL
    var theme: FeatureRequestTheme
    /// Asked at submit time, so a user who subscribes mid-session is reported correctly.
    var isSubscriber: (@Sendable () -> Bool)?

    /// The canonical production API. `fewchurs.shop` without `www` answers with a redirect, so
    /// requests go straight to the host that serves them.
    static let defaultBaseURL = URL(string: "https://www.fewchurs.shop/api/v1")!
}
