import Foundation
import AVFoundation

class MainViewModel: ObservableObject {
    @Published var player: AVAudioPlayer?
    @Published var isPlaying = false
    
    private let visualizerClient = VisualizerClient()

    func loadTrack() {
        // Load local or remote track here
        print("Loading track...")
    }

    func playAndVisualize() {
        // Example: load a local file
        guard let url = Bundle.main.url(forResource: "test", withExtension: "mp3") else {
            print("Could not load audio file")
            return
        }

        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
            player?.play()
            isPlaying = true
            
            // Simulate sending UDP based on visual data
            Task {
                await visualize()
            }
        } catch {
            print("Error playing audio: $error)")
        }
    }

    private func visualize() async {
        // TODO: Download .visual file, parse it, and send UDP frames
        print("Visualizing...")
    }
}
