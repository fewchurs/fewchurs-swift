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
    ///   - isSubscriber: Optional. Return `true` when the current user pays for your app. It is
    ///     called each time a request is submitted, and the answer is shown to you in the
    ///     dashboard next to that request so you can weigh paying users' ideas.
    public static func configure(
        apiKey: String,
        theme: FeatureRequestTheme = .system,
        baseURL: URL = FeatureRequestKit.productionBaseURL,
        isSubscriber: (@Sendable () -> Bool)? = nil
    ) {
        configuration = Configuration(
            apiKey: apiKey,
            baseURL: baseURLOverride ?? baseURL,
            theme: theme,
            isSubscriber: isSubscriber
        )
    }

    /// What the host's `isSubscriber` closure says right now, or `false` without one.
    static var currentUserIsSubscriber: Bool {
        configuration?.isSubscriber?() ?? false
    }

    /// The signed-in user's email, if the host told us. Kept apart from `configuration` so
    /// `identify` and `configure` can be called in either order.
    static var identifiedEmail: String?

    /// Tells the board who is signed in to your app, so they aren't asked for their email.
    ///
    /// The email pre-fills the "Email (optional)" field when submitting a request and is used
    /// to follow a request with one tap. If the user typed a different email into the board
    /// before, that one wins. Pass `nil` when the user signs out.
    public static func identify(email: String?) {
        let trimmed = email?.trimmingCharacters(in: .whitespacesAndNewlines)
        identifiedEmail = (trimmed?.isEmpty ?? true) ? nil : trimmed
    }

    @available(*, deprecated, message: "The Fewchurs API has no notion of a user ID: votes and follows belong to the device, so userId was never sent anywhere. Use identify(email:) instead.")
    public static func identify(userId: String, email: String? = nil) {
        identify(email: email)
    }
}
