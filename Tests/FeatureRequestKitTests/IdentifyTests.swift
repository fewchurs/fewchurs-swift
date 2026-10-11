import Foundation
import Testing
@testable import FeatureRequestKit

/// identify writes a global, so these run one at a time and restore it.
@Suite(.serialized) struct IdentifyTests {
    @Test func identifyStoresATrimmedEmailAndClearsOnNil() {
        defer { FeatureRequestKit.identify(email: nil) }
        FeatureRequestKit.identify(email: "  me@example.com ")
        #expect(FeatureRequestKit.identifiedEmail == "me@example.com")

        FeatureRequestKit.identify(email: "   ")
        #expect(FeatureRequestKit.identifiedEmail == nil)
    }

    @Test func identifyWorksBeforeConfigure() {
        defer { FeatureRequestKit.identify(email: nil) }
        // Used to fatalError when called before configure.
        FeatureRequestKit.identify(email: "early@example.com")
        #expect(FeatureRequestKit.identifiedEmail == "early@example.com")
    }

    @available(*, deprecated)
    @Test func deprecatedIdentifyForwardsTheEmail() {
        defer { FeatureRequestKit.identify(email: nil) }
        FeatureRequestKit.identify(userId: "u1", email: "me@example.com")
        #expect(FeatureRequestKit.identifiedEmail == "me@example.com")
    }
}
