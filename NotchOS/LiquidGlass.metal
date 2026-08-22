//
//  LiquidGlass.metal
//  NotchOS
//
//  Copyright © 2026 Ishan Gupta. MIT License.
//
//  Port of the liquid-glass optics from iyinchao/liquid-glass-studio
//  (src/shaders/fragment-main.glsl, STEP 8 branch) to a SwiftUI layer effect.
//  Same model: a rounded-rect SDF drives Snell refraction of the backdrop,
//  chromatic dispersion splits the sample per channel, and Fresnel + angular
//  glare terms brighten the rim.
//

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>

using namespace metal;

namespace liquidglass {

constant float PI = 3.14159265359;

// Superellipse corner, matching superellipseCornerSDF().
static float superellipseCorner(float2 p, float r, float n) {
    p = abs(p);
    float v = pow(pow(p.x, n) + pow(p.y, n), 1.0 / n);
    return v - r;
}

// roundedRectSDF() from lib/sdf.glsl: negative inside the shape.
static float roundedRectSDF(float2 p, float2 center, float2 size, float cornerRadius, float n) {
    p -= center;
    float cr = cornerRadius;
    float2 d = abs(p) - size * 0.5;

    if (d.x > -cr && d.y > -cr) {
        float2 cornerCenter = sign(p) * (size * 0.5 - float2(cr));
        return superellipseCorner(p - cornerCenter, cr, n);
    }
    return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
}

static float2 sdfNormal(float2 p, float2 center, float2 size, float radius, float roundness) {
    const float eps = 1.0;
    float dx = roundedRectSDF(p + float2(eps, 0.0), center, size, radius, roundness)
             - roundedRectSDF(p - float2(eps, 0.0), center, size, radius, roundness);
    float dy = roundedRectSDF(p + float2(0.0, eps), center, size, radius, roundness)
             - roundedRectSDF(p - float2(0.0, eps), center, size, radius, roundness);
    float2 g = float2(dx, dy);
    float len = max(length(g), 1e-5);
    return g / len;
}

static float safeAsin(float x) {
    return asin(clamp(x, -1.0, 1.0));
}

static float angleOf(float2 v) {
    float a = atan2(v.y, v.x);
    return a < 0.0 ? a + 2.0 * PI : a;
}

} // namespace liquidglass

using namespace liquidglass;

/// Refracts, disperses and lights `layer` as a slab of liquid glass.
///
/// Parameters mirror the reference implementation's controls:
/// thickness (refThickness), refFactor, dispersion (refDispersion),
/// fresnelRange / fresnelHardness / fresnelFactor, and
/// glareRange / glareHardness / glareFactor / glareConvergence /
/// glareOppositeFactor / glareAngle.
[[ stitchable ]] half4 liquidGlass(
    float2 position,
    SwiftUI::Layer layer,
    float2 size,
    float cornerRadius,
    float roundness,
    float thickness,
    float refFactor,
    float dispersion,
    float fresnelRange,
    float fresnelHardness,
    float fresnelFactorScale,
    float glareRange,
    float glareHardness,
    float glareFactorScale,
    float glareConvergence,
    float glareOppositeFactor,
    float glareAngleOffset
) {
    float2 center = size * 0.5;
    float sd = roundedRectSDF(position, center, size, cornerRadius, roundness);

    // Outside the pane: nothing to draw.
    if (sd > 0.0) {
        return half4(0.0h);
    }

    // Depth into the glass, in pixels (the shader's `nmerged`).
    float depth = -sd;

    // Snell refraction across the curved edge.
    float xRRatio = 1.0 - depth / max(thickness, 0.001);
    float thetaI = safeAsin(pow(max(xRRatio, 0.0), 2.0));
    float thetaT = safeAsin(sin(thetaI) / max(refFactor, 0.001));
    float edgeFactor = -tan(thetaT - thetaI);
    if (depth >= thickness) {
        edgeFactor = 0.0;
    }

    // `merged` normalised the way the reference does, so the range/hardness
    // controls keep their published meaning.
    float merged = sd / max(size.y, 1.0);

    float fresnel = clamp(
        pow(1.0 + merged * size.y / 1500.0 * pow(500.0 / max(fresnelRange, 0.001), 2.0) + fresnelHardness, 5.0),
        0.0, 1.0
    );
    float glareGeo = clamp(
        pow(1.0 + merged * size.y / 1500.0 * pow(500.0 / max(glareRange, 0.001), 2.0) + glareHardness, 5.0),
        0.0, 1.0
    );

    half4 color;

    if (edgeFactor <= 0.0) {
        color = layer.sample(position);
    } else {
        float2 normal = sdfNormal(position, center, size, cornerRadius, roundness);
        float2 offset = normal * edgeFactor * size.y * 0.05;

        // Chromatic dispersion: each channel refracts by a slightly different
        // amount (the reference's N_R / N_G / N_B split).
        float spread = dispersion * 0.35;
        half r = layer.sample(position - offset * (1.0 - 0.02 * spread)).r;
        half g = layer.sample(position - offset).g;
        half b = layer.sample(position - offset * (1.0 + 0.02 * spread)).b;
        half a = layer.sample(position - offset).a;
        color = half4(r, g, b, a);

        // Angular glare: brightest where the surface normal faces the light.
        float glareAngle = (angleOf(normal) - PI / 4.0 + glareAngleOffset) * 2.0;
        bool farside = (glareAngle > PI * 1.5 && glareAngle < PI * 3.5) || (glareAngle < -PI * 0.5);
        float glare = (0.5 + sin(glareAngle) * 0.5)
                    * (farside ? glareOppositeFactor : 1.2)
                    * glareFactorScale;
        glare = clamp(pow(max(glare, 0.0), 0.3 + glareConvergence * 1.5), 0.0, 1.0);

        color = mix(color, half4(1.0h), half(glare * glareGeo));
    }

    // Fresnel rim.
    color = mix(color, half4(1.0h), half(fresnel * fresnelFactorScale * 0.7));
    return color;
}
