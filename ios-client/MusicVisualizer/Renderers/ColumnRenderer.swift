import Metal
import simd

enum SpectrumMode: Int32 {
    case bottomUp = 0
    case centered = 1
}

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
    var spectrumMode: SpectrumMode = .bottomUp
    var modeBuffer: MTLBuffer?

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
        
        // mode buffer
        var initialMode = spectrumMode.rawValue
        modeBuffer = device.makeBuffer(bytes: &initialMode, length: MemoryLayout<Int32>.stride, options: [])
    }

    func update(amplitudes: [Float]) {
        guard amplitudes.count > 0 else { return }
        
        // Interpolate input amplitudes to 32 if necessary
        var interpolatedAmplitudes: [Float]
        
        if amplitudes.count == numBars {
            // Already correct size
            interpolatedAmplitudes = amplitudes
        } else if amplitudes.count < numBars {
            // Interpolate: stretch smaller array to fit numBars
            interpolatedAmplitudes = Array(repeating: 0.0, count: numBars)
            let step = Float(numBars) / Float(amplitudes.count)
            
            for i in 0..<amplitudes.count {
                let start = Int(Float(i) * step)
                let end = min(Int(Float(i + 1) * step), numBars)
                
                for j in start..<end {
                    interpolatedAmplitudes[j] = amplitudes[i]
                }
            }
        } else {
            // Truncate larger array
            interpolatedAmplitudes = Array(amplitudes.prefix(numBars))
        }

        // D) Fix "only min or max" loudness issue
        // Find max magnitude in current frame
        let frameMax = interpolatedAmplitudes.max() ?? 1.0
        let safeMax = max(frameMax, 0.0001)
        
        var processedAmplitudes = interpolatedAmplitudes
        for i in 0..<numBars {
            // Normalize relative to current frame
            var normalized = processedAmplitudes[i] / safeMax
            
            // Apply gentle curve
            normalized = pow(normalized, 0.6)
            
            processedAmplitudes[i] = max(0.0, min(normalized, 1.0))
        }
        
        // E) Smoothing
        for i in 0..<numBars {
            smoothedAmplitudes[i] += (processedAmplitudes[i] - smoothedAmplitudes[i]) * 0.25
        }
        
        // F) Update GPU amplitude buffer using smoothedAmplitudes
        guard let buffer = amplitudeBuffer else { return }
        memcpy(buffer.contents(), smoothedAmplitudes, MemoryLayout<Float>.stride * smoothedAmplitudes.count)
    }

    func draw(in renderEncoder: MTLRenderCommandEncoder) {
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.setVertexBuffer(amplitudeBuffer, offset: 0, index: 1)
        renderEncoder.setVertexBuffer(numBarsBuffer, offset: 0, index: 2)
        renderEncoder.setVertexBuffer(segmentsBuffer, offset: 0, index: 3)
        
        // Get current amplitudes from buffer
        var amplitudes = [Float](repeating: 0.0, count: numBars)
        if let bufferContents = amplitudeBuffer?.contents().assumingMemoryBound(to: Float.self) {
            for i in 0..<numBars {
                amplitudes[i] = bufferContents[i]
            }
        }
        
        // Peak hold logic
        for i in 0..<numBars {
            if smoothedAmplitudes[i] > peakLevels[i] {
                peakLevels[i] = smoothedAmplitudes[i]
            } else {
                peakLevels[i] = max(0.0, peakLevels[i] - peakFallSpeed)
            }
        }
        
        memcpy(peakBuffer?.contents(), peakLevels, MemoryLayout<Float>.stride * numBars)
        renderEncoder.setVertexBuffer(peakBuffer, offset: 0, index: 4)
        
        // Beat detection (average amplitude)
        let avg = smoothedAmplitudes.reduce(0, +) / Float(numBars)
        beatIntensity = min(1.0, avg * 1.5)
        
        var beatValue = beatIntensity
        memcpy(beatBuffer?.contents(), &beatValue, MemoryLayout<Float>.stride)
        renderEncoder.setFragmentBuffer(beatBuffer, offset: 0, index: 0)
        
        // G) Bind mode buffer every frame before draw
        var currentMode = spectrumMode.rawValue
        memcpy(modeBuffer?.contents(), &currentMode, MemoryLayout<Int32>.stride)
        renderEncoder.setVertexBuffer(modeBuffer, offset: 0, index: 5)

        // Draw segmented bars as triangles (including peak segments)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: numBars * (segments + 1) * 6)
    }
    
    // C) Add Public Toggle Function
    func toggleSpectrumMode() {
        spectrumMode = (spectrumMode == .bottomUp) ? .centered : .bottomUp
    }
}
