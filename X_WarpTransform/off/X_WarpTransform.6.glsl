#version 120

// This code is taken directly from Kyle Obley's K_BlurMask v1.1 shader
//
// Pass #4: Horizontal blur
//

uniform sampler2D adsk_results_pass5;
uniform float adsk_result_w, adsk_result_h, sigma, v_bias;
const float pi = 3.141592653589793238462643383279502884197969;
uniform float edge_width;
uniform float adsk_result_frameratio;

void main() {
    vec2 xy = gl_FragCoord.xy;
    vec2 px = vec2(1.0) / vec2(adsk_result_w, adsk_result_h);


    float v_sigma = edge_width * 1.0;

    int support = int(v_sigma * 3.0);

    // Incremental coefficient calculation setup as per GPU Gems 3
    vec3 g;
    g.x = 1.0 / (sqrt(2.0 * pi) * v_sigma);
    g.y = exp(-0.5 / (v_sigma * v_sigma));
    g.z = g.y * g.y;

    if(v_sigma == 0.0) {
        g.x = 1.0;
    }

    // Centre sample
    vec4 a = g.x * texture2D(adsk_results_pass5, xy * px);
    float energy = g.x;
    g.xy *= g.yz;

    // The rest

    for(int i = 1; i <= support; i++) {
        a += g.x * texture2D(adsk_results_pass5, (xy - vec2(float(i), 0.0)) * px);
        a += g.x * texture2D(adsk_results_pass5, (xy + vec2(float(i), 0.0)) * px);
        energy += 2.0 * g.x;
        g.xy *= g.yz;
    }
    a /= energy;


	for (int i = 0; i < int(edge_width); i++) {
			a+=.5 * a;
	}

    gl_FragColor = clamp(a, 0.0, 1.0);
}
