shader_type spatial;
render_mode cull_back, diffuse_lambert;

uniform vec4 albedo_color : source_color = vec4(0.24, 0.31, 0.44, 1.0);
uniform sampler2D albedo_tex : source_color, filter_nearest, repeat_disable, hint_default_white;

uniform int band_count = 3;
uniform vec3 band_thresholds = vec3(0.12, 0.42, 0.72);
uniform vec4 band_shadow : source_color = vec4(0.11, 0.14, 0.22, 1.0);
uniform vec4 band_mid : source_color = vec4(0.28, 0.34, 0.48, 1.0);
uniform vec4 band_highlight : source_color = vec4(0.72, 0.68, 0.58, 1.0);
uniform vec4 rim_tint : source_color = vec4(0.55, 0.75, 0.95, 1.0);
uniform float rim_strength = 0.22;

void fragment() {
	vec4 tex = texture(albedo_tex, UV);
	ALBEDO = (tex * albedo_color).rgb;
}

void light() {
	float ndotl = clamp(dot(NORMAL, LIGHT), 0.0, 1.0);
	vec3 lit = band_shadow.rgb;
	if (band_count >= 2 && ndotl > band_thresholds.x) {
		lit = band_mid.rgb;
	}
	if (band_count >= 3 && ndotl > band_thresholds.y) {
		lit = band_highlight.rgb;
	}
	if (band_count >= 4 && ndotl > band_thresholds.z) {
		lit = mix(band_highlight.rgb, vec3(1.0), 0.25);
	}

	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.5) * rim_strength;
	vec3 rim_light = rim_tint.rgb * rim * LIGHT_COLOR;

	DIFFUSE_LIGHT = lit * LIGHT_COLOR * ATTENUATION + rim_light;
}
