shader_type spatial;
render_mode cull_back, diffuse_lambert;

uniform vec4 albedo_color : source_color = vec4(0.24, 0.31, 0.44, 1.0);
uniform sampler2D albedo_tex : source_color, filter_nearest, repeat_disable, hint_default_white;

uniform vec3 band_thresholds = vec3(0.15, 0.45, 0.75);
uniform vec4 band_shadow : source_color = vec4(0.11, 0.14, 0.19, 1.0);
uniform vec4 band_mid : source_color = vec4(0.24, 0.31, 0.44, 1.0);
uniform vec4 band_highlight : source_color = vec4(0.56, 0.64, 0.77, 1.0);

void fragment() {
	vec4 tex = texture(albedo_tex, UV);
	ALBEDO = (tex * albedo_color).rgb;
}

void light() {
	float ndotl = clamp(dot(NORMAL, LIGHT), 0.0, 1.0);
	vec3 lit = band_shadow.rgb;
	if (ndotl > band_thresholds.x) {
		lit = band_mid.rgb;
	}
	if (ndotl > band_thresholds.y) {
		lit = band_highlight.rgb;
	}
	if (ndotl > band_thresholds.z) {
		lit = mix(band_highlight.rgb, vec3(1.0), 0.35);
	}
	DIFFUSE_LIGHT = lit * LIGHT_COLOR * ATTENUATION;
}
