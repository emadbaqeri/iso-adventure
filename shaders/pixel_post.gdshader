shader_type spatial;
render_mode unshaded, depth_test_disabled, cull_disabled;

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest, repeat_disable;
uniform sampler2D depth_texture : hint_depth_texture, filter_nearest, repeat_disable;
uniform sampler2D normal_roughness_texture : hint_normal_roughness_texture, filter_nearest, repeat_disable;

uniform vec2 viewport_size = vec2(640.0, 360.0);
uniform float depth_edge_scale = 2800.0;
uniform float normal_edge_scale = 3.8;
uniform float normal_top_boost = 1.35;
uniform float depth_threshold = 0.02;
uniform float depth_curvature_threshold = 0.004;
uniform float normal_threshold = 0.18;
uniform vec4 outline_dark : source_color = vec4(0.12, 0.06, 0.22, 1.0);
uniform vec4 outline_light : source_color = vec4(0.78, 0.88, 1.0, 1.0);

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

float sample_normal_edge(vec2 uv, vec2 px, vec3 normal_c) {
	vec3 normal_n = texture(normal_roughness_texture, uv + vec2(0.0, -px.y)).rgb * 2.0 - 1.0;
	vec3 normal_s = texture(normal_roughness_texture, uv + vec2(0.0, px.y)).rgb * 2.0 - 1.0;
	vec3 normal_e = texture(normal_roughness_texture, uv + vec2(px.x, 0.0)).rgb * 2.0 - 1.0;
	vec3 normal_w = texture(normal_roughness_texture, uv + vec2(-px.x, 0.0)).rgb * 2.0 - 1.0;
	vec3 normal_ne = texture(normal_roughness_texture, uv + px).rgb * 2.0 - 1.0;
	vec3 normal_nw = texture(normal_roughness_texture, uv + vec2(-px.x, -px.y)).rgb * 2.0 - 1.0;

	float edge = max(
		max(1.0 - dot(normal_c, normal_n), 1.0 - dot(normal_c, normal_s)),
		max(1.0 - dot(normal_c, normal_e), 1.0 - dot(normal_c, normal_w))
	);
	edge = max(edge, max(1.0 - dot(normal_c, normal_ne), 1.0 - dot(normal_c, normal_nw)));
	if (normal_c.y > 0.35 && edge > normal_threshold * 0.5) {
		edge *= normal_top_boost;
	}
	return edge * normal_edge_scale;
}

void fragment() {
	vec2 px = 1.0 / viewport_size;
	vec2 uv = SCREEN_UV;
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

	vec3 normal_c = texture(normal_roughness_texture, uv).rgb * 2.0 - 1.0;
	// Flat upward surfaces have linear depth (zero curvature); skip depth false positives on floors.
	if (normal_c.y > 0.9) {
		depth_edge = 0.0;
	}

	float normal_edge = sample_normal_edge(uv, px, normal_c);
	if (normal_c.y > 0.9 && normal_edge < normal_threshold * 1.75) {
		normal_edge = 0.0;
	}

	bool is_edge = depth_edge > depth_threshold || normal_edge > normal_threshold;
	if (is_edge) {
		float lum = dot(color, vec3(0.299, 0.587, 0.114));
		vec3 outline = mix(outline_dark.rgb, outline_light.rgb, smoothstep(0.35, 0.65, lum));
		color = outline;
	}

	if (use_palette) {
		color = quantize_to_palette(color);
	}

	ALBEDO = color;
}
