import Foundation
import Testing
@testable import Fewchurs

/// identify writes a global, so these run one at a time and restore it.
@Suite(.serialized) struct IdentifyTests {
    @Test func identifyStoresATrimmedEmailAndClearsOnNil() {
        defer { Fewchurs.identify(email: nil) }
        Fewchurs.identify(email: "  me@example.com ")
        #expect(Fewchurs.identifiedEmail == "me@example.com")

        Fewchurs.identify(email: "   ")
        #expect(Fewchurs.identifiedEmail == nil)
    }

    @Test func identifyWorksBeforeConfigure() {
        defer { Fewchurs.identify(email: nil) }
        // Used to fatalError when called before configure.
        Fewchurs.identify(email: "early@example.com")
        #expect(Fewchurs.identifiedEmail == "early@example.com")
    }

    @available(*, deprecated)
    @Test func deprecatedIdentifyForwardsTheEmail() {
        defer { Fewchurs.identify(email: nil) }
        Fewchurs.identify(userId: "u1", email: "me@example.com")
        #expect(Fewchurs.identifiedEmail == "me@example.com")
    }
}
