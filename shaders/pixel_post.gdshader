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
uniform float depth_curvature_threshold = 0.006;
uniform float normal_threshold = 0.18;
uniform vec3 key_light_dir = vec3(0.35, 0.75, 0.35);
uniform float outline_darken = 0.48;
uniform float outline_cool_shift = 0.22;
uniform float crease_highlight_boost = 0.42;
uniform float crease_shadow_darken = 0.38;
uniform vec4 outline_light : source_color = vec4(0.95, 0.88, 0.72, 1.0);

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

vec3 hue_darken_outline(vec3 surface) {
	vec3 cool = vec3(surface.r * 0.72, surface.g * 0.78, surface.b * 1.08);
	vec3 shifted = mix(surface, cool, outline_cool_shift);
	return shifted * outline_darken;
}

vec3 crease_highlight(vec3 surface) {
	vec3 warm = vec3(
		min(surface.r * 1.18 + crease_highlight_boost * 0.25, 1.0),
		min(surface.g * 1.1 + crease_highlight_boost * 0.18, 1.0),
		min(surface.b * 0.95 + crease_highlight_boost * 0.08, 1.0)
	);
	return mix(surface, warm, crease_highlight_boost);
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

vec3 pick_crease_neighbor(vec2 uv, vec2 px, vec3 normal_c) {
	vec3 normal_n = texture(normal_roughness_texture, uv + vec2(0.0, -px.y)).rgb * 2.0 - 1.0;
	vec3 normal_s = texture(normal_roughness_texture, uv + vec2(0.0, px.y)).rgb * 2.0 - 1.0;
	vec3 normal_e = texture(normal_roughness_texture, uv + vec2(px.x, 0.0)).rgb * 2.0 - 1.0;
	vec3 normal_w = texture(normal_roughness_texture, uv + vec2(-px.x, 0.0)).rgb * 2.0 - 1.0;

	vec3 best = normal_c;
	float best_gap = 0.0;
	float gap_n = 1.0 - dot(normal_c, normal_n);
	float gap_s = 1.0 - dot(normal_c, normal_s);
	float gap_e = 1.0 - dot(normal_c, normal_e);
	float gap_w = 1.0 - dot(normal_c, normal_w);
	if (gap_n > best_gap) {
		best_gap = gap_n;
		best = normal_n;
	}
	if (gap_s > best_gap) {
		best_gap = gap_s;
		best = normal_s;
	}
	if (gap_e > best_gap) {
		best_gap = gap_e;
		best = normal_e;
	}
	if (gap_w > best_gap) {
		best = normal_w;
	}
	return best;
}

void fragment() {
	vec2 px = 1.0 / viewport_size;
	vec2 uv = SCREEN_UV;
	vec4 scene = texture(screen_texture, uv);
	vec3 color = scene.rgb;
	vec3 light_dir = normalize(key_light_dir);

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
	if (normal_c.y > 0.9) {
		depth_edge = 0.0;
	}

	float normal_edge = sample_normal_edge(uv, px, normal_c);
	if (normal_c.y > 0.9 && normal_edge < normal_threshold * 1.75) {
		normal_edge = 0.0;
	}

	bool depth_silhouette = depth_edge > depth_threshold;
	bool crease = normal_edge > normal_threshold && !depth_silhouette;

	if (depth_silhouette) {
		color = hue_darken_outline(color);
	} else if (crease) {
		vec3 neighbor = pick_crease_neighbor(uv, px, normal_c);
		float lit_c = dot(normalize(normal_c), light_dir);
		float lit_n = dot(normalize(neighbor), light_dir);
		float convex_lit = lit_n - lit_c;
		if (convex_lit > 0.04) {
			color = crease_highlight(color);
		} else {
			color = hue_darken_outline(color);
			color = mix(color, color * (1.0 - crease_shadow_darken), 0.65);
		}
	}

	if (use_palette) {
		color = quantize_to_palette(color);
	}

	ALBEDO = color;
}
