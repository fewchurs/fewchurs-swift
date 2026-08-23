import SwiftUI

/// A small sheet asking for one piece of optional identity — email (to follow a request)
/// or a display name (to comment). Same layout, different copy; genuinely one reuse case.
struct IdentityPromptSheet: View {
    enum Kind: Equatable {
        case email
        case displayName

        var title: String {
            switch self {
            case .email: return "Follow This Request"
            case .displayName: return "Your Name"
            }
        }

        var fieldLabel: String {
            switch self {
            case .email: return "Email"
            case .displayName: return "Display Name"
            }
        }

        var placeholder: String {
            switch self {
            case .email: return "you@example.com"
            case .displayName: return "Name"
            }
        }

        var footer: String {
            switch self {
            case .email: return "We'll only use this to tell you when this request ships."
            case .displayName: return "Shown next to your comments. Skip to comment as \"App User\"."
            }
        }

        var confirmTitle: String {
            switch self {
            case .email: return "Follow"
            case .displayName: return "Continue"
            }
        }
    }

    let kind: Kind
    /// Called with the trimmed, non-empty value, or `nil` if the user skipped.
    let onConfirm: (String?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var text = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(kind.placeholder, text: $text)
                        .textInputAutocapitalization(kind == .email ? .never : .words)
                        .autocorrectionDisabled(kind == .email)
                        .keyboardType(kind == .email ? .emailAddress : .default)
                } header: {
                    Text(kind.fieldLabel)
                } footer: {
                    Text(kind.footer)
                }
            }
            .navigationTitle(kind.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Skip") {
                        onConfirm(nil)
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(kind.confirmTitle) {
                        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                        onConfirm(trimmed.isEmpty ? nil : trimmed)
                        dismiss()
                    }
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
