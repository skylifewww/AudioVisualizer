import Metal
import simd

class ColumnRenderer {
    let device: MTLDevice
    lazy var pipelineState: MTLRenderPipelineState = {
        let library = device.makeDefaultLibrary()!
        let vertexFunc = library.makeFunction(name: "columnVertexShader")!
        let fragmentFunc = library.makeFunction(name: "columnFragmentShader")!

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunc
        pipelineDescriptor.fragmentFunction = fragmentFunc
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

        do {
            return try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            fatalError("Failed to create pipeline: \(error)")
        }
    }()
    let commandQueue: MTLCommandQueue

    var vertexBuffer: MTLBuffer?
    var amplitudeBuffer: MTLBuffer?
    var numBarsBuffer: MTLBuffer?
    var segmentsBuffer: MTLBuffer?
    var peakBuffer: MTLBuffer?
    let numBars = 32
    let segments = 20
    var peakLevels: [Float] = []
    let peakFallSpeed: Float = 0.02
    var smoothedAmplitudes: [Float] = []
    let smoothingFactor: Float = 0.25
    var beatIntensity: Float = 0
    var beatBuffer: MTLBuffer?

    init(device: MTLDevice) {
        self.device = device
        self.commandQueue = device.makeCommandQueue()!
        
        peakLevels = Array(repeating: 0, count: numBars)
        smoothedAmplitudes = Array(repeating: 0, count: numBars)

        setupBuffers()
    }

    private func setupBuffers() {
        // Dummy vertex buffer (will be updated per frame)
        let vertices = [SIMD2<Float>](repeating: .zero, count: numBars * 4)
        vertexBuffer = device.makeBuffer(bytes: vertices, length: MemoryLayout<SIMD2<Float>>.stride * vertices.count, options: [])

        // Amplitude buffer
        let amplitudes = [Float](repeating: 0.0, count: numBars)
        amplitudeBuffer = device.makeBuffer(bytes: amplitudes, length: MemoryLayout<Float>.stride * amplitudes.count, options: [])
        
        // numBars constant buffer
        var numBarsValue = numBars
        numBarsBuffer = device.makeBuffer(bytes: &numBarsValue, length: MemoryLayout<Int>.stride, options: [])
        
        // segments constant buffer
        var segValue = segments
        segmentsBuffer = device.makeBuffer(bytes: &segValue, length: MemoryLayout<Int>.stride, options: [])
        
        // peak buffer
        peakBuffer = device.makeBuffer(length: MemoryLayout<Float>.stride * numBars, options: [])
        
        // beat intensity buffer
        var beatValue = beatIntensity
        beatBuffer = device.makeBuffer(bytes: &beatValue, length: MemoryLayout<Float>.stride, options: [])
    }

    func update(amplitudes: [Float]) {
        guard let buffer = amplitudeBuffer, amplitudes.count == numBars else { return }
        
        // Apply smoothing
        for i in 0..<numBars {
            smoothedAmplitudes[i] += (amplitudes[i] - smoothedAmplitudes[i]) * smoothingFactor
        }
        
        // Compute average amplitude for beat detection
        let avg = smoothedAmplitudes.reduce(0, +) / Float(numBars)
        beatIntensity = min(1.0, avg * 2.0)
        
        memcpy(buffer.contents(), smoothedAmplitudes, MemoryLayout<Float>.stride * smoothedAmplitudes.count)
    }

    func draw(in renderEncoder: MTLRenderCommandEncoder) {
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.setVertexBuffer(amplitudeBuffer, offset: 0, index: 1)
        renderEncoder.setVertexBuffer(numBarsBuffer, offset: 0, index: 2)
        renderEncoder.setVertexBuffer(segmentsBuffer, offset: 0, index: 3)
        
        // Update peak levels using smoothed amplitudes
        for i in 0..<numBars {
            if smoothedAmplitudes[i] > peakLevels[i] {
                peakLevels[i] = smoothedAmplitudes[i]
            } else {
                peakLevels[i] = max(0, peakLevels[i] - peakFallSpeed)
            }
        }
        
        memcpy(peakBuffer?.contents(), peakLevels, MemoryLayout<Float>.stride * numBars)
        renderEncoder.setVertexBuffer(peakBuffer, offset: 0, index: 4)
        
        // Update beat buffer
        memcpy(beatBuffer?.contents(), &beatIntensity, MemoryLayout<Float>.stride)
        renderEncoder.setVertexBuffer(beatBuffer, offset: 0, index: 5)

        // Draw segmented bars as triangles (including peak segments)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: numBars * (segments + 1) * 6)
    }
}
