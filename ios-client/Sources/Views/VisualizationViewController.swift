import UIKit
import SwiftUI
import MetalKit

class VisualizationViewController: UIViewController {
    var metalView: MTKView!
    var device: MTLDevice!
    var renderer: ColumnRenderer!
    @ObservedObject var visualizerClient = VisualizerClient()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupMetal()
        loadVisualData()
    }

    func setupMetal() {
        device = MTLCreateSystemDefaultDevice()
        guard device != nil else {
            fatalError("Metal is not supported on this device")
        }

        metalView = MTKView()
        metalView.device = device
        metalView.delegate = self
        metalView.framebufferOnly = false
        metalView.clearColor = MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)

        view.addSubview(metalView)
        metalView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            metalView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            metalView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            metalView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            metalView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        renderer = ColumnRenderer(device: device)
    }

    func loadVisualData() {
        Task {
            let data = try? await visualizerClient.downloadVisualFile(for: "test_track")
            if let parsedData = visualizerClient.parseVisualData(data ?? Data()) {
                print("Loaded visual data with \(parsedData.frames.count) frames")
            }
        }
    }
}

extension VisualizationViewController: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    func draw(in view: MTKView) {
        guard let descriptor = view.currentRenderPassDescriptor,
              let commandBuffer = renderer.commandQueue.makeCommandBuffer(),
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
            return
        }

        // Simulate amplitude data (replace with real data later)
        var amplitudes = [Float](repeating: 0.0, count: renderer.numBars)
        for i in 0..<renderer.numBars {
            amplitudes[i] = sin(Float(i) * 0.5 + Float(CACurrentMediaTime())) * 0.5 + 0.5 // Animated sine wave
        }
        renderer.update(amplitudes: amplitudes)

        renderEncoder.setRenderPipelineState(renderer.pipelineState)
        renderer.draw(in: renderEncoder)

        renderEncoder.endEncoding()

        if let drawable = view.currentDrawable {
            commandBuffer.present(drawable)
        }

        commandBuffer.commit()
    }
}
