#define USE_MAP
precision highp float;

varying vec2 f_uv;

uniform sampler2D map;
uniform float test;

void main(){
    gl_FragColor = vec4(texture2D(map, f_uv).r, 0.4, 0.5, 1);

    
}
