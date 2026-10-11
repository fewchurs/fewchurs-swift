import Foundation

struct Configuration {
    var apiKey: String
    var baseURL: URL
    var theme: FeatureRequestTheme
    var userId: String?
    var email: String?

    /// The canonical production API. `fewchurs.shop` without `www` answers with a redirect, so
    /// requests go straight to the host that serves them.
    static let defaultBaseURL = URL(string: "https://www.fewchurs.shop/api/v1")!
}
