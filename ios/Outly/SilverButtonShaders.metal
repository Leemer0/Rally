#include <metal_stdlib>
using namespace metal;

struct SilverButtonVertexOut {
    float4 position [[position]];
    float2 uv;
};

struct SilverButtonUniforms {
    float2 viewportSize;
    float time;
    float pressed;
    float enabled;
    float motion;
};

vertex SilverButtonVertexOut silverButtonVertex(uint vertexID [[vertex_id]]) {
    constexpr float2 positions[6] = {
        float2(-1.0, -1.0), float2( 1.0, -1.0), float2(-1.0,  1.0),
        float2(-1.0,  1.0), float2( 1.0, -1.0), float2( 1.0,  1.0)
    };
    constexpr float2 coordinates[6] = {
        float2(0.0, 1.0), float2(1.0, 1.0), float2(0.0, 0.0),
        float2(0.0, 0.0), float2(1.0, 1.0), float2(1.0, 0.0)
    };

    SilverButtonVertexOut out;
    out.position = float4(positions[vertexID], 0.0, 1.0);
    out.uv = coordinates[vertexID];
    return out;
}

fragment half4 silverButtonFragment(
    SilverButtonVertexOut in [[stage_in]],
    constant SilverButtonUniforms &uniforms [[buffer(0)]]
) {
    const float2 uv = in.uv;

    // A smooth convex chrome body; deliberately polished rather than brushed.
    const float verticalArc = 1.0 - abs(uv.y * 2.0 - 1.0);
    float luminance = mix(0.56, 0.82, pow(verticalArc, 0.48));
    luminance += 0.15 * exp(-pow((uv.y - 0.13) * 13.0, 2.0));
    luminance += 0.055 * exp(-pow((uv.y - 0.48) * 5.5, 2.0));
    luminance -= 0.10 * exp(-pow((uv.y - 0.91) * 10.0, 2.0));

    // The broad reflection travels slowly; it is frozen in a deliberate pose
    // whenever Reduce Motion is enabled.
    const float reflectionPhase = uniforms.motion > 0.5
        ? 0.5 + 0.5 * sin(uniforms.time * 0.27)
        : 0.52;
    const float reflectionCenter = mix(0.22, 0.78, reflectionPhase);
    const float diagonalCoordinate = uv.x + (uv.y - 0.5) * 0.16;
    const float broadReflection = exp(-pow((diagonalCoordinate - reflectionCenter) * 5.2, 2.0));
    const float sharpReflection = exp(-pow((diagonalCoordinate - reflectionCenter - 0.035) * 24.0, 2.0));
    const float whiteCore = exp(-pow((diagonalCoordinate - reflectionCenter - 0.042) * 48.0, 2.0));
    luminance += broadReflection * 0.16 + sharpReflection * 0.14 + whiteCore * 0.12;

    // Crisp internal bevels make the material read as an object, not a gradient.
    const float topBevel = exp(-uv.y * 48.0);
    const float bottomBevel = exp(-(1.0 - uv.y) * 42.0);
    const float sideBevel = exp(-min(uv.x, 1.0 - uv.x) * 65.0);
    luminance += topBevel * 0.16;
    luminance -= bottomBevel * 0.11;
    luminance -= sideBevel * 0.035;

    luminance *= mix(1.0, 0.91, uniforms.pressed);
    luminance = mix(0.44, luminance, mix(0.46, 1.0, uniforms.enabled));
    luminance = clamp(luminance, 0.34, 0.985);

    // Tiny cool and warm offsets at the moving specular edge create a premium
    // optical aberration without turning the chrome into a rainbow gradient.
    const float coolEdge = exp(-pow((diagonalCoordinate - reflectionCenter - 0.073) * 34.0, 2.0));
    const float warmEdge = exp(-pow((diagonalCoordinate - reflectionCenter + 0.018) * 38.0, 2.0));
    float3 silver = float3(luminance * 0.995, luminance, luminance * 1.01);
    silver += coolEdge * float3(0.018, 0.035, 0.075);
    silver += warmEdge * float3(0.055, 0.022, 0.006);
    silver = clamp(silver, 0.0, 1.0);
    return half4(half3(silver), 1.0h);
}
