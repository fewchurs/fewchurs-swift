import SwiftUI
import FeatureRequestKit

@main
struct SampleApp: App {
    init() {
        // 1. Paste the API key from your Fewchurs dashboard (Apps → your app → API key).
        FeatureRequestKit.configure(
            apiKey: "fr_live_paste_your_key_here",
            // Optional: tell Fewchurs which requests come from paying users.
            isSubscriber: { false }
        )

        // Optional: if your app knows the user's email, the board won't have to ask for it.
        // FeatureRequestKit.identify(email: "jane@example.com")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
