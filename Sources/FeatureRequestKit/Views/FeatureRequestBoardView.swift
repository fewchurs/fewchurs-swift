import SwiftUI

public struct FeatureRequestBoardView: View {
    @State private var model = FeatureBoardModel.shared
    @State private var isPresentingSubmit = false
    @State private var path: [String]

    private let title: String?
    private let showsRoadmap: Bool

    /// - Parameters:
    ///   - title: The navigation title. Leave it out to use your app's name from the
    ///     Fewchurs dashboard, or "Feature Requests" until that loads.
    ///   - showsRoadmap: Adds a third "Roadmap" tab listing planned, in-progress and done
    ///     requests, most-voted first. Off by default.
    public init(title: String? = nil, showsRoadmap: Bool = false) {
        self.title = title
        self.showsRoadmap = showsRoadmap
        _path = State(initialValue: [])
    }

    /// Opens the board with one request already showing, for deep links and notifications.
    /// Back goes to the full board.
    ///
    /// - Parameters:
    ///   - featureId: The request's id, as shown in its URL on your public board.
    ///   - title: The board's navigation title. See `init(title:showsRoadmap:)`.
    ///   - showsRoadmap: See `init(title:showsRoadmap:)`.
    public init(featureId: String, title: String? = nil, showsRoadmap: Bool = false) {
        self.title = title
        self.showsRoadmap = showsRoadmap
        _path = State(initialValue: [featureId])
    }

    public var body: some View {
        guard let configuration = FeatureRequestKit.configuration else {
            fatalError("FeatureRequestBoardView was presented before FeatureRequestKit.configure(apiKey:) was called. Call FeatureRequestKit.configure(apiKey:) once, early in your app's lifecycle, before presenting this view.")
        }

        return NavigationStack(path: $path) {
            VStack(spacing: 0) {
                Picker(String(sdk: "Sort"), selection: $model.sort) {
                    ForEach(FeatureSort.visible(showsRoadmap: showsRoadmap), id: \.self) { sort in
                        Text(sort.displayName).tag(sort)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                content(background: configuration.theme.background)
            }
            .background(configuration.theme.background)
            .navigationTitle(model.navigationTitle(hostTitle: title))
            .navigationDestination(for: String.self) { featureId in
                FeatureDetailView(featureId: featureId, boardModel: model)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isPresentingSubmit = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel(String(sdk: "Add a feature request"))
                }
            }
            .sheet(isPresented: $isPresentingSubmit) {
                SubmitFeatureView(model: model)
            }
            .task {
                // The shared model may remember a Roadmap tab from a board that showed one.
                if !showsRoadmap && model.sort == .roadmap {
                    model.sort = .top
                }
                async let loadFeatures: Void = model.load()
                async let loadConfig: Void = model.loadConfig()
                _ = await (loadFeatures, loadConfig)
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
                Label(String(sdk: "Something Went Wrong"), systemImage: "exclamationmark.triangle")
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
                Button(String(sdk: "Retry")) {
                    Task { await model.refresh() }
                }
            }
        } else if model.features.isEmpty && model.sort == .roadmap {
            ContentUnavailableView {
                Label(String(sdk: "Nothing on the Roadmap Yet"), systemImage: "map")
            } description: {
                Text(String(sdk: "Requests show up here once they're planned."))
            }
        } else if model.features.isEmpty {
            ContentUnavailableView {
                Label(String(sdk: "No Feature Requests Yet"), systemImage: "lightbulb")
            } description: {
                Text(String(sdk: "Be the first to suggest an idea."))
            } actions: {
                Button(String(sdk: "Request a Feature")) {
                    isPresentingSubmit = true
                }
            }
        } else {
            List {
                ForEach(model.features) { feature in
                    NavigationLink(value: feature.id) {
                        FeatureRowView(feature: feature, showsVoteCount: !model.boardConfig.hideVoteCounts) {
                            Task { await model.toggleVote(feature) }
                        }
                    }
                    .onAppear {
                        if model.shouldLoadMore(after: feature.id) {
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

                if model.boardConfig.showBranding {
                    PoweredByFooter()
                        .listRowSeparator(.hidden)
                        .listRowBackground(background)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .refreshable {
                async let features: Void = model.refresh()
                async let config: Void = model.loadConfig(force: true)
                _ = await (features, config)
            }
        }
    }
}
