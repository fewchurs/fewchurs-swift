import Foundation
import Testing
@testable import FeatureRequestKit

/// The manifest has to ship inside the package's resource bundle, or App Store Connect won't
/// see it when an app that embeds the SDK is submitted.
@Test func privacyManifestIsBundledAndDeclaresNoTracking() throws {
    let bundle = Bundle.module
    let url = try #require(bundle.url(forResource: "PrivacyInfo", withExtension: "xcprivacy"))
    let plist = try #require(NSDictionary(contentsOf: url) as? [String: Any])
    #expect(plist["NSPrivacyTracking"] as? Bool == false)
    #expect((plist["NSPrivacyTrackingDomains"] as? [String])?.isEmpty == true)

    let collected = (plist["NSPrivacyCollectedDataTypes"] as? [[String: Any]]) ?? []
    let types = Set(collected.compactMap { $0["NSPrivacyCollectedDataType"] as? String })
    #expect(types == [
        "NSPrivacyCollectedDataTypeOtherUserContent",
        "NSPrivacyCollectedDataTypeEmailAddress",
        "NSPrivacyCollectedDataTypeDeviceID",
    ])
    #expect(collected.allSatisfy { $0["NSPrivacyCollectedDataTypeTracking"] as? Bool == false })
}
