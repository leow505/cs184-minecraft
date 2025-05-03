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
    vec3 albedo = pow(outputColorData.rgb ,vec3(2.2)) * pow(foliageColor,vec3(2.2));
    float transparency = outputColorData.a;
    if (transparency < .1) {
        discard;
    }


    //space conversions as well as normal and tangent calculations
    vec3 fragFeetPlayerSpace = (gbufferModelViewInverse * vec4(viewSpacePosition,1.0)).xyz;
    vec3 fragWorldSpace = fragFeetPlayerSpace + cameraPosition;

    vec3 differenceScreenX = dFdx(viewSpacePosition);
    vec3 differenceScreenY = dFdy(viewSpacePosition);
    vec3 v_spaceGeoNormal = normalize(cross(differenceScreenX,differenceScreenY));
    vec3 w_geoNormal = mat3(gbufferModelViewInverse) * v_spaceGeoNormal;
    vec3 viewSpaceInitialTangent = tangent.xyz;
    vec3 viewSpaceTangent = normalize(viewSpaceInitialTangent - dot(viewSpaceInitialTangent,v_spaceGeoNormal)*v_spaceGeoNormal);
    vec3 w_tangent = mat3(gbufferModelViewInverse) * tangent.xyz;
    vec4 normalData = texture(normals, texCoord)*2.0-1.0;
    vec3 n_spaceNormal = vec3(normalData.xy, sqrt(1.0 - dot(normalData.xy, normalData.xy)));
    mat3 TBN = tbnNormalTangent(v_spaceGeoNormal, viewSpaceTangent);
    vec3 v_spaceNormal = TBN * n_spaceNormal;
    vec3 normalWorldSpace = mat3(gbufferModelViewInverse) * v_spaceNormal;

    vec3 specularData = texture(specular,texCoord).rgb;

    float reflectance = specularData.g;
    if (int(blockId + 0.5) == 1000) {
        normalWorldSpace = w_geoNormal;
        reflectance = 0.036;
        specularData.r = .9;
    }
    specularData.g = reflectance;

    //sky light
    vec3 skyLight = pow(texture(lightmap,vec2(1.0/32.0,lightMapCoords.y)).rgb,vec3(2.2));

    //lighting
    vec3 outputColor = lightingCalc(albedo, tangent.xyz, normalWorldSpace, w_geoNormal, skyLight, fragFeetPlayerSpace, fragWorldSpace, frameTimeCounter);
    //dh blend
    float distanceFromCam = distance(viewSpacePosition, vec3(0));
    float dhBlend = smoothstep(far-0.5*far, far, distanceFromCam);
    if (int(blockId + 0.5) == 1000) {
        transparency = mix(0.0, transparency, pow((1-dhBlend), 0.6));
    }

    //output colors
    outColor0 = vec4(pow(outputColor, vec3(1/2.2)), transparency);
    outColor1 = vec4(specularData,1.0);
    outColor2 = vec4(normalWorldSpace*.5+.5,1.0);
    outColor3 = vec4(albedo,1.0);
    outColor4 = vec4(skyLight,1.0);
    
    
}