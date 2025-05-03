#version 460

//attributes
in vec3 vaPosition;
in vec2 vaUV0;

//uniforms
uniform mat4 modelViewMatrix;
uniform mat4 projectionMatrix;
uniform vec3 chunkOffset;



out vec2 lightMapCoords;
out vec2 texCoord;

void main() {
	texCoord = vaUV0;

	gl_Position = projectionMatrix * modelViewMatrix * vec4(vaPosition+chunkOffset,1);
}