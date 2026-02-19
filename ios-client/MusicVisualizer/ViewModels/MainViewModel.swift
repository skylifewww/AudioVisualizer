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
        guard data.count >= 20 else { return nil } // Minimum header size: 5 * 4-byte integers

        // Read header using withUnsafeBytes for safety
        let headerValues = data.withUnsafeBytes { ptr in
            let version = ptr.load(fromByteOffset: 0, as: UInt32.self).littleEndian
            let isCompact = ptr.load(fromByteOffset: 4, as: UInt32.self).littleEndian != 0
            let fps = Float(ptr.load(fromByteOffset: 8, as: UInt32.self).littleEndian)
            let totalFrames = Int(ptr.load(fromByteOffset: 12, as: UInt32.self).littleEndian)
            let durationMs = Int(ptr.load(fromByteOffset: 16, as: UInt32.self).littleEndian)
            return (version, isCompact, fps, totalFrames, durationMs)
        }

        let (version, isCompact, fps, totalFrames, durationMs) = headerValues

        print("Header: version=\(version), isCompact=\(isCompact), fps=\(fps), frames=\(totalFrames), duration=\(durationMs)")

        let frameSize = isCompact ? 33 : 129 // 32 bars + 1 beat
        let expectedDataSize = totalFrames * frameSize
        guard data.count >= 20 + expectedDataSize else {
            print("Data size mismatch: expected \(20 + expectedDataSize), got \(data.count)")
            return nil
        }

        let frameData = data.subdata(in: 20..<(20 + expectedDataSize))
        var frames: [VisualFrame] = []

        for i in 0..<totalFrames {
            let offset = i * frameSize
            let frameSlice = frameData.subdata(in: offset..<(offset + frameSize))

            // Safely read beat flag using withUnsafeBytes
            let beat = frameSlice.withUnsafeBytes { ptr in
                ptr.load(fromByteOffset: isCompact ? 32 : 128, as: UInt8.self) != 0
            }

            // Safely read bars
            let bars: [Float]
            if isCompact {
                bars = frameSlice.withUnsafeBytes { ptr in
                    let uint8Ptr = ptr.bindMemory(to: UInt8.self).baseAddress!
                    return (0..<32).map { Float(uint8Ptr[$0]) / 255.0 }
                }
            } else {
                bars = frameSlice.withUnsafeBytes { ptr in
                    let uint8Ptr = ptr.bindMemory(to: UInt8.self).baseAddress!
                    return stride(from: 0, to: 128, by: 4).map { offset in
                        let uint32Value = UInt32(littleEndian: uint8Ptr.withMemoryRebound(to: UInt32.self, capacity: 1) { $0.advanced(by: offset / 4).pointee })
                        return Float(bitPattern: uint32Value)
                    }
                }
            }

            // Optional: Log first frame's bars for debugging
            if i == 0 {
                print("Frame \(i) size: \(frameSlice.count), expected: \(isCompact ? 33 : 129)")
                print("First frame bars (first 10): \(Array(bars.prefix(10)))")
            }

            frames.append(VisualFrame(bars: bars, beat: beat))
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

