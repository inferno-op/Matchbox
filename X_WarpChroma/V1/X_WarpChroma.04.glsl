uniform float adsk_result_w, adsk_result_h;
uniform sampler2D adsk_results_pass3;

void main()
{
	vec2 st = gl_FragCoord.xy / vec2( adsk_result_w, adsk_result_h);
	vec4 image = texture2D(adsk_results_pass3, st);
	image *= image.a;

	gl_FragColor = image;
}
