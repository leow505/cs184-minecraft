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

mat3 tbnNormalTangent(vec3 normal, vec3 tangent) {
    vec3 bitangent = cross(tangent, normal);
    return mat3(tangent, bitangent, normal);
}

vec3 brdf(vec3 lightDir, vec3 viewDir, float roughness, vec3 normal, vec3 albedo, float metallic, vec3 reflectance) {
    float alpha = pow(roughness, 2);

    vec3 H = normalize(lightDir + viewDir);

    //dot products
    float NdotV = clamp(dot(normal, viewDir), 0.001, 1.0);
    float NdotL = clamp(dot(normal, lightDir), 0.001, 1.0);
    float NdotH = clamp(dot(normal, H), 0.001, 1.0);
    float VdotH = clamp(dot(viewDir, H), 0.001, 1.0);


    //fresnel
    vec3 F0 = reflectance;
    vec3 fresnelReflectance = F0 + (1.0 - F0) * pow(1.0 - VdotH, 5.0);

    //phong diffuse
    vec3 rhoD = albedo;
    rhoD *= (vec3(1.0) - fresnelReflectance);

    // rhoD *= (1 - metallic); //diffuse is 0 for metallic


    //geom attenuation
    float k = alpha/2.0;
    float geom = (NdotL / (NdotL*(1-k)+k)) * (NdotV / ((NdotV*(1-k)+k)));

    //distribution of microfacets
    float lowerTerm = pow(NdotH, 2) * (pow(alpha,2) - 1.0) + 1.0;
    float ndfGGX = pow(alpha, 2) / (3.14159 * pow(lowerTerm, 2));

    vec3 phongDiffuse = rhoD;
    vec3 cookTorrance = (fresnelReflectance*ndfGGX*geom)/(4.0 * NdotL * NdotV);

    vec3 BRDF = (phongDiffuse+cookTorrance)*NdotL;
    vec3 diffFunction = BRDF;

    return BRDF;
}

vec3 lightingCalc(vec3 albedo) {
    //normal and tangent calculations
    vec3 w_geoNormal = mat3(gbufferModelViewInverse) * geoNormal;
    vec3 w_tangent = mat3(gbufferModelViewInverse) * tangent.xyz;
    vec4 normalData = texture(normals, texCoord)*2.0-1.0;
    vec3 n_spaceNormal = vec3(normalData.xy, sqrt(1.0 - dot(normalData.xy, normalData.xy)));
    mat3 TBN = tbnNormalTangent(w_geoNormal, w_tangent);
    vec3 w_spaceNormal = TBN * n_spaceNormal;

    //material data
    vec4 specularData = texture(specular, texCoord);
    float perceptualSmoothness = specularData.r;
    float metallic = 0.0;
    vec3 reflectance = vec3(specularData.g);
    if (specularData.g * 255 > 229) {
        metallic = 1.0;
        reflectance  = albedo;
    } else {
        reflectance = vec3(specularData.g);
    }
    float roughness = pow(1.0 - perceptualSmoothness, 2.0);
    float smoothness = 1.0 - roughness;
    float shininess = (1+(smoothness) * 100);

    //space conversions
    vec3 fragFeetPlayerSpace = (gbufferModelViewInverse * vec4(viewSpacePosition, 1.0)).xyz;
    vec3 w_spaceFrag = fragFeetPlayerSpace + cameraPosition;
    vec3 fragShadowViewSpace = (shadowModelView * vec4(fragFeetPlayerSpace, 1.0)).xyz;
    vec4 fragHomoSpace = shadowProjection * vec4(fragShadowViewSpace, 1.0);
    vec3 fragshadowNDCSpace = fragHomoSpace.xyz / fragHomoSpace.w;
    vec3 fragshadowScreenSpace = fragshadowNDCSpace * 0.5 + 0.5;


    //directions
    vec3 shadowDir = normalize(mat3(gbufferModelViewInverse) * shadowLightPosition);
    vec3 ReflectDir = reflect(-shadowDir, w_spaceNormal);
    vec3 viewDir = normalize(cameraPosition - fragFeetPlayerSpace);
    

    //shadows
    float shadow = step(fragshadowScreenSpace.z - 0.001, texture(shadowtex0, fragshadowScreenSpace.xy).rgb).r;

    //ambient calculation
    vec3 ambientDir = w_geoNormal;
    float ambient_light = 0.2 * clamp(dot(ambientDir, w_spaceNormal),0.0,1.0);

    //brdf calculation
    vec3 outputColor = albedo * ambient_light + shadow*brdf(shadowDir, viewDir, roughness, w_spaceNormal, albedo, metallic, reflectance);
    
    //block and sky lighting
    vec3 lightColor = pow(texture(lightmap,lightMapCoords).rgb,vec3(2.2));
    outputColor *= lightColor;

    return outputColor;
}

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
    float dhBlend = smoothstep(far-0.5*far, far, distanceFromCam);
    transparency = mix(0.0, transparency, pow((1-dhBlend), 0.6));
    outColor0 = vec4(pow(outputColor, vec3(1/2.2)), transparency);
}