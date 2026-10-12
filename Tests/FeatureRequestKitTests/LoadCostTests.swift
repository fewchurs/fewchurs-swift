import Foundation
import Testing
@testable import FeatureRequestKit

/// Every request costs database reads on the server, so these pin how much the board asks for.

@MainActor
@Test func boardRequestsSmallPages() async throws {
    let server = StubServer()
    server.on("GET", "features", .json(200, featuresPageJSON([])))
    let model = FeatureBoardModel(apiClient: server.makeClient())

    await model.load()

    #expect(server.requests("GET", "features").first?.query["limit"] == "15")
}

@MainActor
@Test func commentsRequestSmallPages() async throws {
    let server = StubServer()
    server.on("GET", "features/f1/comments", .json(200, commentsPageJSON([])))
    let client = server.makeClient()
    let detail = FeatureDetailModel(featureId: "f1", boardModel: FeatureBoardModel(apiClient: client), apiClient: client)

    await detail.loadComments()

    #expect(server.requests("GET", "features/f1/comments").first?.query["limit"] == "20")
}

/// Reopening the board within the cache lifetime shows what's loaded and costs nothing.
@MainActor
@Test func reopeningTheBoardDoesNotRefetch() async {
    let server = StubServer()
    server.on("GET", "features", .json(200, featuresPageJSON([featureJSON(id: "f1")])))
    server.on("GET", "config", .json(200, #"{"showBranding":true,"hideVoteCounts":false,"appName":null}"#))
    let model = FeatureBoardModel(apiClient: server.makeClient())

    await model.load()
    await model.loadConfig()
    await model.load()
    await model.loadConfig()

    #expect(server.requests("GET", "features").count == 1)
    #expect(server.requests("GET", "config").count == 1)
    #expect(model.features.map(\.id) == ["f1"])
}

/// Pull to refresh reloads config, so a dashboard change (e.g. hiding counts) shows at once.
@MainActor
@Test func forcedConfigLoadBypassesTheCache() async {
    let server = StubServer()
    server.on(
        "GET", "config",
        .json(200, #"{"showBranding":true,"hideVoteCounts":false,"appName":null}"#),
        .json(200, #"{"showBranding":true,"hideVoteCounts":true,"appName":null}"#)
    )
    let model = FeatureBoardModel(apiClient: server.makeClient())

    await model.loadConfig()
    await model.loadConfig(force: true)

    #expect(server.requests("GET", "config").count == 2)
    #expect(model.boardConfig.hideVoteCounts == true)
}

@MainActor
@Test func nextPageStartsLoadingNearTheEnd() async {
    let server = StubServer()
    let ids = (1...15).map { "f\($0)" }
    server.on("GET", "features", .json(200, featuresPageJSON(ids.map { featureJSON(id: $0) }, nextCursor: "f15")))
    let model = FeatureBoardModel(apiClient: server.makeClient())
    await model.load()

    #expect(model.shouldLoadMore(after: "f10") == false)
    #expect(model.shouldLoadMore(after: "f11") == true)
    #expect(model.shouldLoadMore(after: "f15") == true)
    #expect(model.shouldLoadMore(after: "missing") == false)
}
