#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float2 position;
    float amplitude;
};

struct VertexOut {
    float4 position [[position]];
    float2 uv;
};

vertex VertexOut columnVertexShader(
    uint vid [[vertex_id]],
    constant VertexIn *vertices [[buffer(0)]],
    constant float *amplitudes [[buffer(1)]],
    constant int &numBars [[buffer(2)]])
{
    VertexOut out;

    int barIndex = int(vid) / 4;
    int vertexIndex = int(vid) % 4;

    float barWidth = 2.0f / float(numBars);
    float barHeight = amplitudes[barIndex];

    float cornerX = float(vertexIndex % 2);
    float cornerY = float(vertexIndex / 2);

    float x = -1.0f + (float(barIndex) * barWidth) + (cornerX * barWidth);
    float y = -1.0f + cornerY * barHeight * 2.0f;

    out.position = float4(x, y, 0.0f, 1.0f);
    out.uv = float2(cornerX, cornerY);
    return out;
}

fragment half4 columnFragmentShader(VertexOut in [[stage_in]])
{
    return half4(1.0h, 0.0h, 0.0h, 1.0h);
}
