import Foundation
import Testing
@testable import FeatureRequestKit

@Test func boardConfigDecodesFullPayload() throws {
    let json = """
    { "showBranding": false, "hideVoteCounts": true, "appName": "My App" }
    """
    let config = try JSONDecoder().decode(BoardConfig.self, from: Data(json.utf8))
    #expect(config.showBranding == false)
    #expect(config.hideVoteCounts == true)
    #expect(config.appName == "My App")
}

@Test func boardConfigDecodesVisibleVoteCounts() throws {
    let json = """
    { "showBranding": true, "hideVoteCounts": false, "appName": null }
    """
    let config = try JSONDecoder().decode(BoardConfig.self, from: Data(json.utf8))
    #expect(config.hideVoteCounts == false)
    #expect(config.appName == nil)
}

/// An older server without `hideVoteCounts` (or any other field) must not break the config call.
@Test func boardConfigDefaultsMissingFields() throws {
    let config = try JSONDecoder().decode(BoardConfig.self, from: Data("{}".utf8))
    #expect(config == .fallback)
}

@Test func boardConfigFallbackDefaultsToShowingBrandingAndCounts() {
    #expect(BoardConfig.fallback.showBranding == true)
    #expect(BoardConfig.fallback.hideVoteCounts == false)
    #expect(BoardConfig.fallback.appName == nil)
}

@MainActor
@Test func boardModelPicksUpHiddenVoteCountsFromConfig() async {
    let server = StubServer()
    server.on("GET", "config", .json(200, #"{"showBranding":true,"hideVoteCounts":true,"appName":"Acme"}"#))
    let model = FeatureBoardModel(apiClient: server.makeClient())
    #expect(model.boardConfig.hideVoteCounts == false)

    await model.loadConfig()
    #expect(model.boardConfig.hideVoteCounts == true)
}

@MainActor
@Test func boardModelKeepsCountsVisibleWhenConfigFails() async {
    let server = StubServer()
    server.on("GET", "config", .raw(502, "<html>Bad Gateway</html>"))
    let model = FeatureBoardModel(apiClient: server.makeClient())

    await model.loadConfig()
    #expect(model.boardConfig == .fallback)
}

@MainActor
@Test func navigationTitlePrefersHostThenAppNameThenDefault() async {
    let server = StubServer()
    server.on("GET", "config", .json(200, #"{"showBranding":true,"hideVoteCounts":false,"appName":"Acme"}"#))
    let model = FeatureBoardModel(apiClient: server.makeClient())
    #expect(model.navigationTitle(hostTitle: nil) == "Feature Requests")

    await model.loadConfig()
    #expect(model.navigationTitle(hostTitle: nil) == "Acme")
    #expect(model.navigationTitle(hostTitle: "Ideas") == "Ideas")
}
