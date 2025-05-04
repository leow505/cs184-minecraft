#include "/programs/distort.glsl"

mat3 tbnNormalTangent(vec3 normal, vec3 tangent) {
    vec3 bitangent = normalize(cross(tangent, normal));
    return mat3(tangent, bitangent, normal);
}


vec3 brdf(vec3 lightDir, vec3 viewDir, float roughness, vec3 normal, vec3 albedo, float metallic, vec3 reflectance, bool diffuseOnly, bool reflectionPass) {
    float alpha = roughness * roughness;

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

    rhoD *= (1 - metallic); //diffuse is 0 for metals


    //geom attenuation
    float k = alpha/2.0;
    float geom = (NdotL / (NdotL*(1-k)+k)) * (NdotV / ((NdotV*(1-k)+k)));

    //distribution of microfacets
    float alpha2 = alpha * alpha;
    float lowerTerm = pow(NdotH, 2) * (alpha2 - 1.0) + 1.0;
    float ndfGGX = alpha2 / (3.14159 * lowerTerm * lowerTerm);

    vec3 phongDiffuse = rhoD;
    vec3 cookTorrance = (fresnelReflectance*ndfGGX*geom)/(4.0 * NdotL * NdotV);

    vec3 BRDF = (phongDiffuse+cookTorrance)*NdotL;

    if (diffuseOnly) {
        BRDF = (phongDiffuse)*NdotL;
    }

    if (reflectionPass) {
        BRDF = fresnelReflectance;
    }


    vec3 diffFunction = BRDF;

    return BRDF;
}


vec3 lightingCalc(vec3 albedo, vec3 tangent, vec3 normalWorldSpace, vec3 worldGeoNormal, vec3 skyLight,vec3 fragFeetPlayerSpace,vec3 fragWorldSpace, float frameTimeCounter) {
    //material data
    vec4 specularData = texture(specular,texCoord);
    float perceptualSmoothness = specularData.r;
    float metallic = 0.0;
    vec3 reflectance = vec3(0);
    if (specularData.g*255 > 229) {
        metallic = 1.0;
        reflectance = albedo;
    } else {
        reflectance = vec3(specularData.g);
    }
    float roughness = pow(1.0 - perceptualSmoothness, 2.0);
    float smoothness = 1 - roughness;
    float shininess = (1+(smoothness) * 100);


    
    //space conversion
    vec3 adjustFragFeetPlayerSpace = fragFeetPlayerSpace + worldGeoNormal * .03;
    vec3 fragShadowViewSpace = (shadowModelView * vec4(adjustFragFeetPlayerSpace,1.0)).xyz;
    vec4 fragHomogeneousSpace = shadowProjection * vec4(fragShadowViewSpace,1.0);
    vec3 fragShadowNdcSpace = fragHomogeneousSpace.xyz/fragHomogeneousSpace.w;
    vec3 distortedFragShadowNdcSpace = vec3(distort(fragShadowNdcSpace.xy),fragShadowNdcSpace.z);
    vec3 fragShadowScreenSpace = distortedFragShadowNdcSpace * 0.5 + 0.5;



    //directions
    vec3 shadowDir = normalize(mat3(gbufferModelViewInverse) * shadowLightPosition);
    vec3 ReflectDir = reflect(-shadowDir, normalWorldSpace);
    vec3 viewDir = normalize(cameraPosition - fragWorldSpace);
    
    //shadow - 0 if in shadow, 1 if not
    float isInShadow = step(fragShadowScreenSpace.z, texture(shadowtex0, fragShadowScreenSpace.xy).r);
    float isInNonColoredShadow = step(fragShadowScreenSpace.z, texture(shadowtex1, fragShadowScreenSpace.xy).r);
    vec3 shadowColor = pow(texture(shadowcolor0, fragShadowScreenSpace.xy).rgb, vec3(2.2));
    
    vec3 shadowMult = vec3(1.0);

    //opt to change when comparing
    // shadowMult = mix(shadowMult, shadowColor, isInNonColoredShadow);
    // shadowMult *= isInShadow;


    if (isInShadow == 0.0) {
        if (isInNonColoredShadow == 0.0) {
            shadowMult = vec3(0.0);
        } else {
            shadowMult = shadowColor;
        }
    }

    float distanceFromPlayer = distance(fragFeetPlayerSpace, vec3(0.0));
    float shadowFade = clamp(smoothstep(100, 150, distanceFromPlayer), 0.0, 1.0);
    shadowMult = mix(shadowMult,vec3(1.0),shadowFade);

    //ambient calculation
    vec3 ambientDir = worldGeoNormal;
    vec3 blockLight = pow(texture(lightmap, vec2(lightMapCoords.x, 1.0/32.0)).rgb, vec3(2.2));
    vec3 ambientLight = (blockLight + 0.2*skyLight) * brdf(ambientDir, viewDir, roughness, normalWorldSpace, albedo, metallic, reflectance, true, false);



    //brdf
    vec3 outputColor = ambientLight + skyLight*shadowMult*brdf(shadowDir, viewDir, roughness, normalWorldSpace, albedo, metallic, reflectance, false, false);
    if (renderStage == MC_RENDER_STAGE_PARTICLES) {
        outputColor = ambientLight + skyLight*albedo;
    }
    


    return outputColor;
}