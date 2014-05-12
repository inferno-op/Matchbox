//Heavily Inspired from https://www.shadertoy.com/view/XssGz8

#version 120

uniform float adsk_result_w, adsk_result_h;
uniform sampler2D adsk_results_pass1, adsk_results_pass2, adsk_results_pass4, adsk_results_pass5;
uniform float adsk_result_frameratio;
uniform int samples;
uniform vec2 center;
uniform vec2 position;
uniform float scale;
uniform float rotation;
uniform float barrel;
uniform bool premult_input;
uniform bool comp_over_front;
uniform bool repeat_texture;
uniform bool comp_over_back;
uniform int result;


bool isInTex( const vec2 coords )
{
        return coords.x >= 0.0 && coords.x <= 1.0 &&
                    coords.y >= 0.0 && coords.y <= 1.0;
}

vec2 barrel_distort(vec2 coords, vec2 center, float barrel, float multiplier)
{
	vec2 cc = coords - center;
	float dist = dot(cc, cc);
	coords = coords + cc * dist * barrel * multiplier;
	return coords;
}

vec2 translate(vec2 coords, vec2 center, vec2 position, float multiplier)
{
    position = position * vec2(multiplier);
    return coords - position;

}

vec2 uniform_scale(vec2 coords, vec2 center, float scale, float multiplier)
{
    scale = scale * multiplier + 100;

    vec2 ss = vec2(scale / vec2(100.0));

    return (coords - center) / ss + center;
}

vec2 rotate(vec2 coords, vec2 center, float rotation, float multiplier)
{
    rotation *= multiplier;
    mat2 rotationMatrice = mat2( cos(-rotation), -sin(-rotation), sin(-rotation), cos(-rotation) );

    coords -= center;
    coords.x *= adsk_result_frameratio;
    coords *= rotationMatrice;
    coords.x /= adsk_result_frameratio;
    coords += center;

    return coords;
}

vec2 warp(vec2 coords, vec2 center, float t, float multiplier)
{
	coords = translate(coords, center,  position * t, multiplier);
	coords = uniform_scale(coords, center, scale * t, multiplier);
	coords = barrel_distort(coords, center, -barrel * t, multiplier);
	coords = rotate(coords, center, -rotation * t, multiplier);

	return coords;
}

float sat( float t )
{
	return clamp( t, 0.0, 1.0 );
}

float linterp( float t ) {
	return sat( 1.0 - abs( 2.0*t - 1.0 ) );
}

float remap( float t, float a, float b ) {
	return sat( (t - a) / (b - a) );
}

vec4 spectrum_offset( float t ) {
	vec3 tmp;
	vec4 ret;
	float lo = step(t,0.5);
	float hi = 1.0-lo;
	float w = linterp( remap( t, 1.0/6.0, 5.0/6.0 ) );
	tmp = vec3(lo,1.0,hi) * vec3(1.0-w, w, 1.0-w);

	vec3 W = vec3(0.2125, 0.7154, 0.0721);
	vec3 lum = vec3(dot(tmp, W));

	ret = vec4(tmp, lum.r);

	return pow( ret, vec4(1.0/2.2) );
}

void main()
{	
	float reci_num_iter_f = 1.0 / float(samples);
	vec2 st = gl_FragCoord.xy / vec2( adsk_result_w, adsk_result_h);
	float warper = texture2D(adsk_results_pass5, st).r;

	vec4 sumcol = vec4(0.0);
	vec4 sumw = vec4(0.0);

	for (int i=0; i < samples; i++)
	{
		float t = float(i) * reci_num_iter_f;
		vec4 w = spectrum_offset( t );

		sumw += w;
		vec2 coords = warp(st, center, t,  warper);

		if (repeat_texture) {
			if (result == 0) {
				sumcol += w * texture2D(adsk_results_pass1, coords);
			} else {
				sumcol += w * texture2D(adsk_results_pass4, coords);
			}
		} else {
			if (isInTex(coords)) {
				if (result == 0) {
					sumcol += w * texture2D(adsk_results_pass1, coords);
				} else {
					sumcol += w * texture2D(adsk_results_pass4, coords);
				}
			}
		}
	}

	vec4 warped = (sumcol / sumw);
	vec4 comp = warped;

	if (result == 1) {
		vec4 front = texture2D(adsk_results_pass1, st);
		comp = warped * warped.a + front * (1.0 - warped.a);
		comp.a = warped.a;
	} else if (result == 2) {
		vec4 back = texture2D(adsk_results_pass2, st);
		comp = warped * warped.a + back * (1.0 - warped.a);
		comp.a = warped.a;
	}

	gl_FragColor = comp;
}
