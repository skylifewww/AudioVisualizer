#include <metal_stdlib>
using namespace metal;

struct VertexOut {
    float4 position [[position]];
    float2 uv;
};

vertex VertexOut columnVertexShader(
    uint vid [[ vertex_id ]],
    constant float* amplitudes [[ buffer(1) ]],
    constant int& numBars [[ buffer(2) ]],
    constant int& segments [[ buffer(3) ]],
    constant float* peaks [[ buffer(4) ]])
{
    uint verticesPerBar = (segments + 1) * 6; // +1 for peak segment
    uint barIndex = vid / verticesPerBar;
    uint localVertex = vid % verticesPerBar;

    uint segmentIndex = localVertex / 6;
    uint triangleVertex = localVertex % 6;

    float barWidth = 2.0 / float(numBars);
    float segmentHeight = 2.0 / float(segments);

    float barCenterX = -1.0 + float(barIndex) * barWidth + barWidth * 0.5;
    float x = barCenterX - barWidth * 0.4;

    bool isPeakSegment = (segmentIndex == segments);
    float normalizedHeight = isPeakSegment ? peaks[barIndex] : amplitudes[barIndex];
    float activeSegments = normalizedHeight * float(segments);

    bool segmentOn = !isPeakSegment && (float(segmentIndex) < activeSegments);

    float yBase = -1.0 + float(segmentIndex) * segmentHeight;

    float2 pos;
    float w = barWidth * 0.8;
    float h = segmentHeight * 0.9;

    if (!segmentOn && !isPeakSegment) {
        pos = float2(0.0, -2.0);
    } else if (isPeakSegment) {
        // Render white peak segment at peak height
        float peakY = -1.0 + peaks[barIndex] * 2.0;
        float peakH = segmentHeight * 0.3; // Thin white line
        
        if (triangleVertex == 0) pos = float2(x, peakY);
        else if (triangleVertex == 1) pos = float2(x, peakY + peakH);
        else if (triangleVertex == 2) pos = float2(x + w, peakY);
        else if (triangleVertex == 3) pos = float2(x, peakY + peakH);
        else if (triangleVertex == 4) pos = float2(x + w, peakY + peakH);
        else pos = float2(x + w, peakY);
    } else {
        if (triangleVertex == 0) pos = float2(x, yBase);
        else if (triangleVertex == 1) pos = float2(x, yBase + h);
        else if (triangleVertex == 2) pos = float2(x + w, yBase);
        else if (triangleVertex == 3) pos = float2(x, yBase + h);
        else if (triangleVertex == 4) pos = float2(x + w, yBase + h);
        else pos = float2(x + w, yBase);
    }

    VertexOut out;
    out.position = float4(pos, 0.0, 1.0);
    out.uv = float2(isPeakSegment ? 1.0 : 0.0, float(segmentIndex) / float(segments));
    return out;
}

fragment half4 columnFragmentShader(VertexOut in [[ stage_in ]],
                                     constant float& beat [[ buffer(0) ]]) {
    if (in.uv.x > 0.5) {
        // White peak segment
        return half4(1.0, 1.0, 1.0, 1.0);
    }
    
    float t = in.uv.y;

    float3 green = float3(0.0, 1.0, 0.0);
    float3 yellow = float3(1.0, 1.0, 0.0);
    float3 red = float3(1.0, 0.0, 0.0);

    float3 color;

    if (t < 0.7)
        color = mix(green, yellow, t / 0.7);
    else
        color = mix(yellow, red, (t - 0.7) / 0.3);

    // Add glow boost
    color += beat * 0.3;
    color = min(color, float3(1.0));

    return half4(half(color.r), half(color.g), half(color.b), 1.0);
}
