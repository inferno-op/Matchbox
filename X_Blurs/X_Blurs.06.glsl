#version 120

uniform float adsk_result_w, adsk_result_h;
vec2 res = vec2(adsk_result_w, adsk_result_h);

uniform sampler2D adsk_results_pass5, adsk_results_pass4;


uniform float blur_amount;
uniform float v_bias;
float bias = v_bias;

const int dir = 0;

const float pi = 3.141592653589793238462643383279502884197969;

vec4 gblur(sampler2D source)
{
	vec2 xy = gl_FragCoord.xy;
  	vec2 px = vec2(1.0) / vec2(adsk_result_w, adsk_result_h);

	float strength = texture2D(adsk_results_pass5, gl_FragCoord.xy / res).r;

	float sigma = blur_amount * bias * strength + .001;
   
	int support = int(sigma * 3.0);

	vec3 g;
	g.x = 1.0 / (sqrt(2.0 * pi) * sigma);
	g.y = exp(-0.5 / (sigma * sigma));
	g.z = g.y * g.y;

	vec4 a = g.x * texture2D(source, xy * px);
	float energy = g.x;
	g.xy *= g.yz;

	for(int i = 1; i <= support; i++) {
		vec2 tmp = vec2(0.0, float(i));
		if (dir == 1) {
			tmp = vec2(float(i), 0.0);
		}

		a += g.x * texture2D(source, (xy - tmp) * px);
		a += g.x * texture2D(source, (xy + tmp) * px);
		energy += 2.0 * g.x;
		g.xy *= g.yz;
	}
	a /= energy;

	return vec4(a);
}

void main(void)
{

	gl_FragColor = gblur(adsk_results_pass4);
}
