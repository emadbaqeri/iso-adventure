shader_type spatial;
render_mode unshaded, depth_test_disabled, cull_disabled;

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest, repeat_disable;
uniform sampler2D depth_texture : hint_depth_texture, filter_nearest, repeat_disable;

uniform vec2 viewport_size = vec2(640.0, 360.0);
uniform float depth_edge_scale = 2800.0;
uniform float color_edge_scale = 12.0;
uniform float depth_threshold = 0.02;
uniform float depth_curvature_threshold = 0.006;
uniform float color_threshold = 0.09;
uniform vec4 outline_color : source_color = vec4(0.09, 0.09, 0.14, 1.0);

uniform bool use_palette = false;
uniform sampler2D palette_tex : filter_nearest, repeat_disable;

vec2 texel_uv(ivec2 coord) {
	return (vec2(coord) + vec2(0.5)) / viewport_size;
}

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
	ivec2 ic = ivec2(floor(SCREEN_UV * viewport_size));
	vec2 uv = texel_uv(ic);
	vec4 scene = texture(screen_texture, uv);
	vec3 color = scene.rgb;

	float depth_c = texture(depth_texture, uv).r;
	float depth_n = texture(depth_texture, uv + vec2(0.0, -px.y)).r;
	float depth_s = texture(depth_texture, uv + vec2(0.0, px.y)).r;
	float depth_e = texture(depth_texture, uv + vec2(px.x, 0.0)).r;
	float depth_w = texture(depth_texture, uv + vec2(-px.x, 0.0)).r;
	float depth_grad = max(
		max(abs(depth_c - depth_n), abs(depth_c - depth_s)),
		max(abs(depth_c - depth_e), abs(depth_c - depth_w))
	);
	float depth_lap = abs(depth_e + depth_w - 2.0 * depth_c) + abs(depth_n + depth_s - 2.0 * depth_c);
	float depth_edge = 0.0;
	if (depth_lap * depth_edge_scale > depth_curvature_threshold) {
		depth_edge = depth_grad * depth_edge_scale;
	}

	vec3 col_n = texture(screen_texture, uv + vec2(0.0, -px.y)).rgb;
	vec3 col_s = texture(screen_texture, uv + vec2(0.0, px.y)).rgb;
	vec3 col_e = texture(screen_texture, uv + vec2(px.x, 0.0)).rgb;
	vec3 col_w = texture(screen_texture, uv + vec2(-px.x, 0.0)).rgb;
	float color_edge = max(
		max(distance(color, col_n), distance(color, col_s)),
		max(distance(color, col_e), distance(color, col_w))
	) * color_edge_scale;

	if (depth_edge > depth_threshold || color_edge > color_threshold) {
		color = outline_color.rgb;
	}

	if (use_palette) {
		color = quantize_to_palette(color);
	}

	ALBEDO = color;
}
