#version 120

// This code is taken directly from Kyle Obley's K_BlurMask v1.1 shader
//

uniform sampler2D adsk_results_pass4;
uniform float adsk_result_w, adsk_result_h, edge_blur;
const float pi = 3.141592653589793238462643383279502884197969;
uniform float edge_strength;

void main() {
	vec2 xy = gl_FragCoord.xy;
	vec2 px = vec2(1.0) / vec2(adsk_result_w, adsk_result_h);
	float h_bias = 1.0;
	float es = 1.0 + edge_strength;

	float h_sigma1 = edge_blur * h_bias;
	
	int support = int(h_sigma1 * 3.0);

	// Incremental coefficient calculation setup as per GPU Gems 3
	vec3 g;
	g.x = 1.0 / (sqrt(2.0 * pi) * h_sigma1);
	g.y = exp(-0.5 / (h_sigma1 * h_sigma1));
	g.z = g.y * g.y;

	if(h_sigma1 == 0.0) {
		g.x = 1.0;
	}

	// Centre sample
	vec4 a = g.x * texture2D(adsk_results_pass4, xy * px);
	float energy = g.x;
	g.xy *= g.yz;

	// The rest
	for(int i = 1; i <= support; i++) {
		a += g.x * texture2D(adsk_results_pass4, (xy - vec2(float(i), 0.0)) * px);
		a += g.x * texture2D(adsk_results_pass4, (xy + vec2(float(i), 0.0)) * px);
		energy += 2.0 * g.x;
		g.xy *= g.yz;
	}
	a /= energy;

	gl_FragColor = vec4(a*es);
}
