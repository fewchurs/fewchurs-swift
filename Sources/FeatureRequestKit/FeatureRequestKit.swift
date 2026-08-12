import Foundation

public enum FeatureRequestKit {
    static var configuration: Configuration?

    /// Overridable base URL for testing. When set, takes precedence over `Configuration.defaultBaseURL`.
    static var baseURLOverride: URL?

    public static func configure(apiKey: String, theme: FeatureRequestTheme = .system) {
        configuration = Configuration(
            apiKey: apiKey,
            baseURL: baseURLOverride ?? Configuration.defaultBaseURL,
            theme: theme
        )
    }

    public static func identify(userId: String, email: String? = nil) {
        guard configuration != nil else {
            fatalError("FeatureRequestKit.identify(userId:email:) was called before FeatureRequestKit.configure(apiKey:). Call configure() first.")
        }
        configuration?.userId = userId
        configuration?.email = email
    }
}
