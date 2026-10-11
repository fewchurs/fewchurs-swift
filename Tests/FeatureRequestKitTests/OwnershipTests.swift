import Foundation
import Testing
@testable import FeatureRequestKit
import struct FeatureRequestKit.Comment

private typealias SDKComment = Comment

@Test func featureDecodesIsMine() throws {
    let feature = try APIClient.decoder.decode(FeatureRequest.self, from: Data(featureJSON(id: "f1", isMine: true).utf8))
    #expect(feature.isMine == true)
}

@Test func featureDefaultsIsMineWhenAbsent() throws {
    let json = #"{"id":"f1","title":"Widgets","status":"open","createdAt":"2026-08-01T10:15:30.123Z"}"#
    let feature = try APIClient.decoder.decode(FeatureRequest.self, from: Data(json.utf8))
    #expect(feature.isMine == false)
}

@Test func commentDecodesIsMineAndDefaultsWhenAbsent() throws {
    let mine = try APIClient.decoder.decode(SDKComment.self, from: Data(commentJSON(id: "c1", isMine: true).utf8))
    #expect(mine.isMine == true)
    let unknown = try APIClient.decoder.decode(SDKComment.self, from: Data(commentJSON(id: "c2").utf8))
    #expect(unknown.isMine == false)
}

/// Other users' device IDs arrive in every payload. The SDK must not keep them anywhere.
@Test func otherUsersDeviceIdsAreNeverStored() throws {
    let feature = try APIClient.decoder.decode(FeatureRequest.self, from: Data(featureJSON(id: "f1").utf8))
    let comment = try APIClient.decoder.decode(SDKComment.self, from: Data(commentJSON(id: "c1").utf8))
    let featureFields = Mirror(reflecting: feature).children.compactMap(\.label)
    let commentFields = Mirror(reflecting: comment).children.compactMap(\.label)
    #expect(!featureFields.contains("authorDeviceId"))
    #expect(!commentFields.contains("deviceId"))
    #expect(!String(describing: feature).contains("someone-elses-device"))
    #expect(!String(describing: comment).contains("someone-elses-device"))
}

@MainActor
@Test func postedCommentIsMarkedMineLocally() async throws {
    let server = StubServer()
    server.on("GET", "features", .json(200, featuresPageJSON([featureJSON(id: "f1")])))
    // The create response omits isMine, exactly like the server.
    server.on("POST", "comments", .json(201, commentJSON(id: "c9", text: "Me too")))
    let client = server.makeClient()
    let board = FeatureBoardModel(apiClient: client)
    await board.load()
    let detail = FeatureDetailModel(featureId: "f1", boardModel: board, apiClient: client)

    let posted = await detail.postComment(text: "  Me too  ", authorName: "Sam")

    #expect(posted == true)
    #expect(detail.comments.last?.isMine == true)
    #expect(board.feature(withId: "f1")?.commentCount == 1)
    let body = try #require(server.requests("POST", "comments").first?.json)
    #expect(body["featureId"] as? String == "f1")
    #expect(body["text"] as? String == "Me too")
    #expect(body["authorName"] as? String == "Sam")
}
