import SwiftUI

struct CommentRowView: View {
    let comment: Comment

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text(comment.authorName?.isEmpty == false ? comment.authorName! : "App User")
                    .font(.subheadline.weight(.semibold))

                if comment.isDeveloper {
                    Text("Developer")
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .foregroundStyle(.white)
                        .background(Color.blue, in: Capsule())
                }

                Spacer()

                Text(comment.createdAt, format: .relative(presentation: .named))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(comment.text)
                .font(.body)
        }
        .padding(.vertical, 4)
    }
}
