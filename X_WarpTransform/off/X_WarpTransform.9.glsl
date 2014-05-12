#version 120

// This code is taken directly from Kyle Obley's K_BlurMask v1.1 shader
//
// Pass #5: Vertical blur
//

uniform sampler2D adsk_results_pass5, adsk_results_pass8, adsk_results_pass7;
uniform float adsk_result_w, adsk_result_h, sigma, v_bias;
const float pi = 3.141592653589793238462643383279502884197969;

void main() {
    vec2 xy = gl_FragCoord.xy;
    vec2 px = vec2(1.0) / vec2(adsk_result_w, adsk_result_h);

    float v_sigma = sigma * 1.0;

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
        a += g.x * texture2D(adsk_results_pass8, (xy - vec2(0.0, float(i))) * px);
        a += g.x * texture2D(adsk_results_pass8, (xy + vec2(0.0, float(i))) * px);
        energy += 2.0 * g.x;
        g.xy *= g.yz;
    }
    a /= energy;

	vec2 st = gl_FragCoord.xy/vec2(adsk_result_w, adsk_result_h);
	vec4 front = texture2D(adsk_results_pass5, st);
	vec4 matte = texture2D(adsk_results_pass7, st);
	vec4 comp = mix(front, a, matte.a);

	
    gl_FragColor = vec4(comp.rgb, matte.a);
}
