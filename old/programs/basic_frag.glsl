
uniform sampler2D gtexture;
uniform sampler2D lightmap;
uniform sampler2D normals;
uniform sampler2D specular;

uniform vec3 shadowLightPosition;
uniform vec3 cameraPosition;

uniform mat4 gbufferModelViewInverse;
uniform mat4 modelViewMatrixInverse;


/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 outColor0;

in vec2 texCoord;
in vec2 lightMapCoords;
in vec3 foliageColor;


void main() {


    vec4 outputColorData = pow(texture(gtexture, texCoord),vec4(2.2));
    vec3 albedo = outputColorData.rgb * pow(foliageColor,vec3(2.2));
    
    float transparency = outputColorData.a;
    if (transparency < .1) {
        discard;
    }
    
    outColor0 = vec4(pow(albedo, vec3(1/2.2)), transparency);
}