import SwiftUI

struct SubmitFeatureView: View {
    let model: FeatureBoardModel

    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var description = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    private let titleLimit = 80
    private let descriptionLimit = 500

    private var canSubmit: Bool {
        title.trimmingCharacters(in: .whitespacesAndNewlines).count >= 3 && !isSubmitting
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

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
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
        isSubmitting = true
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        Task {
            do {
                try await model.submit(title: trimmedTitle, description: description)
                isSubmitting = false
                dismiss()
            } catch {
                isSubmitting = false
                errorMessage = (error as? APIError)?.userMessage ?? APIError.network.userMessage
            }
        }
    }
}
