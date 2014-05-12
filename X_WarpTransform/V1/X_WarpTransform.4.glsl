#version 120
#extension GL_ARB_shader_texture_lod : enable

uniform float adsk_result_w, adsk_result_h;
uniform float adsk_result_frameratio;
uniform sampler2D adsk_results_pass2, adsk_results_pass1, adsk_results_pass3;
uniform vec2 translate;
uniform vec2 center;
uniform float radius;
uniform float angle;
uniform float scale;
uniform float uvmix;
uniform float rotation;
uniform int transform_order;
uniform int hardmatte;
uniform int output;
uniform int input_premult;
uniform int comp_output;


void main()
{
    vec2 st = gl_FragCoord.xy / vec2( adsk_result_w, adsk_result_h);
    vec2 sto = st;

    vec4 matte = texture2D(adsk_results_pass2, st);
    vec4 front = texture2D(adsk_results_pass1, st);

	vec2 toffset = vec2(-.5);

	st -= center;
	st /= scale;
	if (transform_order == 0) {
		st += center;
		st -= translate + toffset;
		st -= center;
	}

	float dist = length(st);

	if (dist < radius) {
		float percent = (radius - dist) / radius;
		float theta = percent * percent * angle;
		float s = sin(theta);
		float c = cos(theta);
		st = vec2(dot(st, vec2(c, -s)), dot(st, vec2(s, c)));
  	}

	mat2 rotationMatrice = mat2( cos(-rotation), -sin(-rotation),
                          sin(-rotation), cos(-rotation) );

	float ratio = adsk_result_frameratio;

   	st.x *= ratio;
   	st *= rotationMatrice;
   	st.x /= ratio;

	if (transform_order == 1) {
		st -= translate + toffset;
	}

	st += center;


	st = mix(st, sto, uvmix);

	if (output == 0) {
		float tmp = matte.r;
		if (hardmatte == 1) {
			if (tmp < .5) {
				tmp = 0.0;
			} else {
				tmp = 1.0;
			}
		}

		st = mix(sto, st, vec2(tmp));
	}

	vec4 warped = vec4(0.0);
	vec4 alpha = vec4(0.0);
	vec3 comp = vec3(0.0);

	if (input_premult == 0) {
   		warped = texture2D(adsk_results_pass1, st);
		alpha = warped.aaaa;
		comp = warped.rgb + front.rgb * (1.0 - abs(alpha.rgb));
		alpha = 1.0 - alpha;
	} else {
   		warped = texture2D(adsk_results_pass3, st);
		alpha = 1.0 - warped.aaaa;
		comp = warped.rgb + front.rgb * (1.0 - max(alpha.rgb, matte.rgb));
		alpha += 1.0 - matte;
	}

	alpha = clamp(alpha, 0.0, 1.0);

	if (comp_output == 1.0) {
		comp = comp + front.rgb * (1.0 - alpha.rgb);
	}

	gl_FragColor = vec4(comp, alpha.r);
}

