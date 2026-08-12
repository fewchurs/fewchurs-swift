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

@Test func featureStatusFailsToDecodeUnknownRawValue() {
    let json = Data("\"archived\"".utf8)
    #expect(throws: (any Error).self) {
        try JSONDecoder().decode(FeatureStatus.self, from: json)
    }
}

@Test func featureStatusDisplayNameForInProgress() {
    #expect(FeatureStatus.inProgress.displayName == "In Progress")
}
