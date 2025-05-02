#version 460

uniform sampler2D gtexture;
uniform sampler2D lightmap;
uniform mat4 gbufferModelViewInverse;

uniform vec3 shadowLightPosition;

layout(location = 0) out vec4 outColor0;

in vec2 texCoord;
in vec3 foliageColor;
in vec2 lightMapCoords;
in vec3 geoNormal;

void main() {
    vec3 shadowLightDirect = normalize(mat3(gbufferModelViewInverse) * shadowLightPosition);

    vec3 worldGeoNormal = mat3(gbufferModelViewInverse) * geoNormal;

    float lightBrightness = clamp(dot(shadowLightDirect, worldGeoNormal),0.2,1.0);

    vec3 lightColor = pow(texture(lightmap,lightMapCoords).rgb,vec3(2.2));
    vec4 outputColorData = pow(texture(gtexture, texCoord),vec4(2.2));
    vec3 outputColor = outputColorData.rgb * pow(foliageColor,vec3(2.2)) * lightColor;
    float transparency = outputColorData.a;
    if (transparency < .1) {
        discard;
    }
    outputColor *= lightBrightness;
    outColor0 =vec4(pow(outputColor,vec3(1/2.2)), transparency);
}