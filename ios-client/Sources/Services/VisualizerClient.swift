import Foundation
import Network

class VisualizerClient: ObservableObject {
    private let baseURL = "http://localhost:3000"
    private let udpConnection: NWConnection?

    init() {
        self.udpConnection = nil
    }

    func downloadVisualFile(for trackID: String) async throws -> Data {
        let url = URL(string: "\(baseURL)/files/\(trackID).visual")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return data
    }

    func parseVisualData(_ data: Data) -> VisualData? {
        // TODO: Implement parsing of binary .visual file
        // For now, return dummy data
        let frames = [VisualFrame(bars: Array(repeating: 0.5, count: 32), beat: false)]
        return VisualData(fps: 60, durationMs: 1000, frames: frames)
    }

    func sendUDP(to host: String = "192.168.4.1", port: UInt16 = 7777, data: Data) {
        let connection = NWConnection(
            host: NWEndpoint.Host(host),
            port: NWEndpoint.Port(rawValue: port)!,
            using: .udp
        )

        connection.start(queue: .global(qos: .utility))

        connection.send(content: data, completion: .contentProcessed { error in
            if let error = error {
                print("UDP send error: \(error)")
            } else {
                print("UDP packet sent successfully.")
            }
        })

        connection.cancel()
    }
}
