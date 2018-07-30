precision highp float;

varying vec2 f_uv;

uniform sampler2D loli;
uniform float test;

void main(){
    gl_FragColor = vec4(texture2D(loli, f_uv).rgb, 1);

}
