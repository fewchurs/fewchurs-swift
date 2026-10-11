import SwiftUI
import FeatureRequestKit

struct ContentView: View {
    @State private var isPresentingBoard = false
    @State private var isPresentingRoadmapBoard = false

    var body: some View {
        VStack(spacing: 16) {
            Button("Feature Requests") {
                isPresentingBoard = true
            }
            Button("Feature Requests with Roadmap") {
                isPresentingRoadmapBoard = true
            }
        }
        .buttonStyle(.borderedProminent)
        .sheet(isPresented: $isPresentingBoard) {
            FeatureRequestBoardView()
        }
        .sheet(isPresented: $isPresentingRoadmapBoard) {
            FeatureRequestBoardView(showsRoadmap: true)
        }
    }
}
