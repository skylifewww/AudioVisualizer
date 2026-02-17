import Foundation
import Network

class VisualizerClient {
    private let baseURL = "http://localhost:3000"

    func downloadVisualFile(for trackID: String) async throws -> Data {
        let url = URL(string: "\(baseURL)/files/\(trackID).visual")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return data
    }

    func sendUDP(_ bars: [Float], beat: Bool, host: String = "192.168.4.1", port: UInt16 = 7777) {
        let packet: [String: Any] = [
            "bars": bars.map { Double($0) },
            "beat": beat ? 1 : 0,
            "frame": 0
        ]

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: packet, options: [])
            let connection = NWConnection(
                host: NWEndpoint.Host(host),
                port: NWEndpoint.Port(rawValue: port)!,
                using: .udp
            )

            connection.start(queue: .global(qos: .utility))
            connection.send(content: jsonData, completion: .contentProcessed { error in
                if let e = error {
                    print("UDP send failed: \(e)")
                } else {
                    print("UDP sent")
                }
            })
            connection.cancel()
        } catch {
            print("UDP error: \(error)")
        }
    }
}

