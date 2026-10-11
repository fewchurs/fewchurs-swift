import SwiftUI

/// "87/100" near a field once it's close to the server's limit, red when over. Hidden otherwise.
struct LimitCounter: View {
    let text: String
    let max: Int

    var body: some View {
        if ValidationLimits.showsCounter(for: text, max: max) {
            let length = ValidationLimits.length(of: text)
            Text("\(length)/\(max)")
                .font(.caption)
                .monospacedDigit()
                .foregroundStyle(length > max ? Color.red : Color.secondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .accessibilityLabel("\(length) of \(max) characters")
        }
    }
}
