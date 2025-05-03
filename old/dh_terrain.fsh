#version 460 compatibility

uniform sampler2D lightmap;
uniform sampler2D depthtex0;
uniform sampler2D dhDepthtex0;


uniform float viewHeight;
uniform float viewWidth;
uniform float near;
uniform float far;
uniform float dhNearPlane;
uniform float dhFarPlane;


uniform vec3 fogColor;
uniform vec3 shadowLightPosition;

uniform mat4 gbufferModelViewInverse;



/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 outColor0;

in vec4 blockColor;
in vec2 lightMapCoords;
in vec3 viewSpacePosition;
in vec3 geoNormal;

void main() {

    vec3 shadowDir = normalize(mat3(gbufferModelViewInverse) * shadowLightPosition);

    vec3 w_geoNormal = mat3(gbufferModelViewInverse) * geoNormal;

    // compares to see how close these vectors are pointing in the same direction, dictating how bright the object should be
    float brightness = clamp(dot(shadowDir, w_geoNormal), 0.2, 1.0); 
    vec3 lightColor = pow(texture(lightmap,lightMapCoords).rgb,vec3(2.2));

    //input color
    vec4 outputColorData = blockColor;
    vec3 outputColor = pow(outputColorData.rgb, vec3(2.2)) * lightColor;
    float transparency = outputColorData.a;
    if (transparency < .1) {
        discard;
    }
    vec2 texCoord = gl_FragCoord.xy / vec2(viewWidth, viewHeight);
    float depth = texture(depthtex0,texCoord).r;
    if(depth != 1.0){
        discard;
    }

    //fog
    float distanceFromCam = distance(vec3(0), viewSpacePosition);
    float maxFogDistance = 3500;
    float minFogDistance = 2000;

    outputColor *= brightness;

    float fogBlendValue = clamp((distanceFromCam - minFogDistance) / (maxFogDistance - minFogDistance),0,1);

    outputColor = mix(outputColor,pow(fogColor,vec3(2.2)),fogBlendValue);
    //output
    outColor0 = vec4(pow(outputColor, vec3(1/2.2)), transparency);
}