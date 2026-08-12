import Foundation
import Testing
@testable import FeatureRequestKit

private let baseURL = URL(string: "https://api.example.com/api/v1")!

@Test func featuresEndpointBuildsURLWithSortAndLimit() {
    let endpoint = Endpoint.features(sort: "top", limit: 20, cursor: nil)
    let url = endpoint.url(relativeTo: baseURL)
    #expect(url?.absoluteString.hasPrefix("https://api.example.com/api/v1/features?") == true)
    let components = URLComponents(url: url!, resolvingAgainstBaseURL: false)
    let items = Dictionary(uniqueKeysWithValues: (components?.queryItems ?? []).map { ($0.name, $0.value) })
    #expect(items["sort"] == "top")
    #expect(items["limit"] == "20")
    #expect(items["cursor"] == nil)
}

@Test func featuresEndpointIncludesCursorWhenProvided() {
    let endpoint = Endpoint.features(sort: "new", limit: 10, cursor: "abc123")
    let url = endpoint.url(relativeTo: baseURL)
    let components = URLComponents(url: url!, resolvingAgainstBaseURL: false)
    let items = Dictionary(uniqueKeysWithValues: (components?.queryItems ?? []).map { ($0.name, $0.value) })
    #expect(items["cursor"] == "abc123")
}

@Test func voteEndpointBuildsExpectedPathAndMethod() {
    let endpoint = Endpoint.vote(featureId: "feature-42")
    let url = endpoint.url(relativeTo: baseURL)
    #expect(url?.absoluteString == "https://api.example.com/api/v1/features/feature-42/vote")
    #expect(endpoint.method == .post)
}

@Test func removeVoteEndpointUsesDeleteMethod() {
    let endpoint = Endpoint.removeVote(featureId: "feature-42")
    #expect(endpoint.method == .delete)
    #expect(endpoint.url(relativeTo: baseURL)?.absoluteString == "https://api.example.com/api/v1/features/feature-42/vote")
}

@Test func createFeatureEndpointEncodesBodyAndOmitsNilDescription() throws {
    let endpoint = try Endpoint.createFeature(title: "Dark mode", description: nil)
    #expect(endpoint.method == .post)
    let json = try JSONSerialization.jsonObject(with: endpoint.body!) as! [String: Any]
    #expect(json["title"] as? String == "Dark mode")
    #expect(json["description"] == nil)
}

@Test func createFeatureEndpointIncludesDescriptionWhenPresent() throws {
    let endpoint = try Endpoint.createFeature(title: "Dark mode", description: "Please add it")
    let json = try JSONSerialization.jsonObject(with: endpoint.body!) as! [String: Any]
    #expect(json["description"] as? String == "Please add it")
}
