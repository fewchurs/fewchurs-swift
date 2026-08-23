import SwiftUI

struct CommentInputView: View {
    @Binding var text: String
    let isPosting: Bool
    let onSubmit: () -> Void

    @Environment(\.featureRequestTheme) private var theme
    @FocusState private var isFocused: Bool

    private var canSubmit: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isPosting
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            TextField("Add a comment", text: $text, axis: .vertical)
                .lineLimit(1...4)
                .focused($isFocused)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: theme.cornerRadius, style: .continuous))

            if isPosting {
                ProgressView()
                    .frame(width: 32, height: 32)
            } else {
                Button {
                    isFocused = false
                    onSubmit()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(canSubmit ? theme.accent : Color.secondary.opacity(0.4))
                }
                .buttonStyle(.plain)
                .disabled(!canSubmit)
            }
        }
        .padding()
        .background(.bar)
    }
}
