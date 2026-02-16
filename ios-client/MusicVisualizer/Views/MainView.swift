import SwiftUI

struct MainView: View {
    @StateObject private var viewModel = MainViewModel()

    var body: some View {
        NavigationView {
            VStack {
                Text("Music Visualizer")
                    .font(.largeTitle)
                
                Button("Load Track") {
                    viewModel.loadTrack()
                }
                
                Button("Play & Visualize") {
                    viewModel.playAndVisualize()
                }

                NavigationLink(destination: VisualizationView()) {
                    Text("Show Visualization")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                Spacer()
            }
            .padding()
        }
    }
}
