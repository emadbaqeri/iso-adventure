shader_type canvas_item;

uniform vec2 viewport_size = vec2(640.0, 360.0);
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
	vec3 color = texture(TEXTURE, UV).rgb;
	if (use_palette) {
		color = quantize_to_palette(color);
	}
	COLOR = vec4(color, 1.0);
}
