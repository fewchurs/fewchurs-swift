import Foundation

enum FeatureSort: String, CaseIterable {
    case top
    case new

    var displayName: String {
        switch self {
        case .top: return "Top"
        case .new: return "New"
        }
    }
}

@Observable
@MainActor
final class FeatureBoardModel {
    private(set) var features: [FeatureRequest] = []
    private(set) var isLoading = false
    private(set) var isLoadingMore = false
    private(set) var boardConfig = BoardConfig.fallback
    var errorMessage: String?
    var errorDetail: String?
    var sort: FeatureSort = .top {
        didSet {
            guard oldValue != sort else { return }
            Task { await refresh() }
        }
    }

    private var nextCursor: String?
    private var hasMore = true
    private let apiClient: APIClient
    private let pageLimit = 20

    init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
    }

    func load() async {
        guard features.isEmpty else { return }
        await performFreshLoad()
    }

    func refresh() async {
        await performFreshLoad()
    }

    func loadMore() async {
        guard !isLoadingMore, !isLoading, hasMore, let cursor = nextCursor else { return }
        isLoadingMore = true
        errorMessage = nil
        errorDetail = nil
        do {
            let page: FeaturesPage = try await apiClient.send(.features(sort: sort.rawValue, limit: pageLimit, cursor: cursor))
            features.append(contentsOf: page.features)
            nextCursor = page.nextCursor
            hasMore = page.nextCursor != nil
        } catch {
            setError(error)
        }
        isLoadingMore = false
    }

    func toggleVote(_ feature: FeatureRequest) async {
        guard let index = features.firstIndex(where: { $0.id == feature.id }) else { return }
        let original = features[index]
        let wasVoted = original.hasVoted

        features[index].hasVoted.toggle()
        features[index].upvoteCount += wasVoted ? -1 : 1

        do {
            let response: VoteResponse = wasVoted
                ? try await apiClient.send(.removeVote(featureId: feature.id))
                : try await apiClient.send(.vote(featureId: feature.id))
            if let currentIndex = features.firstIndex(where: { $0.id == feature.id }) {
                features[currentIndex].upvoteCount = response.upvoteCount
                features[currentIndex].hasVoted = response.hasVoted
            }
        } catch {
            if let currentIndex = features.firstIndex(where: { $0.id == feature.id }) {
                features[currentIndex] = original
            }
            setError(error)
        }
    }

    func feature(withId id: String) -> FeatureRequest? {
        features.first { $0.id == id }
    }

    func toggleFollow(_ feature: FeatureRequest, email: String?) async {
        guard let index = features.firstIndex(where: { $0.id == feature.id }) else { return }
        let original = features[index]
        let wasFollowing = original.isFollowing
        guard wasFollowing || email != nil else { return }

        features[index].isFollowing.toggle()
        features[index].followerCount += wasFollowing ? -1 : 1

        do {
            let response: FollowResponse
            if wasFollowing {
                response = try await apiClient.send(.unfollow(featureId: feature.id))
            } else {
                response = try await apiClient.send(.follow(featureId: feature.id, email: email!))
            }
            if let currentIndex = features.firstIndex(where: { $0.id == feature.id }) {
                features[currentIndex].followerCount = response.followerCount
                features[currentIndex].isFollowing = response.isFollowing
            }
        } catch {
            if let currentIndex = features.firstIndex(where: { $0.id == feature.id }) {
                features[currentIndex] = original
            }
            setError(error)
        }
    }

    func incrementCommentCount(for featureId: String) {
        guard let index = features.firstIndex(where: { $0.id == featureId }) else { return }
        features[index].commentCount += 1
    }

    /// Loads once per board open. Never surfaces an error and never overwrites the
    /// safe `.fallback` default on failure — a broken config call must not hide the
    /// board or make branding disappear.
    func loadConfig() async {
        guard let config: BoardConfig = try? await apiClient.send(.config) else { return }
        boardConfig = config
    }

    /// If `email` is provided, the newly created feature is auto-followed via the
    /// existing follow endpoint — no separate backend contract needed for this.
    /// A failed auto-follow doesn't fail the submission; the feature was already created.
    func submit(title: String, description: String?, email: String?) async throws {
        let trimmedDescription = description?.trimmingCharacters(in: .whitespacesAndNewlines)
        let endpoint = try Endpoint.createFeature(
            title: title,
            description: (trimmedDescription?.isEmpty ?? true) ? nil : trimmedDescription
        )
        var created: FeatureRequest = try await apiClient.send(endpoint)

        if let email, !email.isEmpty,
           let followEndpoint = try? Endpoint.follow(featureId: created.id, email: email),
           let response: FollowResponse = try? await apiClient.send(followEndpoint) {
            created.followerCount = response.followerCount
            created.isFollowing = response.isFollowing
        }

        features.insert(created, at: 0)
    }

    private func performFreshLoad() async {
        isLoading = true
        errorMessage = nil
        errorDetail = nil
        do {
            let page: FeaturesPage = try await apiClient.send(.features(sort: sort.rawValue, limit: pageLimit, cursor: nil))
            features = page.features
            nextCursor = page.nextCursor
            hasMore = page.nextCursor != nil
        } catch {
            setError(error)
        }
        isLoading = false
    }

    private func setError(_ error: Error) {
        let apiError = (error as? APIError) ?? .network
        errorMessage = apiError.userMessage
        errorDetail = apiError.debugDetail
    }
}
