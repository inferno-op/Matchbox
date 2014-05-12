#version 120

uniform float adsk_result_w, adsk_result_h;
uniform float adsk_result_frameratio;
uniform sampler2D adsk_results_pass2, adsk_results_pass4;
const float pi = 3.141592653589793238462643383279502884197969;
uniform float edge_tolerance;

float intensity(float color)
{
        //return sqrt((color.x*color.x)+(color.y*color.y)+(color.z*color.z));
        return(sqrt(color*color));
}

vec2 jitter(vec2 st) {
	st.x = sqrt(st.y * cos(2*pi*st.x));
	st.y = sqrt(st.y * sin(2*pi*st.x));

	return st;
}


float sobel(sampler2D input)
{
    vec2 st = gl_FragCoord.xy / vec2( adsk_result_w, adsk_result_h);

    float xlimit = edge_tolerance;
	vec2 m;
	float xxx = adsk_result_frameratio;
	m.x = abs(st.x - .5);
	m.y = abs(st.y - .5);
    float xstep = .004 * m.x;
    float ystep = .004 * m.y;

    float tleft = intensity(texture2D(input,st + vec2(-xstep,ystep)).a);
    float left = intensity(texture2D(input,st + vec2(-xstep,0)).a);
    float bleft = intensity(texture2D(input,st + vec2(-xstep,-ystep)).a);
    float top = intensity(texture2D(input,st + vec2(0,ystep)).a);
    float bottom = intensity(texture2D(input,st + vec2(0,-ystep)).a);
    float tright = intensity(texture2D(input,st + vec2(xstep,ystep)).a);
    float right = intensity(texture2D(input,st + vec2(xstep,0)).a);
    float bright = intensity(texture2D(input,st + vec2(xstep,-ystep)).a);



    float x = tleft + left + bleft - tright - right - bright;
    float y = -tleft - top - tright + bleft + bottom + bright;

    float color = sqrt((x*x) + (y*y));

    if (color > xlimit){
        return 0.0;
    } else {
        return 1.0;
    }
 }



void main()
{
    vec2 st = gl_FragCoord.xy / vec2( adsk_result_w, adsk_result_h);
    vec2 sto = st;
	vec3 front = texture2D(adsk_results_pass4, st).rgb;

	float a1 = sobel(adsk_results_pass2);
	float a2 = sobel(adsk_results_pass4);
	float a3 = a1 * a2;
	//a3 *= 5.0;
	a3 = clamp(a3, 0.0, 1.0);

	gl_FragColor = vec4(front, 1.0 - a3);
}

