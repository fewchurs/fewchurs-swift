import SwiftUI

struct FeatureRowView: View {
    let feature: FeatureRequest
    var showsVoteCount = true
    let onVote: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// Side by side normally; stacked at accessibility text sizes, where a side-by-side vote
    /// button would squeeze the title to a few characters per line.
    private var layout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
            : AnyLayout(HStackLayout(alignment: .top, spacing: 12))
    }

    var body: some View {
        layout {
            VStack(alignment: .leading, spacing: 4) {
                Text(feature.title)
                    .font(.headline)
                if let description = feature.description, !description.isEmpty {
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                FlowingRow {
                    if feature.status.showsBadge {
                        StatusBadgeView(status: feature.status)
                    }
                    if feature.isMine {
                        MineMarker(text: "Your request")
                    }
                    if feature.commentCount > 0 {
                        Label("\(feature.commentCount)", systemImage: "bubble.left")
                            .labelStyle(.titleAndIcon)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .accessibilityLabel(feature.commentCount == 1 ? "1 comment" : "\(feature.commentCount) comments")
                    }
                }
            }
            if !dynamicTypeSize.isAccessibilitySize {
                Spacer(minLength: 8)
            }
            UpvoteButton(count: feature.upvoteCount, hasVoted: feature.hasVoted, showsCount: showsVoteCount, action: onVote)
        }
        .padding(.vertical, 4)
    }
}

/// Small tags in a row that wrap onto a new line when they don't fit, instead of truncating.
struct FlowingRow<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 10) { content }
            VStack(alignment: .leading, spacing: 6) { content }
        }
    }
}

/// A quiet tag for things this device wrote. Deliberately low-contrast: it orients the user,
/// it isn't a badge to compete with the status.
struct MineMarker: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption2.weight(.medium))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .overlay(Capsule().strokeBorder(Color.secondary.opacity(0.4)))
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
                // 44pt is the minimum comfortable tap target; the icon itself stays small.
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Follow request")
        .accessibilityHint("Get an email when this request changes.")
        .accessibilityAddTraits(isFollowing ? .isSelected : [])
    }
}
