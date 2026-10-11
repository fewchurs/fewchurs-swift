import Foundation
import Testing
@testable import FeatureRequestKit

private let decoder: JSONDecoder = APIClient.decoder

@Test func featureRequestDecodesFullPayload() throws {
    let json = """
    {
        "id": "f1",
        "title": "Dark mode",
        "description": "Please add it",
        "status": "open",
        "upvoteCount": 5,
        "hasVoted": true,
        "commentCount": 3,
        "followerCount": 2,
        "isFollowing": true,
        "createdAt": "2026-08-01T10:15:30.123Z"
    }
    """
    let feature = try decoder.decode(FeatureRequest.self, from: Data(json.utf8))
    #expect(feature.id == "f1")
    #expect(feature.upvoteCount == 5)
    #expect(feature.hasVoted == true)
    #expect(feature.commentCount == 3)
    #expect(feature.followerCount == 2)
    #expect(feature.isFollowing == true)
}

@Test func featureRequestDefaultsMissingCountsAndFlags() throws {
    let json = """
    {
        "id": "f2",
        "title": "Widgets",
        "status": "open",
        "createdAt": "2026-08-01T10:15:30.123Z"
    }
    """
    let feature = try decoder.decode(FeatureRequest.self, from: Data(json.utf8))
    #expect(feature.upvoteCount == 0)
    #expect(feature.hasVoted == false)
    #expect(feature.commentCount == 0)
    #expect(feature.followerCount == 0)
    #expect(feature.isFollowing == false)
    #expect(feature.description == nil)
}

@Test func featureRequestThrowsWhenIdIsMissing() {
    let json = """
    {
        "title": "Widgets",
        "status": "open",
        "createdAt": "2026-08-01T10:15:30.123Z"
    }
    """
    #expect(throws: (any Error).self) {
        try decoder.decode(FeatureRequest.self, from: Data(json.utf8))
    }
}

/// `translation` is the owner's dashboard translation, not for end users. Whatever shape it
/// arrives in, the feature decodes and keeps its original title.
@Test func featureIgnoresTranslationInAnyShape() throws {
    let shapes = [
        #"{"lang":"fr","title":"Mode sombre","description":"S'il vous plaît"}"#,
        "null",
        #""unexpected string""#,
    ]
    for shape in shapes {
        let json = featureJSON(id: "f1", title: "Dark mode")
            .replacingOccurrences(of: #""translation":null"#, with: #""translation":\#(shape)"#)
        let feature = try decoder.decode(FeatureRequest.self, from: Data(json.utf8))
        #expect(feature.title == "Dark mode")
        #expect(!String(describing: feature).contains("Mode sombre"))
    }
}
