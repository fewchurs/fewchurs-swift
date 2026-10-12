import Foundation
import Testing
@testable import FeatureRequestKit

@Test func sdkVersionIsSemver() {
    #expect(FeatureRequestKit.sdkVersion == "1.1.2")
    let parts = FeatureRequestKit.sdkVersion.split(separator: ".")
    #expect(parts.count == 3 && parts.allSatisfy { Int($0) != nil })
}

@Test func everyRequestCarriesTheStandardHeaders() async throws {
    let server = StubServer()
    server.on("GET", "config", .json(200, #"{"showBranding":true,"hideVoteCounts":false,"appName":null}"#))
    let _: BoardConfig = try await server.makeClient(apiKey: "fr_live_abc").send(.config)

    let headers = try #require(server.requests.first?.headers)
    #expect(headers["Authorization"] == "Bearer fr_live_abc")
    #expect(headers["X-Device-Id"] == DeviceIdentity.current)
    #expect(headers["Content-Type"] == "application/json")
    #expect(headers["X-Fewchurs-Sdk"] == "swift/\(FeatureRequestKit.sdkVersion)")
    #expect(headers["Accept-Language"] == APIClient.acceptLanguage)
    #expect(headers["Accept-Language"]?.isEmpty == false)
}
