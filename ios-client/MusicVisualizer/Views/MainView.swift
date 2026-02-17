import SwiftUI
// import MediaPlayer

struct MainView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @State private var showingMediaPicker = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("🎵 Music Visualizer")
                    .font(.title2)
                    .bold()

                Button("Load Track") {
                    viewModel.loadTrack()
                    // showingMediaPicker = true // Commented out to prevent crash
                }
                .buttonStyle(.borderedProminent)

                HStack(spacing: 20) {
                    Button("Play & Visualize") {
                        viewModel.playAndVisualize()
                    }
                    .disabled(viewModel.selectedTrack == nil || viewModel.isPlaying)
                    .buttonStyle(.bordered)
                    
                    Button("Stop") {
                        viewModel.stopPlayback()
                    }
                    .disabled(!viewModel.isPlaying)
                    .buttonStyle(.bordered)
                }

                NavigationLink("Show Visualization") {
                    VisualizationView()
                        .environmentObject(viewModel)
                }
                .buttonStyle(.bordered)

                Spacer()
            }
            .padding()
            // .sheet(isPresented: $showingMediaPicker) {
            //     MediaPickerView(selectedTrack: $viewModel.selectedTrack)
            // }
        }
    }
}
