import Foundation
import Testing
@testable import FeatureRequestKit

@Test func defaultBaseURLIsCanonicalProductionDomain() {
    #expect(Configuration.defaultBaseURL.absoluteString == "https://www.fewchurs.com/api/v1")
    #expect(FeatureRequestKit.productionBaseURL == Configuration.defaultBaseURL)
}

@Test func subscriberClosureIsReadEachTime() {
    final class Flag: @unchecked Sendable { var value = false }
    let flag = Flag()
    var configuration = Configuration(apiKey: "k", baseURL: Configuration.defaultBaseURL, theme: .system)
    #expect(configuration.isSubscriber?() ?? false == false)

    configuration.isSubscriber = { flag.value }
    #expect(configuration.isSubscriber?() == false)
    flag.value = true
    #expect(configuration.isSubscriber?() == true)
}
