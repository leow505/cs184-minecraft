#version 460
//attributes of vertex
in vec3 vaPosition;  //vertex position
in vec2 vaUV0; // texture of vertex (from texture map)
in vec4 vaColor; // vertex color
in ivec2 vaUV2; // light color of vertex (from light map)
in vec3 vaNormal; // normal of vertex
in vec4 at_tangent;
in vec3 mc_Entity;

uniform vec3 chunkOffset;
uniform vec3 cameraPosition;

uniform mat3 normalMatrix;
uniform mat4 modelViewMatrix;
uniform mat4 projectionMatrix;
uniform mat4 gbufferModelViewInverse;


out vec2 texCoord;
out vec2 lightMapCoords;
out vec3 foliageColor;
out vec4 tangent;
out float blockId;
out vec3 viewSpacePosition;
out vec3 fragNormal;
out vec3 fragViewDir;

void main() {
    blockId = mc_Entity.x;

    tangent = vec4(normalize(normalMatrix * at_tangent.xyz), at_tangent.a);

    // values to send to frag shader
    texCoord = vaUV0;
    fragNormal = normalize(normalMatrix * vaNormal);
    
    foliageColor = vaColor.rgb;
    lightMapCoords = vaUV2 * (1.0 / 256.0) + (1.0 / 32.0);

    vec4 viewSpacePositionVec4 = modelViewMatrix * vec4(vaPosition+chunkOffset, 1.0);
    viewSpacePosition = viewSpacePositionVec4.xyz;
    
    fragViewDir = normalize(cameraPosition - viewSpacePosition);

    gl_Position = projectionMatrix * viewSpacePositionVec4;
}