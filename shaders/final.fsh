#version 330 compatibility

uniform sampler2D colortex0;
uniform vec2 viewSize;
uniform float frameTimeCounter;

in vec2 texcoord;
layout(location = 0) out vec4 color;

void main() {
    vec2 uv = texcoord;

    vec3 base = texture(colortex0, uv).rgb;

    //  Soft light / bloom-like blur
    vec2 px = 1.0 / viewSize;
    vec3 blur = vec3(0.0);
    float total = 0.0;
    for (int x = -2; x <= 2; ++x) {
        for (int y = -2; y <= 2; ++y) {
            float weight = 1.0 - length(vec2(x, y)) / 5.0;
            blur += texture(colortex0, uv + vec2(x, y) * px).rgb * weight;
            total += weight;
        }
    }
    blur /= total;

    // Blend blurred result for softness
    vec3 softLight = mix(base, blur, 0.35); // adjust softness level

    // Filmic color grading
    vec3 graded = softLight;
    graded = pow(graded, vec3(0.9));          // film curve
    graded = mix(graded, vec3(dot(graded, vec3(0.3, 0.4, 0.3))), 0.05); // slight desaturation

    //Vignette
    vec2 center = uv - 0.5;
    float vignette = smoothstep(0.8, 0.2, length(center)) * 0.8 + 0.2;
    graded *= vignette;

    color = vec4(graded, 1.0);
}
