import SwiftUI

struct UpvoteButton: View {
    let count: Int
    let hasVoted: Bool
    /// False when the board owner hid vote counts. The button still votes; only the number goes.
    var showsCount = true
    let action: () -> Void

    @Environment(\.featureRequestTheme) private var theme

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: "chevron.up")
                    .font(.caption.weight(.bold))
                if showsCount {
                    Text(count, format: .number)
                        .font(.caption2.weight(.semibold))
                        .monospacedDigit()
                }
            }
            .frame(minWidth: 40)
            .padding(.vertical, 6)
            .foregroundStyle(hasVoted ? theme.background : theme.accent)
            .background {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(hasVoted ? theme.accent : theme.accent.opacity(0.12))
            }
            // The pill keeps its size; the tappable area grows to the 44pt minimum around it.
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        // VoiceOver: "Upvote, 42 votes, selected". No count when the owner hid counts.
        .accessibilityLabel(String(sdk: "Upvote"))
        .accessibilityValue(showsCount ? (count == 1 ? String(sdk: "1 vote") : String(sdk: "\(count) votes")) : "")
        .accessibilityAddTraits(hasVoted ? .isSelected : [])
    }
}
