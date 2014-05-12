#version 120

uniform float adsk_result_w, adsk_result_h;
uniform sampler2D adsk_results_pass1, adsk_results_pass3, adsk_results_pass2;

vec2 uniform_scale(vec2 st, vec2 center, float scale)
{
    vec2 ss = vec2(scale / vec2(100.0));

    return (st - center) / ss + center;
}

void main(void)
{
	vec2 st = gl_FragCoord.xy / vec2( adsk_result_w, adsk_result_h);
	vec4 front = texture2D(adsk_results_pass1, st);
	st = uniform_scale(st, vec2(.5), 2000.0);

	vec4 ave_lum = texture2D(adsk_results_pass2, st);
	vec4 lock_frame = texture2D(adsk_results_pass3, st);

	vec4 lum = vec4(0.2125, 0.7154, 0.0721, 0.0);

	float a = dot(ave_lum, lum);
	float l = dot(lock_frame, lum);

	front *= l / a;

	gl_FragColor = front;
}
