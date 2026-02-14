import Foundation

struct VisualFrame: Codable {
    let bars: [Float]
    let beat: Bool
}

struct VisualData: Codable {
    let fps: Int
    let durationMs: Int
    let frames: [VisualFrame]
}
