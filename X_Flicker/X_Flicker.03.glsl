#version 120

uniform float adsk_result_w, adsk_result_h;
uniform sampler2D adsk_results_pass1;

uniform sampler2D LockFrame;

#extension GL_ARB_shader_texture_lod : enable

bool isInTex( const vec2 coords )
{
	    return coords.x >= 0.0 && coords.x <= 1.0 &&
		            coords.y >= 0.0 && coords.y <= 1.0;
}


vec2 uniform_scale(vec2 st, vec2 center, float scale)
{
	    vec2 ss = vec2(scale);

		    return (st - center) / ss + center;
}

void main(void)
{
	vec2 st = gl_FragCoord.xy / vec2( adsk_result_w, adsk_result_h);
	vec4 front = vec4(0.0);

	st = uniform_scale(st, vec2(.5), .05);

	float lum = dot(front, vec4(0.2125, 0.7154, 0.0721, 0.0));
	float lod = 4;

	float x = 0.0;
	float y = 1080.0;
	vec4 tmp1 = vec4(0.0);
	vec4 tmp2 = vec4(0.0);

	if (isInTex(st)) {
			while (x <= adsk_result_w) {
	
				tmp1 += texture2DLod(LockFrame, gl_FragCoord.xy / vec2(x, adsk_result_h), lod);

				x += 1.0;
			}

		tmp1 /= adsk_result_w;

		y = 0.0;
		x = 1920;
		while (y <= adsk_result_h) {
			tmp2 += texture2DLod(LockFrame, gl_FragCoord.xy / vec2(adsk_result_w, y), lod);
			
			y += 1.0;
		}

		tmp2 /= adsk_result_h;

		front = (tmp1 + tmp2) / 2.0;
	}

	gl_FragColor = front;
}
