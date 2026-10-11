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

    private let titleLimit = 80
    private let descriptionLimit = 500

    private var canSubmit: Bool {
        title.trimmingCharacters(in: .whitespacesAndNewlines).count >= 3 && !isSubmitting
    }

    init(model: FeatureBoardModel) {
        self.model = model
        let savedEmail = UserIdentity.email ?? ""
        _email = State(initialValue: savedEmail)
        _isEditingEmail = State(initialValue: savedEmail.isEmpty)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title", text: $title)
                        .onChange(of: title) { _, newValue in
                            if newValue.count > titleLimit {
                                title = String(newValue.prefix(titleLimit))
                            }
                        }
                    Text("\(title.count)/\(titleLimit)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Title")
                }

                Section {
                    TextEditor(text: $description)
                        .frame(minHeight: 100)
                        .onChange(of: description) { _, newValue in
                            if newValue.count > descriptionLimit {
                                description = String(newValue.prefix(descriptionLimit))
                            }
                        }
                    Text("\(description.count)/\(descriptionLimit)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Description (optional)")
                }

                Section {
                    if isEditingEmail {
                        TextField("you@example.com", text: $email)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    } else {
                        HStack {
                            Text(email)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Button("Change") { isEditingEmail = true }
                                .font(.caption)
                        }
                    }
                } header: {
                    Text("Email (optional)")
                } footer: {
                    Text("Want an email when this is added?")
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
            .navigationTitle("Request a Feature")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSubmitting {
                        ProgressView()
                    } else {
                        Button("Submit") { submit() }
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
                if !trimmedEmail.isEmpty {
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
