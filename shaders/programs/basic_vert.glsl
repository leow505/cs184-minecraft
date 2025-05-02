#version 460

//attributes of vertex
in vec3 vaPosition;  //vertex position
in vec2 vaUV0; // texture of vertex (from texture map)
in vec4 vaColor; // vertex color

//uniforms
uniform vec3 chunkOffset;
uniform mat4 modelViewMatrix;
uniform mat4 projectionMatrix;


out vec2 texCoord;
out vec3 foliageColor;

void main() {

    // values to send to frag shader
    texCoord = vaUV0;
    foliageColor = vaColor.rgb;

    gl_Position = projectionMatrix * modelViewMatrix * vec4(vaPosition+chunkOffset,1);
}