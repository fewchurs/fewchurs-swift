import Foundation
import Testing
@testable import FeatureRequestKit

@Test func boardConfigDecodesFullPayload() throws {
    let json = """
    { "showBranding": false, "appName": "My App" }
    """
    let config = try JSONDecoder().decode(BoardConfig.self, from: Data(json.utf8))
    #expect(config.showBranding == false)
    #expect(config.appName == "My App")
}

@Test func boardConfigFallbackDefaultsToShowingBranding() {
    #expect(BoardConfig.fallback.showBranding == true)
    #expect(BoardConfig.fallback.appName == nil)
}
