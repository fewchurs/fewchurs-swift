import Foundation
import Testing
@testable import FeatureRequestKit

@MainActor
private func detail(on server: StubServer) -> FeatureDetailModel {
    let client = server.makeClient()
    return FeatureDetailModel(featureId: "f1", boardModel: FeatureBoardModel(apiClient: client), apiClient: client)
}

/// A first page of only-deleted comments used to read as "No comments yet" with no way on.
@MainActor
@Test func commentsSkipAnEmptyFirstPage() async {
    let server = StubServer()
    server.on(
        "GET", "features/f1/comments",
        .json(200, commentsPageJSON([], nextCursor: "p1")),
        .json(200, commentsPageJSON([], nextCursor: "p2")),
        .json(200, commentsPageJSON([commentJSON(id: "c1")], nextCursor: nil))
    )
    let model = detail(on: server)

    await model.loadComments()

    #expect(model.comments.map(\.id) == ["c1"])
    let cursors = server.requests("GET", "features/f1/comments").map { $0.query["cursor"] }
    #expect(cursors == [nil, "p1", "p2"])
}

@MainActor
@Test func commentsSkipAnEmptyLaterPage() async {
    let server = StubServer()
    server.on(
        "GET", "features/f1/comments",
        .json(200, commentsPageJSON([commentJSON(id: "c1")], nextCursor: "p1")),
        .json(200, commentsPageJSON([], nextCursor: "p2")),
        .json(200, commentsPageJSON([commentJSON(id: "c2")], nextCursor: nil))
    )
    let model = detail(on: server)
    await model.loadComments()

    await model.loadMoreComments()

    #expect(model.comments.map(\.id) == ["c1", "c2"])
}

@MainActor
@Test func emptyPageSkippingIsCapped() async {
    let server = StubServer()
    server.on("GET", "features/f1/comments", .json(200, commentsPageJSON([], nextCursor: "again")))
    let model = detail(on: server)

    await model.loadComments()

    #expect(server.requests("GET", "features/f1/comments").count == 1 + Paging.maxEmptyPagesSkipped)
    #expect(model.comments.isEmpty)
}

@MainActor
@Test func featuresSkipAnEmptyPage() async {
    let server = StubServer()
    server.on(
        "GET", "features",
        .json(200, featuresPageJSON([featureJSON(id: "f1")], nextCursor: "p1")),
        .json(200, featuresPageJSON([], nextCursor: "p2")),
        .json(200, featuresPageJSON([featureJSON(id: "f2")], nextCursor: nil))
    )
    let model = FeatureBoardModel(apiClient: server.makeClient())
    await model.load()

    await model.loadMore()

    #expect(model.features.map(\.id) == ["f1", "f2"])
}
