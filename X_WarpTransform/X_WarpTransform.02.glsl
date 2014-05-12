#version 120

uniform float adsk_result_w, adsk_result_h;
uniform sampler2D Warp;

void main()
{
    vec2 st = gl_FragCoord.xy / vec2( adsk_result_w, adsk_result_h);
    vec3 warp = texture2D(Warp, st).rgb;

    gl_FragColor = vec4(warp, warp.r);
}

