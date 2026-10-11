import SwiftUI

struct PoweredByFooter: View {
    var body: some View {
        Text(String(sdk: "Powered by Fewchurs"))
            .font(.caption2)
            .foregroundStyle(.tertiary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
    }
}
