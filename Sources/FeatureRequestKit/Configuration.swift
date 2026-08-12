import Foundation

struct Configuration {
    var apiKey: String
    var baseURL: URL
    var theme: FeatureRequestTheme
    var userId: String?
    var email: String?

    static let defaultBaseURL = URL(string: "https://api.featurerequestkit.com/api/v1")!
}
