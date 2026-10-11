import Foundation
import Testing
@testable import FeatureRequestKit

@Test func featureEndpointBuildsPath() {
    let endpoint = Endpoint.feature(id: "f42")
    #expect(endpoint.method == .get)
    #expect(endpoint.url(relativeTo: URL(string: "https://api.example.com/api/v1")!)?.absoluteString == "https://api.example.com/api/v1/features/f42")
}

/// A deep link to a request that's on no loaded page used to show "Request Not Found".
@MainActor
@Test func detailFetchesAFeatureMissingFromTheBoardCache() async throws {
    let server = StubServer()
    server.on("GET", "features/deep1", .json(200, featureJSON(id: "deep1", title: "Offline mode", upvoteCount: 7, hasVoted: true)))
    let client = server.makeClient()
    let board = FeatureBoardModel(apiClient: client)
    let detail = FeatureDetailModel(featureId: "deep1", boardModel: board, apiClient: client)
    #expect(detail.feature == nil)

    await detail.loadFeatureIfNeeded()

    let feature = try #require(detail.feature)
    #expect(feature.title == "Offline mode")
    #expect(feature.hasVoted == true)
    #expect(detail.featureIsMissing == false)

    // Votes on a standalone feature work like any other.
    server.on("DELETE", "features/deep1/vote", .json(200, #"{"upvoteCount":6,"hasVoted":false}"#))
    await detail.toggleVote()
    #expect(detail.feature?.upvoteCount == 6)
    #expect(detail.feature?.hasVoted == false)
}

@MainActor
@Test func detailDoesNotRefetchACachedFeature() async {
    let server = StubServer()
    server.on("GET", "features", .json(200, featuresPageJSON([featureJSON(id: "f1")])))
    let client = server.makeClient()
    let board = FeatureBoardModel(apiClient: client)
    await board.load()
    let detail = FeatureDetailModel(featureId: "f1", boardModel: board, apiClient: client)

    await detail.loadFeatureIfNeeded()
    #expect(server.requests("GET", "features/f1").isEmpty)
}

@MainActor
@Test func detailRefreshUpdatesTheBoardCopy() async throws {
    let server = StubServer()
    server.on("GET", "features", .json(200, featuresPageJSON([featureJSON(id: "f1", status: "open", upvoteCount: 1)])))
    server.on("GET", "features/f1", .json(200, featureJSON(id: "f1", status: "planned", upvoteCount: 9)))
    server.on("GET", "features/f1/comments", .json(200, commentsPageJSON([commentJSON(id: "c1")])))
    let client = server.makeClient()
    let board = FeatureBoardModel(apiClient: client)
    await board.load()
    let detail = FeatureDetailModel(featureId: "f1", boardModel: board, apiClient: client)

    await detail.refresh()

    #expect(board.features.first?.status == .planned)
    #expect(board.features.first?.upvoteCount == 9)
    #expect(detail.comments.map(\.id) == ["c1"])
}

@MainActor
@Test func detailReportsAMissingFeature() async {
    let server = StubServer()
    server.on("GET", "features/gone", .json(404, #"{"error":{"code":"not_found","message":"Feature not found."}}"#))
    let client = server.makeClient()
    let detail = FeatureDetailModel(featureId: "gone", boardModel: FeatureBoardModel(apiClient: client), apiClient: client)

    await detail.loadFeatureIfNeeded()
    #expect(detail.featureIsMissing == true)
    #expect(detail.feature == nil)
}
