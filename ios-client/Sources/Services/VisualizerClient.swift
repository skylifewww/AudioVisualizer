import Foundation

class VisualizerClient: ObservableObject {
    private let baseURL = "http://localhost:3000"

    func downloadVisualFile(for trackID: String) async throws -> Data {
        let url = URL(string: "\(baseURL)/files/\(trackID).visual")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return data
    }

    func sendUDP(data: Data) {
        // TODO: Send UDP packet to ESP32
        print("Sending UDP data...")
    }
}
