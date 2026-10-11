import Foundation
import Testing
@testable import FeatureRequestKit
import struct FeatureRequestKit.Comment

private typealias SDKComment = Comment
private let configJSON = #"{"showBranding":true,"hideVoteCounts":false,"appName":null}"#

@Test func getRetriesOnceAfterABadGateway() async throws {
    let server = StubServer()
    server.on("GET", "config", .raw(502, "<html>Bad Gateway</html>"), .json(200, configJSON))

    let config: BoardConfig = try await server.makeClient().send(.config)

    #expect(config.showBranding == true)
    #expect(server.requests("GET", "config").count == 2)
}

@Test func getRetriesOnceAfterATimeout() async throws {
    let server = StubServer()
    server.on("GET", "features", .failure(.timedOut), .json(200, featuresPageJSON([])))

    let page: FeaturesPage = try await server.makeClient().send(.features(sort: "top", limit: 20, cursor: nil))

    #expect(page.features.isEmpty)
    #expect(server.requests("GET", "features").count == 2)
}

@Test func getGivesUpAfterTheSecondFailure() async {
    let server = StubServer()
    server.on("GET", "config", .raw(504, "Gateway Timeout"))

    await #expect(throws: APIError.server("HTTP 504")) {
        let _: BoardConfig = try await server.makeClient().send(.config)
    }
    #expect(server.requests("GET", "config").count == 2)
}

@Test func getDoesNotRetryAClientError() async {
    let server = StubServer()
    server.on("GET", "config", .json(401, #"{"error":{"code":"invalid_key","message":"Invalid or inactive API key."}}"#))

    await #expect(throws: APIError.invalidKey) {
        let _: BoardConfig = try await server.makeClient().send(.config)
    }
    #expect(server.requests("GET", "config").count == 1)
}

@Test func voteAndFollowAreRetried() async throws {
    let server = StubServer()
    server.on("POST", "features/f1/vote", .failure(.networkConnectionLost), .json(200, #"{"upvoteCount":1,"hasVoted":true}"#))
    server.on("POST", "features/f1/follow", .raw(503, ""), .json(200, #"{"following":true}"#))
    let client = server.makeClient()

    let _: VoteResponse = try await client.send(.vote(featureId: "f1"))
    let _: FollowResponse = try await client.send(.follow(featureId: "f1", email: "me@example.com"))

    #expect(server.requests("POST", "features/f1/vote").count == 2)
    #expect(server.requests("POST", "features/f1/follow").count == 2)
}

/// A retry after a lost response would create the same feature twice.
@Test func creatingAFeatureIsNeverRetried() async throws {
    let server = StubServer()
    server.on("POST", "features", .raw(502, "Bad Gateway"), .json(201, featureJSON(id: "dup")))

    await #expect(throws: APIError.self) {
        let _: FeatureRequest = try await server.makeClient().send(try .createFeature(title: "Widgets", description: nil))
    }
    #expect(server.requests("POST", "features").count == 1)
}

@Test func postingACommentIsNeverRetried() async throws {
    let server = StubServer()
    server.on("POST", "comments", .failure(.timedOut), .json(201, commentJSON(id: "dup")))

    await #expect(throws: APIError.network) {
        let _: SDKComment = try await server.makeClient().send(try .createComment(featureId: "f1", text: "Hi", authorName: nil))
    }
    #expect(server.requests("POST", "comments").count == 1)
}

@Test func onlyCreatesAreNonIdempotent() throws {
    #expect(Endpoint.config.isIdempotent)
    #expect(Endpoint.features(sort: "top", limit: 1, cursor: nil).isIdempotent)
    #expect(Endpoint.feature(id: "f1").isIdempotent)
    #expect(Endpoint.comments(featureId: "f1", limit: 1, cursor: nil).isIdempotent)
    #expect(Endpoint.vote(featureId: "f1").isIdempotent)
    #expect(Endpoint.removeVote(featureId: "f1").isIdempotent)
    #expect(try Endpoint.follow(featureId: "f1", email: "a@b.co").isIdempotent)
    #expect(Endpoint.unfollow(featureId: "f1").isIdempotent)
    #expect(try Endpoint.createFeature(title: "abc", description: nil).isIdempotent == false)
    #expect(try Endpoint.createComment(featureId: "f1", text: "x", authorName: nil).isIdempotent == false)
}

@Test func dedicatedSessionHasAShortTimeoutAndNoCache() {
    let configuration = APIClient.makeSession().configuration
    #expect(configuration.timeoutIntervalForRequest == 15)
    #expect(configuration.urlCache == nil)
    #expect(configuration.requestCachePolicy == .reloadIgnoringLocalCacheData)
}
