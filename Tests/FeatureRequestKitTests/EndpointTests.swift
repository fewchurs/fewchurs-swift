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

@Test func followEndpointEncodesEmailAndUsesPost() throws {
    let endpoint = try Endpoint.follow(featureId: "feature-42", email: "me@example.com")
    #expect(endpoint.method == .post)
    #expect(endpoint.url(relativeTo: baseURL)?.absoluteString == "https://api.example.com/api/v1/features/feature-42/follow")
    let json = try JSONSerialization.jsonObject(with: endpoint.body!) as! [String: Any]
    #expect(json["email"] as? String == "me@example.com")
}

@Test func unfollowEndpointUsesDeleteMethod() {
    let endpoint = Endpoint.unfollow(featureId: "feature-42")
    #expect(endpoint.method == .delete)
    #expect(endpoint.url(relativeTo: baseURL)?.absoluteString == "https://api.example.com/api/v1/features/feature-42/follow")
}

@Test func commentsEndpointBuildsURLWithLimitAndCursor() {
    let endpoint = Endpoint.comments(featureId: "feature-42", limit: 50, cursor: "c9")
    let url = endpoint.url(relativeTo: baseURL)
    #expect(url?.absoluteString.hasPrefix("https://api.example.com/api/v1/features/feature-42/comments?") == true)
    let components = URLComponents(url: url!, resolvingAgainstBaseURL: false)
    let items = Dictionary(uniqueKeysWithValues: (components?.queryItems ?? []).map { ($0.name, $0.value) })
    #expect(items["limit"] == "50")
    #expect(items["cursor"] == "c9")
}

@Test func createCommentEndpointEncodesTextAndOptionalAuthorName() throws {
    let endpoint = try Endpoint.createComment(featureId: "feature-42", text: "Nice!", authorName: nil)
    #expect(endpoint.method == .post)
    let json = try JSONSerialization.jsonObject(with: endpoint.body!) as! [String: Any]
    #expect(json["text"] as? String == "Nice!")
    #expect(json["authorName"] == nil)
}

/// Guards the 405 regression: the nested `features/{id}/comments` path is GET-only on the
/// server, so creating a comment must target the flat collection with the id in the body.
@Test func createCommentPostsToFlatCollectionWithFeatureIdInBody() throws {
    let endpoint = try Endpoint.createComment(featureId: "feature-42", text: "Nice!", authorName: "Sam")
    #expect(endpoint.url(relativeTo: baseURL)?.absoluteString == "https://api.example.com/api/v1/comments")
    let json = try JSONSerialization.jsonObject(with: endpoint.body!) as! [String: Any]
    #expect(json["featureId"] as? String == "feature-42")
    #expect(json["authorName"] as? String == "Sam")
}

@Test func configEndpointUsesGetAndFixedPath() {
    let url = Endpoint.config.url(relativeTo: baseURL)
    #expect(Endpoint.config.method == .get)
    #expect(url?.absoluteString == "https://api.example.com/api/v1/config")
}

@Test func createFeatureEndpointSendsEmailAndSubscriberFlag() throws {
    let endpoint = try Endpoint.createFeature(
        title: "Dark mode",
        description: nil,
        email: "me@example.com",
        isSubscriber: true
    )
    let json = try JSONSerialization.jsonObject(with: endpoint.body!) as! [String: Any]
    #expect(json["email"] as? String == "me@example.com")
    #expect(json["isSubscriber"] as? Bool == true)
}

@Test func createFeatureEndpointOmitsEmailWhenNil() throws {
    let endpoint = try Endpoint.createFeature(title: "Dark mode", description: nil)
    let json = try JSONSerialization.jsonObject(with: endpoint.body!) as! [String: Any]
    #expect(json["email"] == nil)
    #expect(json["isSubscriber"] as? Bool == false)
}
