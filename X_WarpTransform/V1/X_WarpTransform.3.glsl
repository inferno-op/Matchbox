#version 120
#extension GL_ARB_shader_texture_lod : enable

uniform float adsk_result_w, adsk_result_h;
uniform sampler2D adsk_results_pass1, adsk_results_pass2;

void main()
{
    vec2 st = gl_FragCoord.xy / vec2( adsk_result_w, adsk_result_h);
    vec4 front = texture2D(adsk_results_pass1, st);
    vec4 matte = texture2D(adsk_results_pass2, st);
	vec4 premult = front * matte;

    gl_FragColor = vec4(premult.rgb, 1.0-matte.r);
}

