import Foundation

@Observable
@MainActor
final class FeatureDetailModel {
    let featureId: String

    private(set) var comments: [Comment] = []
    private(set) var isLoadingComments = false
    private(set) var isLoadingMoreComments = false
    private(set) var isPostingComment = false
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
        errorDetail = apiError.debugDetail
    }
}
