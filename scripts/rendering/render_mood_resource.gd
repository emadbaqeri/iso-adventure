class_name RenderMoodResource
extends Resource

@export var mood_name: String = "Unnamed"
@export var key_light_color: Color = Color(1.0, 0.92, 0.78)
@export var key_light_energy: float = 1.35
@export var ambient_color: Color = Color(0.42, 0.52, 0.72)
@export var ambient_energy: float = 0.48
@export var shadow_tint: Color = Color(0.14, 0.18, 0.32)
@export var mid_tint: Color = Color(0.32, 0.38, 0.52)
@export var highlight_tint: Color = Color(0.82, 0.76, 0.62)
@export var top_tint: Color = Color(0.92, 0.84, 0.68)
@export_range(0.0, 0.35) var band_dither_strength: float = 0.12
@export var rim_tint: Color = Color(0.55, 0.78, 0.98)
@export var rim_strength: float = 0.24
@export_range(2, 4) var band_count: int = 3
@export var fog_enabled: bool = true
@export var fog_color: Color = Color(0.55, 0.68, 0.88)
@export var fog_density: float = 0.018
@export var fog_aerial_perspective: float = 0.35
@export var ssao_intensity: float = 0.55
@export var outline_light: Color = Color(0.95, 0.88, 0.72)
@export_range(0.2, 0.8) var outline_darken: float = 0.48
@export_range(0.0, 0.5) var outline_cool_shift: float = 0.22
@export_range(0.1, 0.8) var crease_highlight_boost: float = 0.42
@export_range(0.1, 0.8) var crease_shadow_darken: float = 0.38
