#version 460



//uniforms
uniform sampler2D gtexture;
uniform sampler2D lightmap;
uniform sampler2D normals;
uniform sampler2D specular;
uniform sampler2D depthtex0;
uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;
uniform sampler2D colortex0; // screen color buffer
uniform float frameTimeCounter;

uniform mat4 gbufferModelViewInverse;
uniform mat4 modelViewMatrixInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;

uniform float far;
uniform float dhNearPlane;
uniform vec3 shadowLightPosition; 
uniform vec3 cameraPosition;

uniform float viewHeight;
uniform float viewWidth;
uniform int renderStage;

//vertexToFragment
in vec2 texCoord;
in vec2 lightMapCoords;
in vec3 foliageColor;
in vec3 viewSpacePosition;
in vec4 tangent;
in float blockId;
in vec3 fragNormal;
in vec3 fragViewDir;

/*
const int colortex2Format = RGBA32F;
*/

/* DRAWBUFFERS:01234 */
layout(location = 0) out vec4 outColor0; //colortex0 - outcolor
layout(location = 1) out vec4 outColor1; //colortex1 - specular
layout(location = 2) out vec4 outColor2; //colortex2 - normal
layout(location = 3) out vec4 outColor3; //colortex3 - albedo
layout(location = 4) out vec4 outColor4; //colortex4 - skyLight


#include "/programs/functions.glsl"




void main() {

    //color in
    vec4 outputColorData = texture(gtexture, texCoord);
    float transparency = outputColorData.a;
    if (transparency < .1) {
        discard;
    }

    vec3 albedo = pow(outputColorData.rgb ,vec3(2.2)) * pow(foliageColor,vec3(2.2));
    vec3 specTex = texture(specular, texCoord).rgb;
    vec4 normalTex = texture(normals, texCoord) * 2.0 - 1.0;


    //space conversions as well as normal and tangent calculations
    mat3 invModelView = mat3(gbufferModelViewInverse);
    vec3 fragFeetPlayerSpace = (gbufferModelViewInverse * vec4(viewSpacePosition,1.0)).xyz;
    vec3 fragWorldSpace = fragFeetPlayerSpace + cameraPosition;


    //geom and TBN
    vec3 differenceScreenX = dFdx(viewSpacePosition);
    vec3 differenceScreenY = dFdy(viewSpacePosition);
    vec3 v_spaceGeoNormal = normalize(cross(differenceScreenX,differenceScreenY));
    vec3 w_geoNormal = normalize(invModelView * v_spaceGeoNormal);


    vec3 viewSpaceTangent = normalize(tangent.xyz - dot(tangent.xyz,v_spaceGeoNormal)*v_spaceGeoNormal);
    vec3 w_tangent = invModelView * tangent.xyz;
    mat3 TBN = tbnNormalTangent(v_spaceGeoNormal, viewSpaceTangent);
    // vec4 normalData = texture(normals, texCoord)*2.0-1.0;


    vec3 n_spaceNormal = vec3(normalTex.xy, sqrt(1.0 - dot(normalTex.xy, normalTex.xy)));
    // vec3 v_spaceNormal = TBN * n_spaceNormal;
    vec3 normalWorldSpace = normalize(invModelView * (TBN * n_spaceNormal));

    
    //sky light
    vec3 skyLight = pow(texture(lightmap,vec2(1.0/32.0,lightMapCoords.y)).rgb,vec3(2.2));

    bool isWater = (int(blockId + 0.5) == 1000);
    float reflectance = isWater ? 0.036 : specTex.g;
    float roughness = pow(1.0 - specTex.r, 2.0);
    vec3 finalSpecular = vec3(specTex.r, reflectance, specTex.b);
    if (isWater) {
        normalWorldSpace = w_geoNormal;
        finalSpecular.r = 0.9;
    }


    // vec3 specularData = texture(specular,texCoord).rgb;
    // float reflectance = specularData.g;
    // if (int(blockId + 0.5) == 1000) {
    //     normalWorldSpace = w_geoNormal;
    //     reflectance = 0.036;
    //     specularData.r = .9;
    // }
    // specularData.g = reflectance;

    

    //lighting
    vec3 outputColor = lightingCalc(albedo, w_tangent, normalWorldSpace, w_geoNormal, skyLight, fragFeetPlayerSpace, fragWorldSpace, frameTimeCounter);
    //dh blend
    float distanceFromCam = length(viewSpacePosition);
    float dhBlend = smoothstep(far-0.5*far, far, distanceFromCam);
    float finalAlpha = isWater ? mix(0.0, transparency, pow(1.0 - dhBlend, 0.6)) : transparency;
    // if (int(blockId + 0.5) == 1000) {
    //     transparency = mix(0.0, transparency, pow((1-dhBlend), 0.6));
    // }



    //rim lighting
    // vec3 LightColor = texture2D(lightmap, lightMapCoords).rgb;
    // float blockLight = LightColor.g;

    
    // vec3 fragNormalize = normalize(fragNormal);

    // float rim = 1.0 - max(dot(fragNormalize, fragViewDir), 0.0);
    // rim = pow(rim, 4.0);

    // float flicker = sin(frameTimeCounter * 5.0) * 0.05 + 0.95;
    // vec3 rimColor = vec3(.5, .4, 0.2) * flicker;

    // float distanceFade = clamp(1.0 - (distanceFromCam / 20.0), 0.0, 1.0);
    // if (blockLight > 0.5) {
    //     outputColor += rim * rimColor * blockLight * distanceFade;
    // }
    


    //output colors
    outColor0 = vec4(pow(outputColor, vec3(1.0/2.2)), finalAlpha);
    outColor1 = vec4(finalSpecular,1.0);
    outColor2 = vec4(normalWorldSpace*.5+.5,1.0);
    outColor3 = vec4(albedo,1.0);
    outColor4 = vec4(skyLight,1.0);
    
    
}