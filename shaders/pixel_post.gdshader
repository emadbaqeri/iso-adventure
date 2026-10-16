shader_type spatial;
render_mode unshaded, depth_test_disabled, cull_disabled;

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest, repeat_disable;
uniform sampler2D depth_texture : hint_depth_texture, filter_nearest, repeat_disable;
uniform sampler2D normal_roughness_texture : hint_normal_roughness_texture, filter_nearest, repeat_disable;

uniform vec2 viewport_size = vec2(640.0, 360.0);
uniform float depth_edge_scale = 120.0;
uniform float normal_edge_scale = 2.5;
uniform float edge_threshold = 0.35;
uniform vec4 outline_color : source_color = vec4(0.07, 0.09, 0.12, 1.0);

uniform bool use_palette = false;
uniform sampler2D palette_tex : filter_nearest, repeat_disable;

vec3 quantize_to_palette(vec3 color) {
	int palette_width = textureSize(palette_tex, 0).x;
	vec3 best = color;
	float best_dist = 1e9;
	for (int i = 0; i < palette_width; i++) {
		vec3 sample_col = texelFetch(palette_tex, ivec2(i, 0), 0).rgb;
		float d = distance(color, sample_col);
		if (d < best_dist) {
			best_dist = d;
			best = sample_col;
		}
	}
	return best;
}

void fragment() {
	vec2 px = 1.0 / viewport_size;
	vec2 uv = SCREEN_UV;
	vec4 scene = texture(screen_texture, uv);

	float depth_c = texture(depth_texture, uv).r;
	float depth_n = texture(depth_texture, uv + vec2(0.0, -px.y)).r;
	float depth_s = texture(depth_texture, uv + vec2(0.0, px.y)).r;
	float depth_e = texture(depth_texture, uv + vec2(px.x, 0.0)).r;
	float depth_w = texture(depth_texture, uv + vec2(-px.x, 0.0)).r;
	float depth_edge = max(
		max(abs(depth_c - depth_n), abs(depth_c - depth_s)),
		max(abs(depth_c - depth_e), abs(depth_c - depth_w))
	) * depth_edge_scale;

	vec3 normal_c = texture(normal_roughness_texture, uv).rgb * 2.0 - 1.0;
	vec3 normal_n = texture(normal_roughness_texture, uv + vec2(0.0, -px.y)).rgb * 2.0 - 1.0;
	vec3 normal_s = texture(normal_roughness_texture, uv + vec2(0.0, px.y)).rgb * 2.0 - 1.0;
	vec3 normal_e = texture(normal_roughness_texture, uv + vec2(px.x, 0.0)).rgb * 2.0 - 1.0;
	vec3 normal_w = texture(normal_roughness_texture, uv + vec2(-px.x, 0.0)).rgb * 2.0 - 1.0;
	float normal_edge = max(
		max(distance(normal_c, normal_n), distance(normal_c, normal_s)),
		max(distance(normal_c, normal_e), distance(normal_c, normal_w))
	) * normal_edge_scale;

	float edge = max(depth_edge, normal_edge);
	vec3 color = scene.rgb;
	if (edge > edge_threshold) {
		color = outline_color.rgb;
	}

	if (use_palette) {
		color = quantize_to_palette(color);
	}

	ALBEDO = color;
}
