#version 120

uniform float adsk_result_w, adsk_result_h;
uniform sampler2D Front;

bool isInTex( const vec2 coords )
{
        return coords.x >= 0.0 && coords.x <= 1.0 &&
                    coords.y >= 0.0 && coords.y <= 1.0;
}


void main()
{
    vec2 st = gl_FragCoord.xy / vec2( adsk_result_w, adsk_result_h);
	vec4 front = vec4(0.0);

	if (isInTex(st)) {
    	front = texture2D(Front, st);
		front *= vec4(1.0);
	}


    gl_FragColor = front;
}

