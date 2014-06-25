#version 120

uniform float adsk_result_w, adsk_result_h;
vec2 res = vec2(adsk_result_w, adsk_result_h);

uniform sampler2D LockFrame, Front;
uniform float lod;
uniform int operation;

#extension GL_ARB_shader_texture_lod : enable

void main(void)
{
	vec2 st = gl_FragCoord.xy / res;

	vec4 front = texture2D(Front, st);
	vec4 front_avg = texture2DLod(Front, st, lod);
	vec4 lock_frame = texture2DLod(LockFrame, st, lod);

	vec4 lum = vec4(0.2125, 0.7154, 0.0721, 0.0);

	float a = dot(front_avg, lum);
	float l = dot(lock_frame, lum);

	float new_gain = l / a;

	if (operation == 1) {
		new_gain = a / l;
		front = texture2D(LockFrame, st);
	}

	front *= new_gain;

	gl_FragColor = vec4(front.rgb, new_gain);
}
