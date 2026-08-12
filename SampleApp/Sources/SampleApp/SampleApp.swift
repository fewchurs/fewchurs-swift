import SwiftUI
import FeatureRequestKit

@main
struct SampleApp: App {
    init() {
        FeatureRequestKit.configure(apiKey: "fr_live_sample_key")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
