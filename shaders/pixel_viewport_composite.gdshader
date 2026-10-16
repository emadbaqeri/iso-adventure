shader_type canvas_item;

uniform vec2 viewport_size = vec2(640.0, 360.0);
uniform float color_edge_scale = 14.0;
uniform float color_threshold = 0.075;
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

void fragment() {
	vec2 px = 1.0 / viewport_size;
	vec2 uv = UV;
	vec3 color = texture(TEXTURE, uv).rgb;

	vec3 col_n = texture(TEXTURE, uv + vec2(0.0, -px.y)).rgb;
	vec3 col_s = texture(TEXTURE, uv + vec2(0.0, px.y)).rgb;
	vec3 col_e = texture(TEXTURE, uv + vec2(px.x, 0.0)).rgb;
	vec3 col_w = texture(TEXTURE, uv + vec2(-px.x, 0.0)).rgb;
	float edge = max(
		max(distance(color, col_n), distance(color, col_s)),
		max(distance(color, col_e), distance(color, col_w))
	) * color_edge_scale;

	if (edge > color_threshold) {
		float lum = dot(color, vec3(0.299, 0.587, 0.114));
		color = mix(outline_dark.rgb, outline_light.rgb, smoothstep(0.35, 0.65, lum));
	}

	if (use_palette) {
		color = quantize_to_palette(color);
	}

	COLOR = vec4(color, 1.0);
}
