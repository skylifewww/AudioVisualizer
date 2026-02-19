import UIKit
import MetalKit
internal import AVFAudio

class VisualizationViewController: UIViewController {
    var metalView: MTKView!
    var device: MTLDevice!
    var renderer: ColumnRenderer!
    weak var viewModel: MainViewModel?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupMetal()
    }

    func setupMetal() {
        device = MTLCreateSystemDefaultDevice()
        guard device != nil else { fatalError("Metal not supported") }

        metalView = MTKView()
        metalView.device = device
        metalView.delegate = self
        metalView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
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
}

extension VisualizationViewController: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    func draw(in view: MTKView) {
        guard let descriptor = view.currentRenderPassDescriptor,
              let commandBuffer = renderer.commandQueue.makeCommandBuffer(),
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else { return }

        // Use proper synchronization based on AVPlayer.currentTime
        var amplitudes = [Float](repeating: 0.0, count: 32)
        if let player = viewModel?.player,
           let data = viewModel?.visualData,
           !data.frames.isEmpty {
            
            let currentMs = player.currentTime * 1000
            let progress = currentMs / Double(data.durationMs)
            let frameIndex = min(data.frames.count - 1,
                                 Int(progress * Double(data.frames.count)))

            amplitudes = data.frames[frameIndex].bars
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
