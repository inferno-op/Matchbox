#version 120
#extension GL_ARB_shader_texture_lod : enable

uniform float adsk_time, adsk_result_w, adsk_result_h, adsk_result_frameratio;
vec2 res = vec2(adsk_result_w, adsk_result_h);

uniform sampler2D adsk_results_pass1, adsk_results_pass2, adsk_results_pass3, adsk_results_pass4, adsk_results_pass5;

uniform int process;
uniform int result;

uniform float zoom;

uniform bool show_swatch;
uniform vec2 swatch_center;
uniform float swatch_size;

uniform bool show_pallette;
uniform float pallette_detail;

uniform vec3 color;

uniform bool static_noise;
uniform bool color_noise;

uniform vec3 cb_color1, cb_color2;
uniform float checkerboard_freq;
uniform float cb_aspect;
uniform bool show_cbpallette;
uniform float cbpallette_detail;

uniform int colorbars_type;
uniform int colorbars_p;
uniform int colorbars_softness;
uniform bool blue_only;

uniform vec2 cw_center;
uniform float cw_size;
uniform float cw_val;
uniform float cw_aspect;

uniform int grad_type;
uniform int grad_fit;
uniform bool show_gpallette;
uniform float gpallette_detail;
uniform vec3 grad_color1;
uniform vec3 grad_color2;
uniform bool grad_rev;

uniform float shape_size;
uniform int shape_type;
uniform float shape_aspect;

uniform bool ssat;
uniform bool slum;
uniform bool shue;

vec2 texel = vec2(1.0) / res;


const vec3 lum_c = vec3(0.2125, 0.7154, 0.0721);

const vec3 white = vec3(1.0);
const vec3 black = vec3(0.0);
const vec3 red = vec3(1.0, 0.0, 0.0);
const vec3 green = vec3(0.0, 1.0, 0.0);
const vec3 blue = vec3(0.0, 0.0, 1.0);
const vec3 cyan = white - red;
const vec3 magenta = white - green;
const vec3 yellow = white - blue;

bool isInTex( const vec2 coords )
{
   return coords.x >= 0.0 && coords.x <= 1.0 &&
          coords.y >= 0.0 && coords.y <= 1.0;
}


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


float mag(vec2 v) {
    // find the magnitude of a vector
    return sqrt(v.x * v.x + v.y * v.y);
}

float get_angle(vec2 center_to_point2, vec2 coords_from_center)
{
    float angle = acos(dot(center_to_point2, coords_from_center) / (mag(center_to_point2) * mag(coords_from_center)));

    return angle;
}

float draw_circle(vec2 st, vec2 center, float size, float aspect)
{
	vec2 v2 = center - (center + vec2(size));
	v2.x *= adsk_result_frameratio;
	vec2 v3 = center - st;
	v3.x *= adsk_result_frameratio;
	v3.x /= aspect;

    float circle =  1.0 - smoothstep(length(v2) - .005, length(v2), length(v3));

    return circle;
}

vec3 colorwheel(vec2 st) {
	vec2 v2 = cw_center - vec2(cw_center.x - .01, cw_center.y);
	v2.x *= adsk_result_frameratio;

	vec2 v3 = cw_center - st;
	v3.x *= adsk_result_frameratio;

	vec2 v4 = cw_center - vec2(cw_center.x - cw_size * .25, cw_center.y);
	v4.x *= adsk_result_frameratio;

	float rad = distance(v4, v2);
	float d = distance(v3, v2);
	

	float angle_in_radians = get_angle(v2, v3);
	float circle = draw_circle(st, cw_center, cw_size * .25, cw_aspect);

	float angle_in_degrees = degrees(angle_in_radians);

	 if (cross(vec3(v2, 0.0), vec3(v3, 0.0)).z < 0.0) {
        angle_in_degrees = 360.0 - angle_in_degrees;
    }

	vec3 col = vec3(angle_in_degrees / 360.0);
	col.g =  d / rad;
	col.b = cw_val;

	return hsv2rgb(col) * vec3(circle);
}

vec2 scale(vec2 st, float scale_amnt, float aspect) {
	st -= vec2(.5);
	st = 2.0 * (st * scale_amnt);
	st.x *= aspect * adsk_result_frameratio;

	return st;
}

float luminance(vec3 col) {
	return clamp(dot(col, lum_c), 0.0, 1.0);
}

float random(vec2 co)
{
	float seed = adsk_time;

	if (static_noise) {
		seed = 1.0;
	}

	float a = 38.544846;
	float b = 321.468884635;
	float c = 48348.65468456;
	float dot= dot(co.xy * seed ,vec2(a,b));
	float sn= mod(dot,3.14);

	return fract(sin(sn) * c);
}

float noise(vec2 st) 
{
	vec2 p = scale(st, zoom / 100 * res.x, 1.0);
	return random(floor(p));
}

vec3 checkerboard(vec2 st, vec3 first, vec3 second)
{
	vec2 p = scale(st, checkerboard_freq * .25, cb_aspect);
	return mix(first, second, max(0.0, sign(sin(p.x)) * sign(sin(p.y))));
}

vec3 smpte2_colorbars(vec2 st)
{
	vec3 col = black;

	if (st.x < 1.0 / 7.0 * 1.0) {
		col = blue;
	} else if (st.x < 1.0 / 7.0 * 2.0) {
		col = black;
	} else if (st.x < 1.0 / 7.0 * 3.0) {
		col = magenta;
	} else if (st.x < 1.0 / 7.0 * 4.0) {
		col = black;
	} else if (st.x < 1.0 / 7.0 * 5.0) {
		col = cyan;
	} else if (st.x < 1.0 / 7.0 * 6.0) {
		col = black;
	} else if (st.x < 1.0 / 7.0 * 7.0) {
		col = white;
	}

	colorbars_p == 0 ? col *= vec3(.75) : col;

	return col;
}
vec3 smpte_colorbars(vec2 st)
{
	vec3 col = black;

	if (st.y < 1.0 / 4.0) {
		if (st.x < 1.0 / 6.0 * 1.0) {
			col = vec3(0.0, 0.11761, 0.47827);
			colorbars_p == 0 ? col *= vec3(.5) : col;
		} else if (st.x < 1.0 / 6.0 * 2.0) {
			col = white;
		} else if (st.x < 1.0 / 6.0 * 3.0) {
			col = vec3(0.2666, 0.0, 0.54492);
			if (colorbars_p == 0) {
				col.r *= .5;
				col.b *= .676081;
			}
		} else if (st.x < 1.0 / 6.0 * 4.0) {
			col = black;
		} else if (st.x < 1.0 / 6.0 * 5.0) {
			col = vec3(.03922);
		} else if (st.x < 1.0 / 6.0 * 6.0) {
			col = black;
		}
	} else {
		if (st.x < 1.0 / 7.0 * 1.0) {
			col = white;
		} else if (st.x < 1.0 / 7.0 * 2.0) {
			col = yellow;
		} else if (st.x < 1.0 / 7.0 * 3.0) {
			col = cyan;
		} else if (st.x < 1.0 / 7.0 * 4.0) {
			col = green;
		} else if (st.x < 1.0 / 7.0 * 5.0) {
			col = magenta;
		} else if (st.x < 1.0 / 7.0 * 6.0) {
			col = red;
		} else if (st.x < 1.0 / 7.0 * 7.0) {
			col = blue;
		}

		colorbars_p == 0 ? col *= vec3(.75) : col;
	}

	return col;
}

vec3 pal_colorbars(vec2 st)
{
	vec3 col = black;
	int allon = 0;

	if (st.y < 1.0 / 4.0) {
		if (st.x < 1.0 / 8.0 * 1.0) {
			col = white;
			colorbars_p == 0 ? col *= vec3(.75) : col;
		} else if (st.x < 1.0 / 8.0 * 2.0) {
			col = vec3(.88232);
			colorbars_p == 0 ? col = vec3(.66260) : col;
		} else if (st.x < 1.0 / 8.0 * 3.0) {
			col = vec3(.69775);
			colorbars_p == 0 ? col = vec3(.52539) : col;
		} else if (st.x < 1.0 / 8.0 * 4.0) {
			col = vec3(.58398);
			colorbars_p == 0 ? col = vec3(.43921) : col;
		} else if (st.x < 1.0 / 8.0 * 5.0) {
			col = vec3(.41162);
			colorbars_p == 0 ? col = vec3(.30566) : col;
		} else if (st.x < 1.0 / 8.0 * 6.0) {
			col = vec3(.29785);
			colorbars_p == 0 ? col = vec3(.22351) : col;
		} else if (st.x < 1.0 / 8.0 * 7.0) {
			col = vec3(.11371);
			colorbars_p == 0 ? col = vec3(.08234) : col;
		} else if (st.x < 1.0 / 8.0 * 8.0) {
			col = black;
		}
	} else {
		if (st.x < 1.0 / 8.0 * 1.0) {
			col = white;
		} else if (st.x < 1.0 / 8.0 * 2.0) {
			col = yellow;
			colorbars_p == 0 ? col *= vec3(.75) : col;
		} else if (st.x < 1.0 / 8.0 * 3.0) {
			col = cyan;
			colorbars_p == 0 ? col *= vec3(.75) : col;
		} else if (st.x < 1.0 / 8.0 * 4.0) {
			col = green;
			colorbars_p == 0 ? col *= vec3(.75) : col;
		} else if (st.x < 1.0 / 8.0 * 5.0) {
			col = magenta;
			colorbars_p == 0 ? col *= vec3(.75) : col;
		} else if (st.x < 1.0 / 8.0 * 6.0) {
			col = red;
			colorbars_p == 0 ? col *= vec3(.75) : col;
		} else if (st.x < 1.0 / 8.0 * 7.0) {
			col = blue;
			colorbars_p == 0 ? col *= vec3(.75) : col;
		} else if (st.x < 1.0 / 8.0 * 8.0) {
			col = black;
			colorbars_p == 0 ? col *= vec3(.75) : col;
		}
	}

	return col;
}

vec3 colorbars(vec2 st) 
{
	vec3 bars;
	if (colorbars_type == 0) {
		bars = smpte_colorbars(st);
	} else if (colorbars_type == 1) {
		bars = pal_colorbars(st);
	} else if (colorbars_type == 2) {	
		bars = smpte_colorbars(st);
		if (st.y > .25 && st.y < .35) {
			bars = smpte2_colorbars(st);
		}
	}

	if (blue_only) {
		bars.rg = vec2(bars.b);
	}

	return bars;
}

float is_perpendicular(vec2 point_from_center, vec2 coords_from_center)
{
    float scale_vector = 1000.0;
    float width = 10.0;

    float dot1 = 1.0 - abs(dot(normalize(point_from_center) / width, coords_from_center * scale_vector));

    return dot1;
}


float is_parallel(vec3 point_from_center, vec3 coords_from_center)
{
    float scale_vector = 1000.0;

    float para = 1.0 - abs(cross(normalize(point_from_center) / 1, coords_from_center * scale_vector).z);

    return para;
}


vec4 gradient(vec2 st) {
	vec3 col = vec3(st.x);

	vec3 c1 = grad_color1;
	vec3 c2 = grad_color2;

	if (grad_rev) {
		vec3 t = c1;
		c1 = c2;
		c2 = t;
	}

	if (grad_type == 1) {
		col = vec3(st.y);
	} else if (grad_type == 2) {
		st -= vec2(.5);
		if (grad_fit == 0) {
			st.x *= adsk_result_frameratio;
			st /= .5;
		} else if (grad_fit == 2) {
			st /= .5;
		} else if (grad_fit == 1) {
			st.y /= adsk_result_frameratio;
			st /= .5;
		}

		st += vec2(.5);
		col = vec3(1.0 - distance(vec2(.5), st));
	}

	float a = col.r;
	col = mix(c2, c1, col);
	
	return vec4(col, a);
}

float draw_square(vec2 st) {
	float size = shape_size;
	vec2 center = vec2(.5);

	st -= center;
	st.x *= adsk_result_frameratio;
	st += center;

	if (st.x > center.x - size * .5 * shape_aspect  && st.x < center.x + size * shape_aspect * .5) {
		if (st.y > center.y - size * .5  && st.y < center.y + size * .5) {
			return 1.0;
		} else {
			return 0.0;
		}
	} else {
		return 0.0;
	}
}

vec4 shape(vec2 st) {
	if (shape_type == 0) {
		return vec4(draw_square(st));
	} else if (shape_type == 1) {
		return vec4(draw_circle(st, vec2(.5), shape_size * .25, shape_aspect));
	}
}


void main(void)
{
	vec2 st = gl_FragCoord.xy / vec2( adsk_result_w, adsk_result_h);
	vec3 front = texture2D(adsk_results_pass1, st).rgb;

	// Default output is solid color
	vec3 col = vec3(color);
	float matte_out = luminance(col);

	vec4 pallette = vec4(0.0);
	float swatch = draw_circle(st, swatch_center, swatch_size * .25, 1.0);

	bool sw = show_swatch;
	bool sp = show_pallette;
	bool gsp = show_gpallette;
	bool csp = show_cbpallette;

	if (result != 0) {
		sw = false;
		sp = false;
		gsp = false;
		csp = false;
	}

	if (process == 0) {
		if (sw) {
			col = mix(front, color, swatch);
		}

		if (sp) {
			vec2 coords = (st - vec2(.5)) / .65 + .5;
			if (isInTex(coords)) {
				pallette = texture2DLod(adsk_results_pass5, coords , pallette_detail);
			

				col = mix(front, pallette.rgb, pallette.a);

				if (sw) {
					col = mix(col, color, swatch);
				}	

				if (st.x < .2) {
					col.rgb -= .5;
					col = clamp(col, 0.0, 1.0);
				}

				float thresh = .93;
				if (col.r > thresh && col.g > thresh && col.b > thresh) {
					col.rgb = white;
				}
			} else {
				if (sw) {
					col = mix(front, color, swatch);
				} else {	
					col = front;
				}
			}
		}
	} else if (process == 1) {
		col = vec3(noise(st));
		matte_out = col.r;
		if ( color_noise ) {
            col = vec3(noise(st * noise(st)+1.), noise(st * noise(st)-1.), noise(st));
		}
	} else if (process == 2) {
		col = checkerboard(st, cb_color1, cb_color2);
		matte_out = checkerboard(st, white, black).r;

		if (csp) {
            vec2 coords = (st - vec2(.5)) / .65 + .5;
            if (isInTex(coords)) {
                pallette = texture2DLod(adsk_results_pass5, coords , cbpallette_detail);


                col = mix(col, pallette.rgb, pallette.a);

                if (st.x < .2) {
                    col.rgb -= .5;
                    col = clamp(col, 0.0, 1.0);
                }

                float thresh = .93;
                if (col.r > thresh && col.g > thresh && col.b > thresh) {
                    col.rgb = white;
                }
            }
        }

	} else if (process == 3) {
		col = colorbars(st);
		float matte_out = luminance(col);
	} else if (process == 4) {
		col = colorwheel(st);
		matte_out = draw_circle(st, cw_center, cw_size * .25, cw_aspect);
	} else if (process == 5) {
		vec4 tmp = gradient(st);
		col.rgb = tmp.rgb;
		matte_out = tmp.a;

		if (gsp) {
            vec2 coords = (st - vec2(.5)) / .65 + .5;
            if (isInTex(coords)) {
                pallette = texture2DLod(adsk_results_pass5, coords , gpallette_detail);


                col = mix(col, pallette.rgb, pallette.a);

                if (st.x < .2) {
                    col.rgb -= .5; 
                    col = clamp(col, 0.0, 1.0);
                }   

                float thresh = .93;
                if (col.r > thresh && col.g > thresh && col.b > thresh) {
                    col.rgb = white;
                }   
            }   
        }   
		float matte_out = luminance(col);
	} else if (process == 6) {
		col = shape(st).rgb;
	}

	if (result == 2) {
		float matte = texture2D(adsk_results_pass3, st).r;
		col = mix(front, col, matte);
	} else if (result == 3) {
		float matte = texture2D(adsk_results_pass3, st).r;
		vec3 back = texture2D(adsk_results_pass2, st).rgb;
		col = mix(back, col, matte);
	}

	float strength = texture2D(adsk_results_pass4, st).r;
	if (ssat) {
		col = rgb2hsv(col);
		col.g = clamp(col.g - strength, 0.0, 1.0);
		col = hsv2rgb(col);
	}

	if (shue) {
		col = rgb2hsv(col);
		col.r += strength;
		col = hsv2rgb(col);
	}

	if (slum) {
		col *= vec3(strength);
	}

	gl_FragColor = vec4(col, matte_out);
}
