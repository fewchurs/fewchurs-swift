import SwiftUI

struct UpvoteButton: View {
    let count: Int
    let hasVoted: Bool
    let action: () -> Void

    @Environment(\.featureRequestTheme) private var theme

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: "chevron.up")
                    .font(.caption.weight(.bold))
                Text("\(count)")
                    .font(.caption2.weight(.semibold))
                    .monospacedDigit()
            }
            .frame(minWidth: 40)
            .padding(.vertical, 6)
            .foregroundStyle(hasVoted ? theme.background : theme.accent)
            .background {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(hasVoted ? theme.accent : theme.accent.opacity(0.12))
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(hasVoted ? "Remove upvote" : "Upvote")
        .accessibilityValue("\(count) votes")
    }
}
