import Foundation
import Testing
@testable import FeatureRequestKit

@Test func featureStatusDecodesAllKnownRawValues() throws {
    let cases: [(String, FeatureStatus)] = [
        ("\"open\"", .open),
        ("\"planned\"", .planned),
        ("\"in_progress\"", .inProgress),
        ("\"done\"", .done),
        ("\"declined\"", .declined)
    ]
    for (json, expected) in cases {
        let decoded = try JSONDecoder().decode(FeatureStatus.self, from: Data(json.utf8))
        #expect(decoded == expected)
    }
}

/// A status this SDK version has never heard of must decode, not throw — otherwise adding
/// one status server-side breaks the entire board response in every shipped app.
@Test func featureStatusDecodesUnknownRawValueAsFallback() throws {
    let decoded = try JSONDecoder().decode(FeatureStatus.self, from: Data("\"archived\"".utf8))
    #expect(decoded == .unknown)
}

@Test func unknownAndOpenStatusesShowNoBadge() {
    #expect(FeatureStatus.unknown.showsBadge == false)
    #expect(FeatureStatus.open.showsBadge == false)
    #expect(FeatureStatus.done.showsBadge == true)
}

/// The whole point of the fallback: one unrecognised row must not take the page with it.
@Test func featureListWithUnknownStatusStillDecodes() throws {
    let json = """
    {"features":[
      {"id":"1","title":"Known","status":"planned","createdAt":"2026-01-01T00:00:00Z"},
      {"id":"2","title":"Future","status":"shipped_beta","createdAt":"2026-01-01T00:00:00Z"}
    ],"nextCursor":null}
    """
    let page = try APIClient.decoder.decode(FeaturesPage.self, from: Data(json.utf8))
    #expect(page.features.count == 2)
    #expect(page.features[1].status == .unknown)
}

@Test func featureStatusDisplayNameForInProgress() {
    #expect(FeatureStatus.inProgress.displayName == "In Progress")
}
