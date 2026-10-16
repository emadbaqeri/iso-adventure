shader_type spatial;
render_mode unshaded, depth_test_disabled, cull_disabled;

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest, repeat_disable;
uniform sampler2D depth_texture : hint_depth_texture, filter_nearest, repeat_disable;
uniform sampler2D normal_roughness_texture : hint_normal_roughness_texture, filter_nearest, repeat_disable;

uniform vec2 viewport_size = vec2(640.0, 360.0);
uniform float depth_edge_scale = 2800.0;
uniform float normal_edge_scale = 3.8;
uniform float normal_top_boost = 1.2;
uniform float depth_threshold = 0.02;
uniform float depth_curvature_threshold = 0.006;
uniform float normal_threshold = 0.22;
uniform float normal_weak_threshold = 0.14;
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

float raw_normal_edge(vec2 uv, vec2 px, vec3 normal_c) {
	vec3 normal_n = texture(normal_roughness_texture, uv + vec2(0.0, -px.y)).rgb * 2.0 - 1.0;
	vec3 normal_s = texture(normal_roughness_texture, uv + vec2(0.0, px.y)).rgb * 2.0 - 1.0;
	vec3 normal_e = texture(normal_roughness_texture, uv + vec2(px.x, 0.0)).rgb * 2.0 - 1.0;
	vec3 normal_w = texture(normal_roughness_texture, uv + vec2(-px.x, 0.0)).rgb * 2.0 - 1.0;

	float edge = max(
		max(1.0 - dot(normal_c, normal_n), 1.0 - dot(normal_c, normal_s)),
		max(1.0 - dot(normal_c, normal_e), 1.0 - dot(normal_c, normal_w))
	);
	return edge * normal_edge_scale;
}

float sample_normal_edge(vec2 uv, vec2 px, vec3 normal_c) {
	float edge = raw_normal_edge(uv, px, normal_c);
	if (normal_c.y > 0.35 && edge > normal_threshold * 0.5) {
		edge *= normal_top_boost;
	}
	return edge;
}

float normal_edge_neighbor_support(vec2 uv, vec2 px, vec3 normal_c) {
	float support = 0.0;
	support += step(normal_weak_threshold, raw_normal_edge(uv + vec2(0.0, -px.y), px, normal_c));
	support += step(normal_weak_threshold, raw_normal_edge(uv + vec2(0.0, px.y), px, normal_c));
	support += step(normal_weak_threshold, raw_normal_edge(uv + vec2(px.x, 0.0), px, normal_c));
	support += step(normal_weak_threshold, raw_normal_edge(uv + vec2(-px.x, 0.0), px, normal_c));
	return support;
}

float depth_edge_at(vec2 uv, vec2 px) {
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
	if (depth_lap * depth_edge_scale <= depth_curvature_threshold) {
		return 0.0;
	}
	return depth_grad * depth_edge_scale;
}

void fragment() {
	vec2 px = 1.0 / viewport_size;
	ivec2 ic = ivec2(floor(SCREEN_UV * viewport_size));
	vec2 uv = texel_uv(ic);
	vec4 scene = texture(screen_texture, uv);
	vec3 color = scene.rgb;

	float depth_edge = depth_edge_at(uv, px);
	vec3 normal_c = texture(normal_roughness_texture, uv).rgb * 2.0 - 1.0;
	if (normal_c.y > 0.9) {
		depth_edge = 0.0;
	}

	float depth_support = 0.0;
	depth_support += step(depth_threshold, depth_edge_at(uv + vec2(0.0, -px.y), px));
	depth_support += step(depth_threshold, depth_edge_at(uv + vec2(0.0, px.y), px));
	depth_support += step(depth_threshold, depth_edge_at(uv + vec2(px.x, 0.0), px));
	depth_support += step(depth_threshold, depth_edge_at(uv + vec2(-px.x, 0.0), px));

	float normal_edge = sample_normal_edge(uv, px, normal_c);
	if (normal_c.y > 0.9 && normal_edge < normal_threshold * 1.75) {
		normal_edge = 0.0;
	}

	bool depth_silhouette = depth_edge > depth_threshold && depth_support >= 1.0;
	bool crease = normal_edge > normal_threshold
		&& normal_edge_neighbor_support(uv, px, normal_c) >= 1.0
		&& !depth_silhouette;

	if (depth_silhouette || crease) {
		color = outline_color.rgb;
	}

	if (use_palette) {
		color = quantize_to_palette(color);
	}

	ALBEDO = color;
}
