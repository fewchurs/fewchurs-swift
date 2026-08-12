import SwiftUI

struct FeatureRowView: View {
    let feature: FeatureRequest
    let onVote: () -> Void

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
                if feature.status != .open {
                    StatusBadgeView(status: feature.status)
                }
            }
            Spacer(minLength: 8)
            UpvoteButton(count: feature.upvoteCount, hasVoted: feature.hasVoted, action: onVote)
        }
        .padding(.vertical, 4)
    }
}
