import Foundation

enum FeatureSort: String, CaseIterable {
    case top
    case new
    /// Opt-in: what's planned, in progress and done, most-voted first.
    case roadmap

    var displayName: String {
        switch self {
        case .top: return "Top"
        case .new: return "New"
        case .roadmap: return "Roadmap"
        }
    }

    /// The tabs shown, in order. Roadmap only appears when the host asks for it.
    static func visible(showsRoadmap: Bool) -> [FeatureSort] {
        showsRoadmap ? [.top, .new, .roadmap] : [.top, .new]
    }

    /// The `sort` query value. Roadmap is ordered like Top.
    var apiSort: String {
        switch self {
        case .top, .roadmap: return "top"
        case .new: return "new"
        }
    }

    /// The `status` filter; empty means every status.
    var statuses: [FeatureStatus] {
        switch self {
        case .top, .new: return []
        case .roadmap: return [.planned, .inProgress, .done]
        }
    }

    func includes(_ status: FeatureStatus) -> Bool {
        statuses.isEmpty || statuses.contains(status)
    }
}

@Observable
@MainActor
final class FeatureBoardModel {
    /// Everything that is per-tab. Each sort keeps its own page cache so switching tabs can
    /// render instantly from memory instead of waiting on a round trip.
    private struct SortState {
        var features: [FeatureRequest] = []
        var nextCursor: String?
        var hasMore = true
        var loadedAt: Date?
        var isLoading = false
        var isLoadingMore = false
    }

    private(set) var boardConfig = BoardConfig.fallback
    var errorMessage: String?
    var errorDetail: String?
    var sort: FeatureSort = .top {
        didSet {
            guard oldValue != sort else { return }
            // An error left over from the other tab must not cover this tab's cached content.
            errorMessage = nil
            errorDetail = nil
            Task { await loadCurrentSort() }
        }
    }

    private var states: [FeatureSort: SortState] = [:]
    /// Features loaded one at a time (deep links, detail refresh) that may not be on any
    /// loaded page. Votes and follows update these copies too.
    private var standalone: [String: FeatureRequest] = [:]
    private let apiClient: APIClient
    private let pageLimit = 20

    /// How long a cached tab is served without re-fetching. Long enough that toggling
    /// back and forth is free, short enough that a tab left open doesn't go stale.
    private let cacheLifetime: TimeInterval = 30

    init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
    }

    var features: [FeatureRequest] { states[sort]?.features ?? [] }

    /// The host's title wins; otherwise the app name from `/config`; otherwise a generic title.
    func navigationTitle(hostTitle: String?) -> String {
        if let hostTitle, !hostTitle.isEmpty { return hostTitle }
        if let appName = boardConfig.appName, !appName.isEmpty { return appName }
        return "Feature Requests"
    }
    var isLoading: Bool { states[sort]?.isLoading ?? false }
    var isLoadingMore: Bool { states[sort]?.isLoadingMore ?? false }

    func load() async {
        await loadCurrentSort()
    }

    func refresh() async {
        await fetchFirstPage(for: sort, showsSpinner: true)
    }

    func loadMore() async {
        let sort = self.sort
        guard var state = states[sort] else { return }
        guard !state.isLoadingMore, !state.isLoading, state.hasMore, let cursor = state.nextCursor else { return }

        state.isLoadingMore = true
        states[sort] = state
        errorMessage = nil
        errorDetail = nil
        do {
            let page: FeaturesPage = try await apiClient.send(.features(sort: sort.apiSort, limit: pageLimit, cursor: cursor, statuses: sort.statuses))
            var updated = states[sort] ?? SortState()
            updated.features.append(contentsOf: page.features)
            updated.nextCursor = page.nextCursor
            updated.hasMore = page.nextCursor != nil
            updated.isLoadingMore = false
            states[sort] = updated
        } catch {
            states[sort]?.isLoadingMore = false
            setError(error)
        }
    }

    func toggleVote(_ feature: FeatureRequest) async {
        guard let original = self.feature(withId: feature.id) else { return }
        let wasVoted = original.hasVoted

        update(featureId: feature.id) {
            $0.hasVoted.toggle()
            $0.upvoteCount += wasVoted ? -1 : 1
        }

        do {
            let response: VoteResponse = wasVoted
                ? try await apiClient.send(.removeVote(featureId: feature.id))
                : try await apiClient.send(.vote(featureId: feature.id))
            update(featureId: feature.id) {
                $0.upvoteCount = response.upvoteCount
                $0.hasVoted = response.hasVoted
            }
        } catch {
            update(featureId: feature.id) { $0 = original }
            setError(error)
        }
    }

    func feature(withId id: String) -> FeatureRequest? {
        if let match = states[sort]?.features.first(where: { $0.id == id }) {
            return match
        }
        // The detail screen can outlive a tab switch, so fall back to the other tab's cache.
        for state in states.values {
            if let match = state.features.first(where: { $0.id == id }) { return match }
        }
        return standalone[id]
    }

    /// Replaces every cached copy with a fresher one from `GET /features/{id}`, and keeps it
    /// even when it is on no loaded page.
    func store(_ feature: FeatureRequest) {
        standalone[feature.id] = feature
        update(featureId: feature.id) { $0 = feature }
    }

    func toggleFollow(_ feature: FeatureRequest, email: String?) async {
        guard let original = self.feature(withId: feature.id) else { return }
        let wasFollowing = original.isFollowing
        guard wasFollowing || email != nil else { return }

        update(featureId: feature.id) {
            $0.isFollowing.toggle()
            $0.followerCount += wasFollowing ? -1 : 1
        }

        do {
            let response: FollowResponse
            if wasFollowing {
                response = try await apiClient.send(.unfollow(featureId: feature.id))
            } else {
                response = try await apiClient.send(.follow(featureId: feature.id, email: email!))
            }
            update(featureId: feature.id) { $0.isFollowing = response.following }
        } catch {
            update(featureId: feature.id) { $0 = original }
            setError(error)
        }
    }

    func incrementCommentCount(for featureId: String) {
        update(featureId: featureId) { $0.commentCount += 1 }
    }

    /// Loads once per board open. Never surfaces an error and never overwrites the
    /// safe `.fallback` default on failure — a broken config call must not hide the
    /// board or make branding disappear.
    func loadConfig() async {
        guard let config: BoardConfig = try? await apiClient.send(.config) else { return }
        boardConfig = config
    }

    /// One request: with an `email`, the server follows the new feature itself and returns
    /// `followerCount` 1. The create response has no per-device flags, so they are set here.
    func submit(title: String, description: String?, email: String?, isSubscriber: Bool = false) async throws {
        let trimmedDescription = description?.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email?.trimmingCharacters(in: .whitespacesAndNewlines)
        let followEmail = (trimmedEmail?.isEmpty ?? true) ? nil : trimmedEmail
        let endpoint = try Endpoint.createFeature(
            title: title,
            description: (trimmedDescription?.isEmpty ?? true) ? nil : trimmedDescription,
            email: followEmail,
            isSubscriber: isSubscriber
        )
        var created: FeatureRequest = try await apiClient.send(endpoint)
        created.isFollowing = followEmail != nil
        created.isMine = true
        created.hasVoted = false

        // Show it immediately on the tab the user is looking at; the other tabs' caches are
        // expired rather than guessed at, since a 0-vote feature's position under "Top"
        // is the server's call. A new request is "open", so it never belongs on Roadmap.
        let shownOn = sort.includes(created.status) ? sort : nil
        if let shownOn {
            var state = states[shownOn] ?? SortState()
            state.features.insert(created, at: 0)
            states[shownOn] = state
        } else {
            standalone[created.id] = created
        }
        for other in FeatureSort.allCases where other != shownOn {
            states[other]?.loadedAt = nil
        }
    }

    /// Renders the tab instantly when its cache is warm, and only blocks with a spinner the
    /// first time a tab is opened. A warm-but-stale tab refreshes silently underneath.
    private func loadCurrentSort() async {
        let sort = self.sort
        guard let state = states[sort], let loadedAt = state.loadedAt else {
            await fetchFirstPage(for: sort, showsSpinner: true)
            return
        }
        guard Date().timeIntervalSince(loadedAt) > cacheLifetime else { return }
        await fetchFirstPage(for: sort, showsSpinner: false)
    }

    private func fetchFirstPage(for sort: FeatureSort, showsSpinner: Bool) async {
        var state = states[sort] ?? SortState()
        state.isLoading = showsSpinner
        states[sort] = state
        errorMessage = nil
        errorDetail = nil

        do {
            let page: FeaturesPage = try await apiClient.send(.features(sort: sort.apiSort, limit: pageLimit, cursor: nil, statuses: sort.statuses))
            var updated = states[sort] ?? SortState()
            updated.features = page.features
            updated.nextCursor = page.nextCursor
            updated.hasMore = page.nextCursor != nil
            updated.loadedAt = Date()
            updated.isLoading = false
            states[sort] = updated
        } catch {
            states[sort]?.isLoading = false
            // A failed silent refresh keeps the cached content on screen; surfacing the error
            // would replace a working list with an error banner for no good reason.
            if showsSpinner {
                setError(error)
            }
        }
    }

    /// Applies an edit to every cached copy of a feature, so a vote cast on one tab is
    /// already correct when the user switches to the other.
    private func update(featureId: String, _ transform: (inout FeatureRequest) -> Void) {
        for (sort, var state) in states {
            guard let index = state.features.firstIndex(where: { $0.id == featureId }) else { continue }
            transform(&state.features[index])
            states[sort] = state
        }
        if var feature = standalone[featureId] {
            transform(&feature)
            standalone[featureId] = feature
        }
    }

    private func setError(_ error: Error) {
        let apiError = (error as? APIError) ?? .network
        errorMessage = apiError.userMessage
        errorDetail = apiError.presentableDebugDetail
    }
}
