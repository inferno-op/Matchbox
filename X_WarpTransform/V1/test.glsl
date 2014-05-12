#extension GL_ARB_shader_texture_lod : enable

uniform sampler2D matte;
uniform float antialias;
uniform float adsk_result_w, adsk_result_h;

void main()
{
	vec2 st = gl_FragCoord.xy / vec2( adsk_result_w, adsk_result_h );
	vec4 matte = texture2DLod(matte, st, antialias);

	gl_FragColor = matte;
}
