#version 460 compatibility

out vec2 texCoord;
out vec3 foliageColor;

void main() {

    // values to send to frag shader
    texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    foliageColor = gl_Color.rgb;

    gl_Position = ftransform();
}