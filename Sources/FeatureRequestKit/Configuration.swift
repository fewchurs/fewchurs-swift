import Foundation

struct Configuration {
    var apiKey: String
    var baseURL: URL
    var theme: FeatureRequestTheme
    var userId: String?
    var email: String?

    static let defaultBaseURL = URL(string: "http://localhost:3000/api/v1")!
}
