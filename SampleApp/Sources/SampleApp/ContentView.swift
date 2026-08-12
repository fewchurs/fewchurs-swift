import SwiftUI
import FeatureRequestKit

struct ContentView: View {
    @State private var isPresentingBoard = false

    var body: some View {
        Button("Feature Requests") {
            isPresentingBoard = true
        }
        .sheet(isPresented: $isPresentingBoard) {
            FeatureRequestBoardView()
        }
    }
}
