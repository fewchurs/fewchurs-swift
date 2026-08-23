import Foundation
import Testing
@testable import FeatureRequestKit
// `Comment` collides with Testing.Comment; this scoped import disambiguates it
// from our module even though the module and one of its types share a name.
import struct FeatureRequestKit.Comment

private let decoder: JSONDecoder = APIClient.decoder
private typealias SDKComment = Comment

@Test func commentDecodesFullPayload() throws {
    let json = """
    {
        "id": "c1",
        "text": "Great idea!",
        "authorName": "Jane",
        "isDeveloper": true,
        "createdAt": "2026-08-01T10:15:30.123Z"
    }
    """
    let comment = try decoder.decode(SDKComment.self, from: Data(json.utf8))
    #expect(comment.authorName == "Jane")
    #expect(comment.isDeveloper == true)
}

@Test func commentDefaultsIsDeveloperAndAuthorNameWhenAbsent() throws {
    let json = """
    {
        "id": "c2",
        "text": "Me too!",
        "createdAt": "2026-08-01T10:15:30.123Z"
    }
    """
    let comment = try decoder.decode(SDKComment.self, from: Data(json.utf8))
    #expect(comment.isDeveloper == false)
    #expect(comment.authorName == nil)
}

@Test func commentThrowsWhenTextIsMissing() {
    let json = """
    {
        "id": "c3",
        "createdAt": "2026-08-01T10:15:30.123Z"
    }
    """
    #expect(throws: (any Error).self) {
        try decoder.decode(SDKComment.self, from: Data(json.utf8))
    }
}
