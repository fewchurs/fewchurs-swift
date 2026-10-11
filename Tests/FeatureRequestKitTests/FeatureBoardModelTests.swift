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
