import Foundation
import Testing
@testable import FeatureRequestKit
import struct FeatureRequestKit.Comment

private typealias SDKComment = Comment

/// Calls the real API and decodes every response type. This is the test that would have
/// caught both the comment 405 and the follow decoding bug.
///
/// Off unless `FEWCHURS_CONTRACT_API_KEY` is set. Use a key for a test app, not a real one:
/// votes and follows are made and immediately undone, so counts flicker for a moment.
///
/// - `FEWCHURS_CONTRACT_BASE_URL`: optional, defaults to production.
/// - `FEWCHURS_CONTRACT_ALLOW_WRITES=1`: also creates one feature and one comment. These
///   can't be deleted through the public API; remove them from the dashboard afterwards.
///
/// Simulator test runs only see variables prefixed with `TEST_RUNNER_`:
///
///     TEST_RUNNER_FEWCHURS_CONTRACT_API_KEY=fr_live_xxx xcodebuild test -scheme FeatureRequestKit \
///       -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing FeatureRequestKitTests/LiveContractTests
@Suite(.serialized, .enabled(if: LiveContract.apiKey != nil, "Set FEWCHURS_CONTRACT_API_KEY to run"))
struct LiveContractTests {
    private let client = LiveContract.makeClient()

    @Test func config() async throws {
        let _: BoardConfig = try await client.send(.config)
    }

    @Test func listsEveryTabAndReadsOneFeatureWithItsComments() async throws {
        for sort in FeatureSort.allCases {
            let _: FeaturesPage = try await client.send(.features(sort: sort.apiSort, limit: 5, cursor: nil, statuses: sort.statuses))
        }
        let page: FeaturesPage = try await client.send(.features(sort: "new", limit: 5, cursor: nil))
        guard let first = page.features.first else { return }

        let feature: FeatureRequest = try await client.send(.feature(id: first.id))
        #expect(feature.id == first.id)
        let _: CommentsPage = try await client.send(.comments(featureId: first.id, limit: 5, cursor: nil))
    }

    @Test func voteAndFollowThenUndo() async throws {
        let page: FeaturesPage = try await client.send(.features(sort: "new", limit: 1, cursor: nil))
        guard let feature = page.features.first else { return }

        if feature.hasVoted {
            let _: VoteResponse = try await client.send(.removeVote(featureId: feature.id))
            let _: VoteResponse = try await client.send(.vote(featureId: feature.id))
        } else {
            let voted: VoteResponse = try await client.send(.vote(featureId: feature.id))
            #expect(voted.hasVoted)
            let _: VoteResponse = try await client.send(.removeVote(featureId: feature.id))
        }

        if !feature.isFollowing {
            let followed: FollowResponse = try await client.send(.follow(featureId: feature.id, email: "contract-test@example.com"))
            #expect(followed.following)
            let unfollowed: FollowResponse = try await client.send(.unfollow(featureId: feature.id))
            #expect(!unfollowed.following)
        }
    }

    @Test(.enabled(if: LiveContract.allowsWrites, "Set FEWCHURS_CONTRACT_ALLOW_WRITES=1 to create data"))
    func createFeatureAndComment() async throws {
        let created: FeatureRequest = try await client.send(
            try .createFeature(title: "SDK contract test \(FeatureRequestKit.sdkVersion)", description: "Safe to delete.")
        )
        #expect(created.status == .open)
        let _: SDKComment = try await client.send(try .createComment(featureId: created.id, text: "Contract test comment", authorName: nil))
    }
}

enum LiveContract {
    static let environment = ProcessInfo.processInfo.environment
    static let apiKey = environment["FEWCHURS_CONTRACT_API_KEY"].flatMap { $0.isEmpty ? nil : $0 }
    static let allowsWrites = environment["FEWCHURS_CONTRACT_ALLOW_WRITES"] == "1"
    static let baseURL = environment["FEWCHURS_CONTRACT_BASE_URL"].flatMap(URL.init(string:)) ?? Configuration.defaultBaseURL

    static func makeClient() -> APIClient {
        APIClient(configuration: Configuration(apiKey: apiKey ?? "", baseURL: baseURL, theme: .system))
    }
}
