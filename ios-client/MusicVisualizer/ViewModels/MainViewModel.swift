import Foundation
import Combine
import AVFoundation
// import MediaPlayer

class MainViewModel: ObservableObject {
    @Published var player: AVAudioPlayer?
    @Published var isPlaying = false
    // @Published var selectedTrack: MPMediaItem?
    @Published var selectedTrack: String? // Temporary: use track name instead
    @Published var visualData: VisualData?

    private let visualizerClient = VisualizerClient()
    
    private func parseVisualFile(_ data: Data) -> VisualData? {
        guard data.count >= 16 else { return nil }
        
        let header = data.withUnsafeBytes { bytes in
            let version = Int(bytes[0])
            let flags = Int(bytes[1])
            // Parse FPS as little-endian 16-bit fixed point (8.8 format)
            let fpsRaw = Int(bytes[4]) | (Int(bytes[5]) << 8)
            let fps = Float(fpsRaw) / 256.0
            let frameCount = Int(bytes[8]) | (Int(bytes[9]) << 8) | (Int(bytes[10]) << 16) | (Int(bytes[11]) << 24)
            let durationMs = Int(bytes[12]) | (Int(bytes[13]) << 8) | (Int(bytes[14]) << 16) | (Int(bytes[15]) << 24)
            
            print("Header: version=\(version), fps=\(fps), frames=\(frameCount), duration=\(durationMs)")
            
            return (version, flags, fps, frameCount, durationMs)
        }
        
        let (version, flags, fps, frameCount, durationMs) = header
        let isCompact = (flags & 0x01) != 0
        let frameSize = isCompact ? 33 : 133 // uint8 vs float32
        
        guard data.count >= 16 + (frameCount * frameSize) else { return nil }
        
        var frames: [VisualFrame] = []
        let frameData = data.subdata(in: 16..<data.count)
        
        for i in 0..<frameCount {
            let offset = i * frameSize
            let frameBytes = Array(frameData[offset..<min(offset + frameSize, frameData.count)])
            
            if isCompact {
                // uint8 bars (0-255)
                let bars = frameBytes.map { Float($0) / 255.0 }
                let beat = frameBytes.count > 32 ? frameBytes[32] != 0 : false
                frames.append(VisualFrame(bars: bars, beat: beat))
            } else {
                // float32 bars
                var floatBars: [Float] = []
                for j in 0..<32 {
                    let floatOffset = j * 4
                    if floatOffset + 4 <= frameBytes.count {
                        let floatBytes = frameBytes[floatOffset..<floatOffset+4]
                        let value = floatBytes.withUnsafeBytes { bytes in
                            return Float(bitPattern: UInt32(bytes[0]) | (UInt32(bytes[1]) << 8) | (UInt32(bytes[2]) << 16) | (UInt32(bytes[3]) << 24))
                        }
                        floatBars.append(value)
                    }
                }
                let beat = frameBytes.count > 128 ? frameBytes[128] != 0 : false
                frames.append(VisualFrame(bars: floatBars, beat: beat))
            }
        }
        
        return VisualData(fps: Int(fps), durationMs: durationMs, frames: frames)
    }

    func loadTrack() {
        // Will be triggered via MediaPickerView (see below)
        // For now, use dummy track
        selectedTrack = "Test"
    }

    func playAndVisualize() {
        // guard let track = selectedTrack else { return }

        // let trackID = String(track.persistentID)
        let trackID = "Test" // Temporary: use fixed ID to match Test.visual file

        Task {
            do {
                print("Fetching visual data for track ID: \(trackID)")
                let data = try await visualizerClient.downloadVisualFile(for: trackID)
                
                // Parse binary .visual file
                self.visualData = parseVisualFile(data)
                print("Loaded \(visualData?.frames.count ?? 0) frames")

                // Start playback
                // if let url = track.value(forProperty: MPMediaItemPropertyAssetURL) as? URL {
                //     player = try AVAudioPlayer(contentsOf: url)
                //     player?.prepareToPlay()
                //     player?.play()
                //     isPlaying = true
                // }
                
                // Temporary: play dummy audio
                guard let url = Bundle.main.url(forResource: "Test", withExtension: "mp3") else {
                    print("Could not load audio file")
                    return
                }
                
                player = try AVAudioPlayer(contentsOf: url)
                player?.prepareToPlay()
                player?.play()
                isPlaying = true
            } catch {
                print("Error: \(error)")
            }
        }
    }

    func stopPlayback() {
        player?.stop()
        player = nil
        isPlaying = false
        visualData = nil
    }

    func sendUDPFrame(_ frame: VisualFrame) {
        visualizerClient.sendUDP(frame.bars, beat: frame.beat)
    }
}

