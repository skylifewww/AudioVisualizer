import Foundation
import AVFoundation
import SwiftUI
import Combine

class MainViewModel: ObservableObject {
    @Published var player: AVAudioPlayer?
    @Published var isPlaying = false

    private let visualizerClient = VisualizerClient()

    func loadTrack() {
        print("Loading track...")
    }

    func playAndVisualize() {
        guard let url = Bundle.main.url(forResource: "test", withExtension: "mp3") else {
            print("Could not load audio file")
            return
        }

        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
            player?.play()
            isPlaying = true

            Task {
                await visualize()
            }
        } catch {
            print("Error playing audio: \(error)")
        }
    }

    private func visualize() async {
        // TODO: Download .visual file, parse it, and send UDP frames
        // For now, simulate sending UDP frames every 16ms (60 FPS)

        let frame = VisualFrame(bars: Array(repeating: 0.5, count: 32), beat: false)
        let jsonData = try! JSONEncoder().encode(frame)
        visualizerClient.sendUDP(data: jsonData)
    }
}
