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

    func submit(title: String, description: String?) async throws {
        let trimmedDescription = description?.trimmingCharacters(in: .whitespacesAndNewlines)
        let endpoint = try Endpoint.createFeature(
            title: title,
            description: (trimmedDescription?.isEmpty ?? true) ? nil : trimmedDescription
        )
        let created: FeatureRequest = try await apiClient.send(endpoint)
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
