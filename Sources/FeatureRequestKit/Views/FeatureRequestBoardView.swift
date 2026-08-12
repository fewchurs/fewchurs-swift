import SwiftUI

public struct FeatureRequestBoardView: View {
    @State private var model = FeatureBoardModel()
    @State private var isPresentingSubmit = false

    public init() {}

    public var body: some View {
        guard let configuration = FeatureRequestKit.configuration else {
            fatalError("FeatureRequestBoardView was presented before FeatureRequestKit.configure(apiKey:) was called. Call FeatureRequestKit.configure(apiKey:) once, early in your app's lifecycle, before presenting this view.")
        }

        return NavigationStack {
            VStack(spacing: 0) {
                Picker("Sort", selection: $model.sort) {
                    ForEach(FeatureSort.allCases, id: \.self) { sort in
                        Text(sort.displayName).tag(sort)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                content(background: configuration.theme.background)
            }
            .background(configuration.theme.background)
            .navigationTitle("Feature Requests")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isPresentingSubmit = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Request a feature")
                }
            }
            .sheet(isPresented: $isPresentingSubmit) {
                SubmitFeatureView(model: model)
            }
            .task {
                await model.load()
            }
        }
        .environment(\.featureRequestTheme, configuration.theme)
        .tint(configuration.theme.accent)
        .preferredColorScheme(configuration.theme.forcesDarkAppearance ? .dark : nil)
    }

    @ViewBuilder
    private func content(background: Color) -> some View {
        if model.isLoading && model.features.isEmpty {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let errorMessage = model.errorMessage, model.features.isEmpty {
            ContentUnavailableView {
                Label("Something Went Wrong", systemImage: "exclamationmark.triangle")
            } description: {
                VStack(spacing: 4) {
                    Text(errorMessage)
                    if let errorDetail = model.errorDetail {
                        Text(errorDetail)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            } actions: {
                Button("Retry") {
                    Task { await model.refresh() }
                }
            }
        } else if model.features.isEmpty {
            ContentUnavailableView {
                Label("No Feature Requests Yet", systemImage: "lightbulb")
            } description: {
                Text("Be the first to suggest an idea.")
            } actions: {
                Button("Request a Feature") {
                    isPresentingSubmit = true
                }
            }
        } else {
            List {
                ForEach(model.features) { feature in
                    FeatureRowView(feature: feature) {
                        Task { await model.toggleVote(feature) }
                    }
                    .onAppear {
                        if feature.id == model.features.last?.id {
                            Task { await model.loadMore() }
                        }
                    }
                    .listRowBackground(background)
                }

                if model.isLoadingMore {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(background)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .refreshable {
                await model.refresh()
            }
        }
    }
}
