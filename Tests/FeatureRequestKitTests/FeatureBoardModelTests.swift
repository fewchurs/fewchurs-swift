import Foundation
import Testing
@testable import FeatureRequestKit

@MainActor
private func loadedBoard(_ server: StubServer, features: [String]) async -> FeatureBoardModel {
    server.on("GET", "features", .json(200, featuresPageJSON(features)))
    let model = FeatureBoardModel(apiClient: server.makeClient())
    await model.load()
    return model
}

@MainActor
@Test func followSucceedsWithRealServerPayload() async throws {
    let server = StubServer()
    let model = await loadedBoard(server, features: [featureJSON(id: "f1", followerCount: 2)])
    server.on("POST", "features/f1/follow", .json(200, #"{"following":true}"#))

    await model.toggleFollow(try #require(model.feature(withId: "f1")), email: "me@example.com")

    let feature = try #require(model.feature(withId: "f1"))
    #expect(feature.isFollowing == true)
    #expect(feature.followerCount == 3)
    #expect(model.errorMessage == nil)
    #expect(server.requests("POST", "features/f1/follow").first?.json?["email"] as? String == "me@example.com")
}

@MainActor
@Test func unfollowSucceedsWithRealServerPayload() async throws {
    let server = StubServer()
    let model = await loadedBoard(server, features: [featureJSON(id: "f1", followerCount: 3, isFollowing: true)])
    server.on("DELETE", "features/f1/follow", .json(200, #"{"following":false}"#))

    await model.toggleFollow(try #require(model.feature(withId: "f1")), email: nil)

    let feature = try #require(model.feature(withId: "f1"))
    #expect(feature.isFollowing == false)
    #expect(feature.followerCount == 2)
    #expect(model.errorMessage == nil)
}

@MainActor
@Test func followRollsBackWhenTheServerFails() async throws {
    let server = StubServer()
    let model = await loadedBoard(server, features: [featureJSON(id: "f1", followerCount: 2)])
    server.on("POST", "features/f1/follow", .json(404, #"{"error":{"code":"not_found","message":"Feature not found."}}"#))

    await model.toggleFollow(try #require(model.feature(withId: "f1")), email: "me@example.com")

    let feature = try #require(model.feature(withId: "f1"))
    #expect(feature.isFollowing == false)
    #expect(feature.followerCount == 2)
    #expect(model.errorMessage != nil)
}

@MainActor
@Test func voteUsesServerCountAndRollsBackOnFailure() async throws {
    let server = StubServer()
    let model = await loadedBoard(server, features: [featureJSON(id: "f1", upvoteCount: 4)])
    server.on("POST", "features/f1/vote", .json(200, #"{"upvoteCount":10,"hasVoted":true}"#))

    await model.toggleVote(try #require(model.feature(withId: "f1")))
    #expect(model.feature(withId: "f1")?.upvoteCount == 10)
    #expect(model.feature(withId: "f1")?.hasVoted == true)

    server.on("DELETE", "features/f1/vote", .json(500, #"{"error":{"code":"internal","message":"Failed to update vote."}}"#))
    await model.toggleVote(try #require(model.feature(withId: "f1")))
    #expect(model.feature(withId: "f1")?.upvoteCount == 10)
    #expect(model.feature(withId: "f1")?.hasVoted == true)
    #expect(model.errorMessage != nil)
}

/// The create response from the server: no hasVoted/isFollowing/isMine, followerCount 1
/// because the server already followed on the user's behalf.
private let createdFeatureJSON = """
{"id":"new1","title":"Widgets","description":"","status":"open","upvoteCount":0,\
"commentCount":0,"followerCount":1,"authorDeviceId":"this-device","authorIsSubscriber":true,\
"translation":null,"createdAt":"2026-10-01T10:00:00.000Z","updatedAt":"2026-10-01T10:00:00.000Z"}
"""

@MainActor
@Test func submitWithEmailIsOneRequestAndMarksTheFeature() async throws {
    let server = StubServer()
    let model = await loadedBoard(server, features: [featureJSON(id: "f1")])
    server.on("POST", "features", .json(201, createdFeatureJSON))

    try await model.submit(title: "Widgets", description: "  ", email: " me@example.com ", isSubscriber: true)

    #expect(server.requests("POST", "features").count == 1)
    #expect(server.requests.filter { $0.path.hasSuffix("/follow") }.isEmpty)
    let body = try #require(server.requests("POST", "features").first?.json)
    #expect(body["email"] as? String == "me@example.com")
    #expect(body["isSubscriber"] as? Bool == true)
    #expect(body["description"] == nil)

    let created = try #require(model.feature(withId: "new1"))
    #expect(model.features.first?.id == "new1")
    #expect(created.isFollowing == true)
    #expect(created.followerCount == 1)
    #expect(created.isMine == true)
    #expect(created.hasVoted == false)
}

@MainActor
@Test func submitWithoutEmailIsNotFollowing() async throws {
    let server = StubServer()
    let model = await loadedBoard(server, features: [])
    server.on("POST", "features", .json(201, createdFeatureJSON.replacingOccurrences(of: #""followerCount":1"#, with: #""followerCount":0"#)))

    try await model.submit(title: "Widgets", description: nil, email: nil)

    let body = try #require(server.requests("POST", "features").first?.json)
    #expect(body["email"] == nil)
    #expect(body["isSubscriber"] as? Bool == false)
    #expect(model.feature(withId: "new1")?.isFollowing == false)
    #expect(model.feature(withId: "new1")?.isMine == true)
}

@MainActor
@Test func submitSurfacesRateLimit() async throws {
    let server = StubServer()
    let model = await loadedBoard(server, features: [])
    server.on("POST", "features", .json(429, #"{"error":{"code":"rate_limited","message":"Daily submission limit reached."}}"#))

    await #expect(throws: APIError.self) {
        try await model.submit(title: "Widgets", description: nil, email: nil)
    }
    #expect(model.features.isEmpty)
}
