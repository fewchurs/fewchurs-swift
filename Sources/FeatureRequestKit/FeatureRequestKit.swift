import Foundation

public enum FeatureRequestKit {
    static var configuration: Configuration?

    /// Overridable base URL for testing. When set, takes precedence over the `baseURL` passed
    /// to `configure`.
    static var baseURLOverride: URL?

    /// The production Fewchurs API. This is what `configure` uses unless you pass a `baseURL`.
    public static let productionBaseURL = Configuration.defaultBaseURL

    /// Call once, early in your app's lifecycle, before presenting `FeatureRequestBoardView`.
    ///
    /// - Parameters:
    ///   - apiKey: The publishable key from your Fewchurs dashboard.
    ///   - theme: Colors and corner radius for the board. Defaults to `.system`.
    ///   - baseURL: The API to talk to. Leave it out for production; pass a staging or local
    ///     server (for example `http://localhost:3000/api/v1`) while developing.
    public static func configure(
        apiKey: String,
        theme: FeatureRequestTheme = .system,
        baseURL: URL = FeatureRequestKit.productionBaseURL
    ) {
        configuration = Configuration(
            apiKey: apiKey,
            baseURL: baseURLOverride ?? baseURL,
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
