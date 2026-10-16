shader_type spatial;
render_mode cull_back, diffuse_lambert, specular_disabled;

uniform vec4 albedo_color : source_color = vec4(0.24, 0.31, 0.44, 1.0);
uniform sampler2D albedo_tex : source_color, filter_nearest, repeat_disable, hint_default_white;

uniform int band_count = 3;
uniform vec3 band_thresholds = vec3(0.22, 0.58, 0.82);
uniform vec4 band_shadow : source_color = vec4(0.11, 0.14, 0.22, 1.0);
uniform vec4 band_mid : source_color = vec4(0.28, 0.34, 0.48, 1.0);
uniform vec4 band_highlight : source_color = vec4(0.72, 0.68, 0.58, 1.0);
uniform vec4 band_top : source_color = vec4(0.85, 0.78, 0.62, 1.0);
uniform vec4 rim_tint : source_color = vec4(0.55, 0.75, 0.95, 1.0);
uniform float rim_strength = 0.22;
uniform vec3 key_light_dir = vec3(0.35, 0.75, 0.35);
uniform bool band_dither = false;
uniform float band_dither_strength = 0.12;

float _hash21(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec4 tex = texture(albedo_tex, UV);
	ALBEDO = (tex * albedo_color).rgb;
}

void light() {
	vec3 n = normalize(NORMAL);
	vec3 l = normalize(LIGHT);
	float key_align = dot(l, normalize(key_light_dir));
	if (key_align < 0.75) {
		float rim = pow(1.0 - clamp(dot(n, VIEW), 0.0, 1.0), 2.0) * rim_strength * 1.35;
		DIFFUSE_LIGHT = rim_tint.rgb * rim * LIGHT_COLOR;
	} else {
		float shadow_mask = step(0.38, ATTENUATION);

		vec3 lit = band_shadow.rgb;
		if (shadow_mask < 0.5) {
			lit = band_shadow.rgb;
		} else if (n.y > 0.55) {
			lit = band_top.rgb;
		} else {
			float ndotl = clamp(dot(n, l), 0.0, 1.0);
			if (band_dither && band_count >= 2) {
				vec2 cell = floor(FRAGCOORD.xy);
				float dither = (_hash21(cell) - 0.5) * band_dither_strength;
				ndotl += dither;
			}
			if (band_count >= 3 && ndotl > band_thresholds.y) {
				lit = band_highlight.rgb;
			} else if (band_count >= 2 && ndotl > band_thresholds.x) {
				lit = band_mid.rgb;
			} else {
				lit = band_shadow.rgb;
			}
		}

		DIFFUSE_LIGHT = lit * LIGHT_COLOR;
	}
}
