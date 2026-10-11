import SwiftUI

struct SubmitFeatureView: View {
    let model: FeatureBoardModel

    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var description = ""
    @State private var email: String
    @State private var isEditingEmail: Bool
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var errorDetail: String?

    private var canSubmit: Bool {
        ValidationLimits.isValidTitle(title)
            && ValidationLimits.fits(description, max: ValidationLimits.descriptionMax)
            && !isSubmitting
    }

    init(model: FeatureBoardModel) {
        self.model = model
        let savedEmail = UserIdentity.preferredEmail ?? ""
        _email = State(initialValue: savedEmail)
        _isEditingEmail = State(initialValue: savedEmail.isEmpty)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(String(sdk: "Title"), text: $title, axis: .vertical)
                    LimitCounter(text: title, max: ValidationLimits.titleMax)
                } header: {
                    Text(String(sdk: "Title"))
                }

                Section {
                    TextEditor(text: $description)
                        .frame(minHeight: 100)
                    LimitCounter(text: description, max: ValidationLimits.descriptionMax)
                } header: {
                    Text(String(sdk: "Description (optional)"))
                }

                Section {
                    if isEditingEmail {
                        TextField(String(sdk: "you@example.com"), text: $email)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    } else {
                        HStack {
                            Text(email)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Button(String(sdk: "Change")) { isEditingEmail = true }
                                .font(.caption)
                        }
                    }
                } header: {
                    Text(String(sdk: "Email (optional)"))
                } footer: {
                    Text(String(sdk: "Want an email when this is added?"))
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                        if let errorDetail {
                            Text(errorDetail)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle(String(sdk: "Request a Feature"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(sdk: "Cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSubmitting {
                        ProgressView()
                    } else {
                        Button(String(sdk: "Submit")) { submit() }
                            .disabled(!canSubmit)
                    }
                }
            }
        }
    }

    private func submit() {
        errorMessage = nil
        errorDetail = nil
        isSubmitting = true
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        Task {
            do {
                try await model.submit(
                    title: trimmedTitle,
                    description: description,
                    email: trimmedEmail.isEmpty ? nil : trimmedEmail,
                    isSubscriber: FeatureRequestKit.currentUserIsSubscriber
                )
                // Remember an email the user typed. One that came from identify(email:) stays
                // with the host, so signing out (identify(email: nil)) really forgets it.
                if !trimmedEmail.isEmpty, trimmedEmail != FeatureRequestKit.identifiedEmail {
                    UserIdentity.email = trimmedEmail
                }
                isSubmitting = false
                dismiss()
            } catch {
                isSubmitting = false
                let apiError = (error as? APIError) ?? .network
                errorMessage = apiError.userMessage
                errorDetail = apiError.presentableDebugDetail
            }
        }
    }
}
