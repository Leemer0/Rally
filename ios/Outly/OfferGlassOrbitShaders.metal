#include <metal_stdlib>
using namespace metal;

struct OfferOrbitVertexOut {
    float4 position [[position]];
    float2 uv;
};

struct OfferOrbitUniforms {
    float2 viewportSize;
    float time;
    float progress;
    float motion;
};

vertex OfferOrbitVertexOut offerOrbitVertex(uint vertexID [[vertex_id]]) {
    constexpr float2 positions[6] = {
        float2(-1.0, -1.0), float2( 1.0, -1.0), float2(-1.0,  1.0),
        float2(-1.0,  1.0), float2( 1.0, -1.0), float2( 1.0,  1.0)
    };
    constexpr float2 coordinates[6] = {
        float2(0.0, 1.0), float2(1.0, 1.0), float2(0.0, 0.0),
        float2(0.0, 0.0), float2(1.0, 1.0), float2(1.0, 0.0)
    };

    OfferOrbitVertexOut out;
    out.position = float4(positions[vertexID], 0.0, 1.0);
    out.uv = coordinates[vertexID];
    return out;
}

fragment half4 offerOrbitFragment(
    OfferOrbitVertexOut in [[stage_in]],
    constant OfferOrbitUniforms &uniforms [[buffer(0)]]
) {
    constexpr float pi = 3.14159265358979323846;
    constexpr float twoPi = pi * 2.0;
    constexpr float startAngle = twoPi - 0.15;
    constexpr float fullSweep = 5.76; // 330 degrees: intentionally open, never a fitness donut.
    constexpr float ellipseY = 0.99;
    constexpr float orbitRadius = 0.885;
    constexpr float tubeHalfWidth = 0.0375;
    constexpr float trackHalfWidth = 0.0115;

    float2 p = (in.uv - 0.5) * 2.0;
    p.x *= uniforms.viewportSize.x / max(uniforms.viewportSize.y, 1.0);

    // A restrained projection makes the tube feel dimensional without flattening
    // the timer into a sci-fi HUD.
    float2 q = float2(p.x, p.y / ellipseY);
    float radius = length(q);
    float radialDistance = radius - orbitRadius;
    float antialias = max(fwidth(radialDistance), 0.0015);

    float angle = atan2(q.y, q.x);
    if (angle < 0.0) {
        angle += twoPi;
    }

    float relativeAngle = angle - startAngle;
    if (relativeAngle < 0.0) {
        relativeAngle += twoPi;
    }

    // Avoid derivatives across atan2's 0 <-> 2pi discontinuity. Using the
    // physical pixel span keeps both open ends clean at every render scale.
    float normalizedPixel = 2.0 / max(min(uniforms.viewportSize.x, uniforms.viewportSize.y), 1.0);
    float angularAA = max((normalizedPixel / max(radius, 0.15)) * 1.5, 0.0015);
    float trackSegment = smoothstep(0.0, angularAA, relativeAngle)
        * (1.0 - smoothstep(fullSweep, fullSweep + angularAA, relativeAngle));
    float liveSweep = fullSweep * clamp(uniforms.progress, 0.0, 1.0);
    float liveSegment = smoothstep(0.0, angularAA, relativeAngle)
        * (1.0 - smoothstep(liveSweep, liveSweep + angularAA, relativeAngle));

    float startWrapped = fmod(startAngle, twoPi);
    float trackEndWrapped = fmod(startAngle + fullSweep, twoPi);
    float liveEndWrapped = fmod(startAngle + liveSweep, twoPi);
    float2 startPoint = orbitRadius * float2(cos(startWrapped), sin(startWrapped));
    float2 trackEndPoint = orbitRadius * float2(cos(trackEndWrapped), sin(trackEndWrapped));
    float2 liveEndPoint = orbitRadius * float2(cos(liveEndWrapped), sin(liveEndWrapped));

    float trackTube = 1.0 - smoothstep(
        trackHalfWidth,
        trackHalfWidth + antialias,
        abs(radialDistance)
    );
    float trackStartCap = 1.0 - smoothstep(
        trackHalfWidth,
        trackHalfWidth + antialias,
        length(q - startPoint)
    );
    float trackEndCap = 1.0 - smoothstep(
        trackHalfWidth,
        trackHalfWidth + antialias,
        length(q - trackEndPoint)
    );
    float trackMask = max(trackTube * trackSegment, max(trackStartCap, trackEndCap));

    float tube = 1.0 - smoothstep(
        tubeHalfWidth,
        tubeHalfWidth + antialias,
        abs(radialDistance)
    );
    float startCap = 1.0 - smoothstep(
        tubeHalfWidth,
        tubeHalfWidth + antialias,
        length(q - startPoint)
    );
    float liveEndCap = 1.0 - smoothstep(
        tubeHalfWidth,
        tubeHalfWidth + antialias,
        length(q - liveEndPoint)
    );
    float hasProgress = smoothstep(0.0, 0.002, uniforms.progress);
    float liveMask = max(tube * liveSegment, max(startCap, liveEndCap)) * hasProgress;

    float haloHalfWidth = tubeHalfWidth + 0.016;
    float haloTube = 1.0 - smoothstep(
        haloHalfWidth,
        haloHalfWidth + antialias,
        abs(radialDistance)
    );
    float startCapHalo = 1.0 - smoothstep(
        haloHalfWidth,
        haloHalfWidth + antialias,
        length(q - startPoint)
    );
    float liveEndCapHalo = 1.0 - smoothstep(
        haloHalfWidth,
        haloHalfWidth + antialias,
        length(q - liveEndPoint)
    );
    float liveHaloMask = max(
        haloTube * liveSegment,
        max(startCapHalo, liveEndCapHalo)
    ) * hasProgress;
    float exteriorHalo = max(liveHaloMask - liveMask, 0.0);

    // Analytic torus cross-section. The body stays intentionally translucent;
    // two narrow rails and the terminal rims do most of the visual work so the
    // orbit reads as hollow crystal on black instead of a smoky metal tube.
    float radial = clamp(radialDistance / tubeHalfWidth, -1.0, 1.0);
    float z = sqrt(max(0.0, 1.0 - radial * radial));
    float2 ellipseNormal = normalize(float2(q.x, q.y / (ellipseY * ellipseY)) + 0.0001);
    float3 normal = normalize(float3(ellipseNormal * radial, z));
    float lightDrift = sin(uniforms.time * 0.38) * 0.12 * uniforms.motion;
    float3 lightDirection = normalize(float3(-0.32 + lightDrift, -0.72, 1.18));
    float3 viewDirection = float3(0.0, 0.0, 1.0);
    float3 halfDirection = normalize(lightDirection + viewDirection);

    float diffuse = clamp(dot(normal, lightDirection) * 0.5 + 0.5, 0.0, 1.0);
    float specular = pow(max(dot(normal, halfDirection), 0.0), 58.0);
    float fresnel = pow(1.0 - z, 1.25);

    // Separate inner and outer rails. Their narrow profiles retain a crisp
    // one-pixel core at Retina scale, while the middle of the tube is nearly clear.
    float innerRailProfile = exp(-pow((radial + 0.79) * 6.2, 2.0));
    float outerRailProfile = exp(-pow((radial - 0.79) * 6.2, 2.0));
    float tubeRails = (innerRailProfile * 0.78 + outerRailProfile)
        * tube * liveSegment;

    // Round terminal faces get their own thin rim rather than inheriting the
    // tube's radial normal, which keeps both open ends clean and machined.
    float startCapRadius = length(q - startPoint) / tubeHalfWidth;
    float endCapRadius = length(q - liveEndPoint) / tubeHalfWidth;
    float startCapRim = exp(-pow((startCapRadius - 0.81) * 8.2, 2.0)) * startCap;
    float endCapRim = exp(-pow((endCapRadius - 0.81) * 8.2, 2.0)) * liveEndCap;
    float terminalRim = max(startCapRim, endCapRim) * hasProgress;
    float terminalFace = max(startCap, liveEndCap) * hasProgress;

    // A sparse caustic travels around the otherwise neutral glass. There is no
    // chromatic aberration: silver stays neutral and the lime endpoint owns color.
    float caustic = exp(-pow((radial + 0.24) * 5.8, 2.0))
        * (0.28 + 0.72 * max(-ellipseNormal.y, 0.0));
    float topLeftGlint = pow(
        max(dot(ellipseNormal, normalize(float2(-0.62, -0.78))), 0.0),
        18.0
    );
    float lowerGlint = pow(
        max(dot(ellipseNormal, normalize(float2(0.12, 0.99))), 0.0),
        26.0
    );
    float movingGlint = pow(
        max(cos(relativeAngle - 4.2 - uniforms.time * 0.11 * uniforms.motion), 0.0),
        34.0
    );
    float circumferenceHighlight = max(
        topLeftGlint,
        max(lowerGlint * 0.82, movingGlint * 0.58)
    );
    float railHalo = exp(-pow((abs(radial) - 0.76) * 3.5, 2.0));
    float railMask = clamp(tubeRails + terminalRim, 0.0, 1.0);
    float bodyAlpha = liveMask
        * (0.16 + diffuse * 0.04 + fresnel * 0.16 + caustic * 0.11 + railHalo * 0.04);
    float railAlpha = railMask
        * (0.88 + specular * 0.12 + circumferenceHighlight * 0.18);
    float terminalAlpha = terminalFace * 0.38 + terminalRim * 0.94;
    float liveAlpha = max(bodyAlpha, max(railAlpha, terminalAlpha));

    float3 bodySilver = float3(0.79, 0.795, 0.805);
    float3 railSilver = float3(0.985, 0.988, 0.99);
    float highlight = clamp(
        railMask * 0.92
        + specular * liveMask * 0.28
        + caustic * 0.20
        + circumferenceHighlight * railMask * 0.36,
        0.0,
        1.0
    );
    float3 glassColor = mix(bodySilver, railSilver, highlight);

    // The inactive remainder is only a hairline registration track. It should
    // disappear into pure black until the viewer looks for it.
    float trackAlpha = trackMask * 0.055;
    float3 trackColor = float3(0.70, 0.71, 0.73);
    float alpha = max(max(trackAlpha, liveAlpha), exteriorHalo * (0.04 + circumferenceHighlight * 0.05));
    float liveWeight = liveAlpha / max(liveAlpha + trackAlpha, 0.0001);
    float3 result = mix(trackColor, glassColor, liveWeight);
    result = mix(result, railSilver, exteriorHalo * circumferenceHighlight * 0.22);

    // Restrained lime endpoint: a neutral crystalline collar with a tiny live core.
    float endpointDistance = length(q - liveEndPoint);
    float endpointGlow = (1.0 - smoothstep(0.032, 0.062, endpointDistance)) * hasProgress;
    float endpointShell = (1.0 - smoothstep(0.028, 0.040, endpointDistance)) * hasProgress;
    float endpointCore = (1.0 - smoothstep(0.009, 0.020, endpointDistance)) * hasProgress;
    float3 lime = float3(0.74, 1.0, 0.10);
    result += endpointGlow * lime * 0.025;
    result = mix(result, railSilver, endpointShell * 0.76);
    result = mix(result, lime, endpointCore);
    alpha = max(alpha, endpointGlow * 0.05 + endpointShell * 0.84 + endpointCore);

    return half4(half3(clamp(result, 0.0, 1.0)), half(clamp(alpha, 0.0, 1.0)));
}
