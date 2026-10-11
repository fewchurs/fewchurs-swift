import Foundation
import Testing
@testable import FeatureRequestKit

@Test func defaultBaseURLIsCanonicalProductionDomain() {
    #expect(Configuration.defaultBaseURL.absoluteString == "https://www.fewchurs.shop/api/v1")
    #expect(FeatureRequestKit.productionBaseURL == Configuration.defaultBaseURL)
}
