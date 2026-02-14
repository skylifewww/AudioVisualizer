import SwiftUI

struct MainView: View {
    @StateObject private var viewModel = MainViewModel()

    var body: some View {
        VStack {
            Text("Music Visualizer")
                .font(.largeTitle)
            
            Button("Load Track") {
                viewModel.loadTrack()
            }
            
            Button("Play & Visualize") {
                viewModel.playAndVisualize()
            }
            
            Spacer()
        }
        .padding()
    }
}
