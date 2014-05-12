#version 120

uniform sampler2D front;
uniform float adsk_result_w, adsk_result_h;
uniform float red, yellow, green, cyan, blue, magenta;
uniform float red_s, yellow_s, green_s, cyan_s, blue_s, magenta_s;
uniform int matte_output;

vec3 rgb2hsv(vec3 c)
{
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
   
    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

vec4 msat(vec4 color, float sat) {
	vec3 hsv = rgb2hsv(color.rgb);
	hsv.g += sat;
	vec3 rgb = hsv2rgb(hsv);

	return vec4(rgb, 0.0);
}

vec4 mrot(vec4 color, float rot) {
	vec3 hsv = rgb2hsv(color.rgb);
	hsv.r += rot/360.0;
	vec3 rgb = hsv2rgb(hsv);

	return vec4(rgb, 0.0);
}

float get_m(vec4 color)
{
	color = msat(color, magenta_s);
	return clamp(min(color.r, color.b) - min(color.g, color.b), 0 , 1);
}

float get_y(vec4 color)
{
	color = msat(color, yellow_s);
	return clamp(min(color.r, color.g) - min(color.g, color.b), 0, 1);
}

float get_c(vec4 color)
{
	color = msat(color, cyan_s);
	return clamp(min(color.b, color.g) - min(color.g, color.r), 0 , 1);
}

float get_g(vec4 color)
{
	color = msat(color, green_s);
	return clamp(color.g - color.r - color.b, 0 , 1);
}

float get_r(vec4 color)
{
	color = msat(color, red_s);
	return clamp(color.r - color.g - color.b, 0 , 1);
}

float get_b(vec4 color)
{
	color = msat(color, blue_s);
	return clamp(color.b - color.g - color.r, 0 , 1);
}

void main()
{
	vec2 st = gl_FragCoord.xy / vec2( adsk_result_w, adsk_result_h);
	vec4 tex = texture2D(front, st);
	float alpha = 0.0;
	vec4 color = tex;

	color = mix(color, mrot(color, red), get_r(tex));
	color = mix(color, mrot(color, yellow), get_y(tex));
	color = mix(color, mrot(color, green), get_g(tex));
	color = mix(color, mrot(color, cyan), get_c(tex));
	color = mix(color, mrot(color, blue), get_b(tex));
	color = mix(color, mrot(color, magenta), get_m(tex));

	if (matte_output == 0) {
		alpha = get_r(tex);
	} else if (matte_output == 1) {
		alpha = get_g(tex);
	} else if (matte_output == 2) {
		alpha = get_b(tex);
	} else if (matte_output == 3) {
		alpha = get_c(tex);
	} else if (matte_output == 4) {
		alpha = get_m(tex);
	} else if (matte_output == 5) {
		alpha = get_y(tex);

	}

	gl_FragColor = vec4(color.rgb, alpha);
}
