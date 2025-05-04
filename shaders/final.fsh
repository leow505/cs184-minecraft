#version 460 compatibility

uniform sampler2D colortex0;
uniform vec2 viewSize;
uniform float frameTimeCounter;
uniform sampler2D gcolor;

in vec2 texcoord;
layout(location = 0) out vec4 color;

// mat3 aces_input_matrix = mat3(
//     vec3(0.59719f, 0.35458f, 0.04823f),
//     vec3(0.07600f, 0.90834f, 0.01566f),
//     vec3(0.02840f, 0.13383f, 0.83777f)
// );
// mat3 aces_output_matrix = mat3(
//     vec3( 1.60475f, -0.53108f, -0.07367f),
//     vec3(-0.10208f,  1.10813f, -0.00605f),
//     vec3(-0.00327f, -0.07276f,  1.07602f)
// );
// vec3 mul(mat3 m, vec3 v) {
//     float x = m[0][0] * v[0] + m[0][1] * v[1] + m[0][2] * v[2];
//     float y = m[1][0] * v[1] + m[1][1] * v[1] + m[1][2] * v[2];
//     float z = m[2][0] * v[1] + m[2][1] * v[1] + m[2][2] * v[2];
//     return vec3(x, y, z);
// }
// vec3 rtt_and_odt_fit(vec3 v) {
//     vec3 a = v * (v + 0.0245786f) - 0.000090537f;
//     vec3 b = v * (0.983729f * v + 0.4329510f) + 0.238081f;
//     return a / b;
// }
// vec3 aces_fitted(vec3 v) {
//     v = mul(aces_input_matrix, v);
//     v = rtt_and_odt_fit(v);
//     return mul(aces_output_matrix, v);
// }


vec3 ACESFilm(vec3 x) {
    const float a = 1.01;
    const float b = 0.01;
    const float c = 1.03;
    const float d = 0.59;
    const float e = 0.14;
    return clamp((x * (a * x + b)) / (x * (c * x + d) + e), 0.0, 1.0);
}

void main() {
    vec2 uv = texcoord;

    vec3 base = texture(colortex0, uv).rgb;

    if (base.r > 0.6 && base.g < 0.3 && base.b < 0.3) { // Boost red neon highlights
        base.rgb *= vec3(1.5, 1.0, 1.0); 
    } else if (base.r < 0.4 && base.g > 0.5 && base.b > 0.5) { // Boost cyan neon highlights
        base.rgb *= vec3(1.0, 1.2, 1.5); 
    } else if (base.r > 0.5 && base.g < 0.4 && base.b > 0.5) { // Boost magenta neon highlights
        base.rgb *= vec3(1.3, 1.0, 1.3);
    }

    

    //  Soft light / bloom-like blur (can optimize later)
    vec2 px = 1.0 / viewSize;
    vec3 blur = vec3(0.0);
    float total = 0.0;
    // for (int x = -7; x <= 7; ++x) {
    //     for (int y = -7; y <= 7; ++y) {
    //         float weight = 1.0 - length(vec2(x, y)) / 5.0;
    //         vec3 colorSample = texture(colortex0, uv + vec2(x, y) * px).rgb;
    //         blur += colorSample * weight;
    //         total += weight;
    //     }
    // }
    // blur /= total;
    for (int x = -2; x <= 2; ++x) {
        for (int y = -2; y <= 2; ++y) {
            vec2 offset = vec2(x, y) * px;
            blur += texture(colortex0, uv + offset).rgb;
        }
    }
    blur /= 25.0; // 5×5 kernel


    // Blend blurred result for softness
    vec3 softLight = mix(base, blur, 0.25); // adjust softness level

    // Filmic color grading
    vec3 graded = softLight;
    graded = pow(graded, vec3(0.9));          // film curve

    //saturation
    graded = mix(graded, vec3(dot(graded, vec3(0.3, 0.4, 0.3))), 0.2); // slight desaturation


    //ACES Filmic Tonemapping - two implementations
    // graded.b = max(graded.b, 0.0f);
    // graded = aces_fitted(graded);
    graded = ACESFilm(graded);


    //Vignette
    vec2 center = uv - 0.5;
    float vignette = smoothstep(0.8, 0.2, length(center)) * 0.8 + 0.2;
    graded *= vignette;

    //grain
    float grain = fract(sin(dot(gl_FragCoord.xy, vec2(12.9898,78.233))) * 43758.5453);
    graded.rgb += (grain - 0.5) * 0.05;


    


    color = vec4(pow(graded, vec3(1.0/0.9)), 1.0);
}
