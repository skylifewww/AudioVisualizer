import Metal
import simd

struct ColumnVertex {
    var position: SIMD2<Float>
    var amplitude: Float
}

class ColumnRenderer {
    let device: MTLDevice
    let pipelineState: MTLRenderPipelineState
    var commandQueue: MTLCommandQueue

    var vertexBuffer: MTLBuffer?
    var amplitudeBuffer: MTLBuffer?
    var indexBuffer: MTLBuffer?

    let numBars: Int = 32
    let maxAmplitude: Float = 1.0

    init(device: MTLDevice) {
        self.device = device
        self.commandQueue = device.makeCommandQueue()!

        // Create pipeline
        let library = device.makeDefaultLibrary()!
        let vertexFunc = library.makeFunction(name: "columnVertexShader")!
        let fragmentFunc = library.makeFunction(name: "columnFragmentShader")!

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunc
        pipelineDescriptor.fragmentFunction = fragmentFunc
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            fatalError("Failed to create render pipeline: \(error)")
        }

        setupBuffers()
    }

    func setupBuffers() {
        // Create vertex data for quads (4 vertices per bar)
        var vertices: [ColumnVertex] = []
        for i in 0..<numBars {
            let x = Float(i) / Float(numBars) * 2.0 - 1.0
            let y = 0.0
            let w = 1.0 / Float(numBars)
            let h = 0.0

            // Each bar is a quad made of 4 vertices
            let quadVertices: [ColumnVertex] = [
                ColumnVertex(position: SIMD2(x, Float(y)), amplitude: 0.0),
                ColumnVertex(position: SIMD2(x + w, Float(y)), amplitude: 0.0),
                ColumnVertex(position: SIMD2(x, Float(y + h)), amplitude: 0.0),
                ColumnVertex(position: SIMD2(x + w, Float(y + h)), amplitude: 0.0)
            ]
            vertices.append(contentsOf: quadVertices)
        }

        vertexBuffer = device.makeBuffer(bytes: vertices, length: MemoryLayout<ColumnVertex>.stride * vertices.count, options: [])

        // Amplitude buffer
        var amplitudes = [Float](repeating: 0.0, count: numBars)
        amplitudeBuffer = device.makeBuffer(bytes: &amplitudes, length: MemoryLayout<Float>.stride * amplitudes.count, options: [])

        // Index buffer for drawing quads
        var indices: [UInt16] = []
        for i in 0..<numBars {
            let base = UInt16(i * 4)
            indices += [base, base + 1, base + 2, base + 1, base + 3, base + 2] // Two triangles per quad
        }

        indexBuffer = device.makeBuffer(bytes: indices, length: MemoryLayout<UInt16>.stride * indices.count, options: [])
    }

    func update(amplitudes: [Float]) {
        guard let buffer = amplitudeBuffer else { return }
        memcpy(buffer.contents(), amplitudes, MemoryLayout<Float>.stride * amplitudes.count)
    }

    func draw(in renderEncoder: MTLRenderCommandEncoder) {
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.setVertexBuffer(amplitudeBuffer, offset: 0, index: 1)
        renderEncoder.setFragmentBuffer(amplitudeBuffer, offset: 0, index: 1)

        if let indexBuffer = indexBuffer {
            renderEncoder.drawIndexedPrimitives(type: .triangle, indexCount: indexBuffer.length / MemoryLayout<UInt16>.stride, indexType: .uint16, indexBuffer: indexBuffer, indexBufferOffset: 0)
        }
    }
}
