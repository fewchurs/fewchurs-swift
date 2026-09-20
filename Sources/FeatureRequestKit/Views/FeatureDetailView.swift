import SwiftUI

struct FeatureDetailView: View {
    @State private var model: FeatureDetailModel

    @State private var commentText = ""
    @State private var isPresentingNamePrompt = false
    @State private var isPresentingEmailPrompt = false
    @Environment(\.featureRequestTheme) private var theme

    /// Owns its model via `@State`, seeded once from stable inputs. `navigationDestination(for:)`
    /// re-invokes its closure on unrelated parent re-renders (e.g. any `boardModel.features`
    /// mutation), so building the model directly in that closure would silently discard
    /// in-progress comment state — `@State` preserves it across those re-invocations.
    init(featureId: String, boardModel: FeatureBoardModel) {
        _model = State(initialValue: FeatureDetailModel(featureId: featureId, boardModel: boardModel))
    }

    var body: some View {
        Group {
            if let feature = model.feature {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        header(for: feature)
                        Divider()
                        commentsSection
                    }
                    .padding()
                }
                .safeAreaInset(edge: .bottom) {
                    CommentInputView(text: $commentText, isPosting: model.isPostingComment, onSubmit: submitComment)
                }
            } else {
                ContentUnavailableView("Request Not Found", systemImage: "questionmark.circle")
            }
        }
        .background(theme.background)
        .navigationTitle("Feature Request")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await model.loadComments()
        }
        .sheet(isPresented: $isPresentingNamePrompt) {
            IdentityPromptSheet(kind: .displayName) { name in
                if let name { UserIdentity.displayName = name }
                Task { await postComment(authorName: name) }
            }
        }
        .sheet(isPresented: $isPresentingEmailPrompt) {
            IdentityPromptSheet(kind: .email) { email in
                guard let email else { return }
                UserIdentity.email = email
                Task { await model.toggleFollow(email: email) }
            }
        }
    }

    @ViewBuilder
    private func header(for feature: FeatureRequest) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(feature.title)
                .font(.title2.weight(.bold))

            if let description = feature.description, !description.isEmpty {
                Text(description)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                if feature.status.showsBadge {
                    StatusBadgeView(status: feature.status)
                }
                Spacer()
                FollowButton(isFollowing: feature.isFollowing) {
                    handleFollowTap(feature: feature)
                }
                UpvoteButton(count: feature.upvoteCount, hasVoted: feature.hasVoted) {
                    Task { await model.toggleVote() }
                }
            }
        }
    }

    @ViewBuilder
    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Comments")
                .font(.headline)
                .padding(.bottom, 4)

            if model.isLoadingComments && model.comments.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.top, 24)
            } else if model.comments.isEmpty {
                Text("No comments yet.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            } else {
                ForEach(model.comments) { comment in
                    CommentRowView(comment: comment)
                        .onAppear {
                            if comment.id == model.comments.last?.id {
                                Task { await model.loadMoreComments() }
                            }
                        }
                    Divider()
                }
                if model.isLoadingMoreComments {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
            }

            if let errorMessage = model.errorMessage {
                VStack(alignment: .leading, spacing: 2) {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                    if let errorDetail = model.errorDetail {
                        Text(errorDetail)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.top, 4)
            }
        }
    }

    private func handleFollowTap(feature: FeatureRequest) {
        if feature.isFollowing {
            Task { await model.toggleFollow(email: nil) }
        } else if let email = UserIdentity.email {
            Task { await model.toggleFollow(email: email) }
        } else {
            isPresentingEmailPrompt = true
        }
    }

    private func submitComment() {
        guard !commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        if let displayName = UserIdentity.displayName {
            Task { await postComment(authorName: displayName) }
        } else {
            isPresentingNamePrompt = true
        }
    }

    private func postComment(authorName: String?) async {
        if await model.postComment(text: commentText, authorName: authorName) {
            commentText = ""
        }
    }
}
