#version 120

uniform float adsk_result_w, adsk_result_h;
uniform float adsk_result_frameratio;
uniform sampler2D adsk_results_pass2, adsk_results_pass1, adsk_results_pass3, adsk_results_pass4, adsk_results_pass5;
uniform vec2 position;
uniform vec2 center;
uniform float radius;
uniform float angle;
uniform float scale;
uniform float rotation;
uniform int transform_order;
uniform bool hardmatte;
uniform int result;
uniform bool input_premult;
uniform bool comp_over_front;
uniform bool repeat_texture;

vec2 st = gl_FragCoord.xy / vec2( adsk_result_w, adsk_result_h);

bool isInTex( const vec2 coords )
{
        return coords.x >= 0.0 && coords.x <= 1.0 &&
                    coords.y >= 0.0 && coords.y <= 1.0;
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

vec2 twirl(vec2 coords, vec2 center, float radius, float angle, float multiplier)
{
	angle *= multiplier;
    coords -= center;

	float dist = length(coords);
	
	if (dist < radius) {
		float percent = (radius - dist) / radius;
		float theta = percent * percent * angle;
		float s = sin(theta);
		float c = cos(theta);
		coords = vec2(dot(coords, vec2(c, -s)), dot(coords, vec2(s, c)));
  	}

	coords += center;

	return coords;
}

vec2 get_coords(float multiplier) {
	vec2 coords = st;

	coords = translate(coords, center, position, multiplier);
	coords = uniform_scale(coords, center, scale, multiplier);
	coords = rotate(coords, center, rotation, multiplier);
	coords = twirl(coords, center, radius, angle, multiplier);

	return coords;
}

vec4 warp() {
	float warper = texture2D(adsk_results_pass5, st).r;

	vec2 coords = get_coords(warper);
	vec4 warped = vec4(0.0);

	if (repeat_texture) {
  		warped = texture2D(adsk_results_pass4, coords);

		if (result == 0) {
   			warped = texture2D(adsk_results_pass1, coords);
		}
	} else {
		if (isInTex(coords)) {
  			warped = texture2D(adsk_results_pass4, coords);
	
			if (result == 0) {
   				warped = texture2D(adsk_results_pass1, coords);
			}
		}
	}

	return warped;
}

void main()
{
    vec4 matte = texture2D(adsk_results_pass3, st);
    vec4 premult = texture2D(adsk_results_pass4, st);

	float tol = 1.0;

	vec2 around[8] = vec2[](
		vec2(-tol, tol), vec2(0.0, 1.0), vec2(tol, tol),
		vec2(-tol, 0.0), vec2(-tol, 0.0),
		vec2(-tol, -tol), vec2(0.0, -tol), vec2(-tol, -tol));

	vec4 tmp = texture2D(adsk_results_pass3, st);

	for (int i = 0; i < 8; i++) {
		if (tmp != vec4(0.0)) {
			tmp *= texture2D(adsk_results_pass3, st + around[i] / vec2( adsk_result_w, adsk_result_h));
		}
	}

	tmp = clamp(tmp, 0.0, 1.0);


	vec4 warped = vec4(0.0);
	vec4 comp = vec4(0.0);

	warped = warp();

	comp = warped;

	if (result == 1) {
    	vec4 back = texture2D(adsk_results_pass2, st);
		comp = comp + back * (1.0 - comp.a);
		if (comp.a != 1.0) {
			//comp.rgb = back.rgb;
		}
	} else  if (result == 2) {
		vec4 front = texture2D(adsk_results_pass1, st);
        comp = comp + front * (1.0 - comp.a);
        if (comp.a != 1.0) {
            //comp.rgb = front.rgb;
        }
    }

	comp.a = warped.a;
	gl_FragColor = comp;
}

