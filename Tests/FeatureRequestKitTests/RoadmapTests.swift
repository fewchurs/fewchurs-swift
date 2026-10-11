import Foundation
import Testing
@testable import FeatureRequestKit

@Test func roadmapIsOptIn() {
    #expect(FeatureSort.visible(showsRoadmap: false) == [.top, .new])
    #expect(FeatureSort.visible(showsRoadmap: true) == [.top, .new, .roadmap])
}

@MainActor
@Test func roadmapTabRequestsApprovedStatusesByTop() async throws {
    let server = StubServer()
    server.on("GET", "features", .json(200, featuresPageJSON([featureJSON(id: "r1", status: "in_progress")])))
    let model = FeatureBoardModel(apiClient: server.makeClient())

    model.sort = .roadmap
    await model.load()

    let request = try #require(server.requests("GET", "features").last)
    #expect(request.query["sort"] == "top")
    #expect(request.query["status"] == "planned,in_progress,done")
    #expect(model.features.map(\.id) == ["r1"])
}

@MainActor
@Test func topAndNewTabsSendNoStatusFilter() async throws {
    let server = StubServer()
    server.on("GET", "features", .json(200, featuresPageJSON([])))
    let model = FeatureBoardModel(apiClient: server.makeClient())
    await model.load()
    #expect(server.requests("GET", "features").last?.query["status"] == nil)
}

/// New requests are "open", so submitting while on Roadmap must not put one there.
@MainActor
@Test func submittingFromRoadmapDoesNotAddToRoadmap() async throws {
    let server = StubServer()
    server.on("GET", "features", .json(200, featuresPageJSON([featureJSON(id: "r1", status: "planned")])))
    server.on("POST", "features", .json(201, featureJSON(id: "new1", status: "open")))
    let model = FeatureBoardModel(apiClient: server.makeClient())
    model.sort = .roadmap
    await model.load()

    try await model.submit(title: "Widgets", description: nil, email: nil)

    #expect(model.features.map(\.id) == ["r1"])
    #expect(model.feature(withId: "new1")?.isMine == true)
}
