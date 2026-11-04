import Foundation
import Testing
@testable import Fewchurs

private let wrongAppJSON = #"{"error":{"code":"wrong_app","message":"This API key is not set up for com.other.app. Add it to your app in the Fewchurs dashboard."}}"#
private let wrongAppMessage = "This API key is not set up for com.other.app. Add it to your app in the Fewchurs dashboard."

@Test func appIdIsTheBundleIdentifier() throws {
    let appId = try #require(APIClient.appId)
    #expect(appId == Bundle.main.bundleIdentifier)
    #expect(!appId.isEmpty)
}

@Test func everyEndpointSendsTheAppId() async throws {
    let server = StubServer()
    let client = server.makeClient()
    let endpoints: [Endpoint] = [
        .config,
        .features(sort: "top", limit: 15, cursor: nil),
        .feature(id: "f1"),
        try .createFeature(title: "Widgets", description: nil),
        .vote(featureId: "f1"),
        .removeVote(featureId: "f1"),
        try .follow(featureId: "f1", email: "me@example.com"),
        .unfollow(featureId: "f1"),
        .comments(featureId: "f1", limit: 20, cursor: nil),
        try .createComment(featureId: "f1", text: "Nice", authorName: nil)
    ]

    for endpoint in endpoints {
        let _: BoardConfig? = try? await client.send(endpoint)
    }

    let requests = server.requests
    #expect(requests.count == endpoints.count)
    for request in requests {
        #expect(request.headers["X-Fewchurs-App-Id"] == APIClient.appId)
    }
}

@Test func wrongAppMapsToInvalidKeyWithTheServerMessage() {
    let error = APIError.from(code: "wrong_app", message: wrongAppMessage, statusCode: 403)
    #expect(error == .invalidKey(wrongAppMessage))
    #expect(error.debugDetail == wrongAppMessage)
    #expect(error.userMessage == APIError.invalidKey("").userMessage)
}

@Test func wrongAppIsNeverRetried() async {
    let server = StubServer()
    server.on("GET", "config", .json(403, wrongAppJSON))

    await #expect(throws: APIError.invalidKey(wrongAppMessage)) {
        let _: BoardConfig = try await server.makeClient().send(.config)
    }
    #expect(server.requests("GET", "config").count == 1)
}

@Test func wrongAppOnACreateIsNotRetried() async {
    let server = StubServer()
    server.on("POST", "features", .json(403, wrongAppJSON))

    await #expect(throws: APIError.invalidKey(wrongAppMessage)) {
        let _: FeatureRequest = try await server.makeClient().send(try .createFeature(title: "Widgets", description: nil))
    }
    #expect(server.requests("POST", "features").count == 1)
}
