import Foundation
import Testing
@testable import FeatureRequestKit
import struct FeatureRequestKit.Comment

private typealias SDKComment = Comment

/// One test per endpoint in the API contract: the request the SDK sends (method, path, query,
/// body) and the decoding of the exact payload the server returns (web repo, src/app/api/v1).

@Test func configRoundTrip() async throws {
    let server = StubServer()
    server.on("GET", "config", .json(200, #"{"showBranding":false,"hideVoteCounts":true,"appName":"Acme"}"#))

    let config: BoardConfig = try await server.makeClient().send(.config)

    #expect(config == BoardConfig(showBranding: false, hideVoteCounts: true, appName: "Acme"))
    #expect(server.requests.first?.body?.isEmpty ?? true)
}

@Test func listFeaturesRoundTrip() async throws {
    let server = StubServer()
    server.on("GET", "features", .json(200, featuresPageJSON([featureJSON(id: "f1", upvoteCount: 3, hasVoted: true)], nextCursor: "f1")))

    let page: FeaturesPage = try await server.makeClient().send(.features(sort: "new", limit: 20, cursor: "f0"))

    let request = try #require(server.requests.first)
    #expect(request.method == "GET")
    #expect(request.query == ["sort": "new", "limit": "20", "cursor": "f0"])
    #expect(page.nextCursor == "f1")
    #expect(page.features.first?.upvoteCount == 3)
    #expect(page.features.first?.hasVoted == true)
}

@Test func getFeatureRoundTrip() async throws {
    let server = StubServer()
    server.on("GET", "features/f1", .json(200, featureJSON(id: "f1", status: "in_progress", isFollowing: true, isMine: true)))

    let feature: FeatureRequest = try await server.makeClient().send(.feature(id: "f1"))

    #expect(feature.status == .inProgress)
    #expect(feature.isFollowing && feature.isMine)
}

@Test func createFeatureRoundTrip() async throws {
    let server = StubServer()
    // 201 + Feature without hasVoted / isFollowing / isMine, exactly as createFeatureForApp returns it.
    server.on("POST", "features", .json(201, """
    {"id":"n1","title":"Widgets","description":"On the home screen","status":"open","upvoteCount":0,\
    "commentCount":0,"followerCount":1,"authorDeviceId":"d","authorIsSubscriber":false,\
    "translation":null,"createdAt":"2026-10-11T08:00:00.000Z","updatedAt":"2026-10-11T08:00:00.000Z"}
    """))

    let feature: FeatureRequest = try await server.makeClient().send(
        try .createFeature(title: "Widgets", description: "On the home screen", email: "me@example.com", isSubscriber: false)
    )

    let body = try #require(server.requests.first?.json)
    #expect(body.count == 4)
    #expect(body["title"] as? String == "Widgets")
    #expect(body["description"] as? String == "On the home screen")
    #expect(body["email"] as? String == "me@example.com")
    #expect(body["isSubscriber"] as? Bool == false)
    #expect(feature.followerCount == 1)
    #expect(feature.hasVoted == false)
}

@Test func voteAndUnvoteRoundTrip() async throws {
    let server = StubServer()
    server.on("POST", "features/f1/vote", .json(200, #"{"upvoteCount":5,"hasVoted":true}"#))
    server.on("DELETE", "features/f1/vote", .json(200, #"{"upvoteCount":4,"hasVoted":false}"#))
    let client = server.makeClient()

    let voted: VoteResponse = try await client.send(.vote(featureId: "f1"))
    let unvoted: VoteResponse = try await client.send(.removeVote(featureId: "f1"))

    #expect(voted.upvoteCount == 5 && voted.hasVoted)
    #expect(unvoted.upvoteCount == 4 && !unvoted.hasVoted)
}

@Test func followAndUnfollowRoundTrip() async throws {
    let server = StubServer()
    server.on("POST", "features/f1/follow", .json(200, #"{"following":true}"#))
    server.on("DELETE", "features/f1/follow", .json(200, #"{"following":false}"#))
    let client = server.makeClient()

    let followed: FollowResponse = try await client.send(.follow(featureId: "f1", email: "me@example.com"))
    let unfollowed: FollowResponse = try await client.send(.unfollow(featureId: "f1"))

    #expect(followed.following == true)
    #expect(unfollowed.following == false)
    #expect(server.requests("POST", "features/f1/follow").first?.json as? [String: String] == ["email": "me@example.com"])
}

@Test func listCommentsRoundTrip() async throws {
    let server = StubServer()
    server.on("GET", "features/f1/comments", .json(200, commentsPageJSON([commentJSON(id: "c1", isMine: true)], nextCursor: "c1")))

    let page: CommentsPage = try await server.makeClient().send(.comments(featureId: "f1", limit: 50, cursor: nil))

    #expect(server.requests.first?.query == ["limit": "50"])
    #expect(page.comments.first?.authorName == "App User")
    #expect(page.comments.first?.isMine == true)
    #expect(page.nextCursor == "c1")
}

@Test func createCommentRoundTrip() async throws {
    let server = StubServer()
    server.on("POST", "comments", .json(201, commentJSON(id: "c2", text: "Yes please")))

    let comment: SDKComment = try await server.makeClient().send(try .createComment(featureId: "f1", text: "Yes please", authorName: nil))

    let body = try #require(server.requests.first?.json)
    #expect(body.count == 2)
    #expect(body["featureId"] as? String == "f1")
    #expect(body["text"] as? String == "Yes please")
    #expect(comment.isMine == false)
}

@Test func errorEnvelopeRoundTrip() async {
    let server = StubServer()
    server.on("POST", "comments", .json(429, #"{"error":{"code":"rate_limited","message":"Daily comment limit reached."}}"#))

    await #expect(throws: APIError.rateLimited("Daily comment limit reached.")) {
        let _: SDKComment = try await server.makeClient().send(try .createComment(featureId: "f1", text: "Hi", authorName: nil))
    }
}
