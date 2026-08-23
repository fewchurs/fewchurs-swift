import SwiftUI

struct FeatureRowView: View {
    let feature: FeatureRequest
    let onVote: () -> Void
    let onFollowTapped: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(feature.title)
                    .font(.headline)
                if let description = feature.description, !description.isEmpty {
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                HStack(spacing: 10) {
                    if feature.status != .open {
                        StatusBadgeView(status: feature.status)
                    }
                    if feature.commentCount > 0 {
                        Label("\(feature.commentCount)", systemImage: "bubble.left")
                            .labelStyle(.titleAndIcon)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            Spacer(minLength: 8)
            HStack(spacing: 8) {
                FollowButton(isFollowing: feature.isFollowing, action: onFollowTapped)
                UpvoteButton(count: feature.upvoteCount, hasVoted: feature.hasVoted, action: onVote)
            }
        }
        .padding(.vertical, 4)
    }
}

/// A bell toggle for "email me when this changes." Deliberately separate from
/// `UpvoteButton` — following can require an email prompt, but upvoting must always
/// stay a single, frictionless tap.
struct FollowButton: View {
    let isFollowing: Bool
    let action: () -> Void

    @Environment(\.featureRequestTheme) private var theme

    var body: some View {
        Button(action: action) {
            Image(systemName: isFollowing ? "bell.fill" : "bell")
                .font(.body)
                .foregroundStyle(isFollowing ? theme.accent : Color.secondary)
                .frame(width: 32, height: 32)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isFollowing ? "Unfollow this request" : "Follow this request")
    }
}
