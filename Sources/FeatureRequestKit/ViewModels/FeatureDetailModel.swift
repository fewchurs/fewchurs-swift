import Foundation

@Observable
@MainActor
final class FeatureDetailModel {
    let featureId: String

    private(set) var comments: [Comment] = []
    private(set) var isLoadingComments = false
    private(set) var isLoadingMoreComments = false
    private(set) var isPostingComment = false
    private(set) var isLoadingFeature = false
    /// The server answered 404: the request was deleted, or the id was never valid.
    private(set) var featureIsMissing = false
    var errorMessage: String?
    var errorDetail: String?

    private var nextCursor: String?
    private var hasMoreComments = true
    private let commentsLimit = 50

    private let boardModel: FeatureBoardModel
    private let apiClient: APIClient

    var feature: FeatureRequest? {
        boardModel.feature(withId: featureId)
    }

    var hidesVoteCounts: Bool {
        boardModel.boardConfig.hideVoteCounts
    }

    init(featureId: String, boardModel: FeatureBoardModel, apiClient: APIClient = .shared) {
        self.featureId = featureId
        self.boardModel = boardModel
        self.apiClient = apiClient
    }

    /// Opening a request that isn't on a loaded page (a deep link, or a page since evicted)
    /// fetches it instead of showing "not found".
    func loadFeatureIfNeeded() async {
        guard feature == nil else { return }
        await fetchFeature()
    }

    /// Pull-to-refresh: the request itself (status, counts) and its comments.
    func refresh() async {
        async let feature: Void = fetchFeature()
        async let comments: Void = performFreshLoad()
        _ = await (feature, comments)
    }

    func loadComments() async {
        guard comments.isEmpty else { return }
        await performFreshLoad()
    }

    func refreshComments() async {
        await performFreshLoad()
    }

    func loadMoreComments() async {
        guard !isLoadingMoreComments, !isLoadingComments, hasMoreComments, let cursor = nextCursor else { return }
        isLoadingMoreComments = true
        do {
            let page: CommentsPage = try await apiClient.send(.comments(featureId: featureId, limit: commentsLimit, cursor: cursor))
            comments.append(contentsOf: page.comments)
            nextCursor = page.nextCursor
            hasMoreComments = page.nextCursor != nil
        } catch {
            setError(error)
        }
        isLoadingMoreComments = false
    }

    func toggleVote() async {
        guard let feature else { return }
        await boardModel.toggleVote(feature)
    }

    func toggleFollow(email: String?) async {
        guard let feature else { return }
        await boardModel.toggleFollow(feature, email: email)
    }

    @discardableResult
    func postComment(text: String, authorName: String?) async -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        isPostingComment = true
        errorMessage = nil
        errorDetail = nil
        defer { isPostingComment = false }
        do {
            let endpoint = try Endpoint.createComment(featureId: featureId, text: trimmed, authorName: authorName)
            var comment: Comment = try await apiClient.send(endpoint)
            comment.isMine = true
            comments.append(comment)
            boardModel.incrementCommentCount(for: featureId)
            return true
        } catch {
            setError(error)
            return false
        }
    }

    private func fetchFeature() async {
        isLoadingFeature = true
        defer { isLoadingFeature = false }
        do {
            let fetched: FeatureRequest = try await apiClient.send(.feature(id: featureId))
            featureIsMissing = false
            boardModel.store(fetched)
        } catch APIError.notFound {
            featureIsMissing = true
        } catch {
            // A failed refresh of a feature already on screen keeps it there; only a feature
            // we have nothing for needs the error.
            if feature == nil { setError(error) }
        }
    }

    private func performFreshLoad() async {
        isLoadingComments = true
        errorMessage = nil
        errorDetail = nil
        do {
            let page: CommentsPage = try await apiClient.send(.comments(featureId: featureId, limit: commentsLimit, cursor: nil))
            comments = page.comments
            nextCursor = page.nextCursor
            hasMoreComments = page.nextCursor != nil
        } catch {
            setError(error)
        }
        isLoadingComments = false
    }

    private func setError(_ error: Error) {
        let apiError = (error as? APIError) ?? .network
        errorMessage = apiError.userMessage
        errorDetail = apiError.presentableDebugDetail
    }
}
