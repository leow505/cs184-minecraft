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