#version 460

uniform sampler2D gtexture;
uniform sampler2D lightmap;
uniform sampler2D normals;
uniform sampler2D specular;
uniform sampler2D shadowtex0;

uniform vec3 shadowLightPosition;
uniform vec3 cameraPosition;

uniform mat4 gbufferModelViewInverse;
uniform mat4 modelViewMatrixInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;


uniform float viewHeight;
uniform float viewWidth;
uniform float near;
uniform float far;
uniform float dhNearPlane;
uniform float dhFarPlane;

/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 outColor0;

in vec2 texCoord;
in vec2 lightMapCoords;
in vec3 foliageColor;
in vec3 geoNormal;
in vec3 viewSpacePosition;
in vec4 tangent;

#include "/programs/functions.glsl"

void main() {

    //color in
    vec4 outputColorData = texture(gtexture, texCoord);
    vec3 albedo = pow(outputColorData.rgb ,vec3(2.2)) * pow(foliageColor,vec3(2.2));
    float transparency = outputColorData.a;
    if (transparency < .1) {
        discard;
    }

    vec3 outputColor = lightingCalc(albedo);

    
    float distanceFromCam = distance(viewSpacePosition, vec3(0));
    float dhBlend = smoothstep(far - 0.5 * far, far, distanceFromCam);
    transparency = mix(0.0, transparency, pow((1-dhBlend), 0.6));
    outColor0 = vec4(pow(outputColor, vec3(1/2.2)), transparency);
}