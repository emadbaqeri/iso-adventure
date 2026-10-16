class_name RenderMoodResource
extends Resource

@export var mood_name: String = "Unnamed"
@export var key_light_color: Color = Color(1.0, 0.94, 0.82)
@export var key_light_energy: float = 1.2
@export var ambient_color: Color = Color(0.45, 0.52, 0.68)
@export var ambient_energy: float = 0.35
@export var sky_top_color: Color = Color(0.38, 0.48, 0.68)
@export var sky_horizon_color: Color = Color(0.62, 0.7, 0.82)
@export var fog_enabled: bool = true
@export var fog_color: Color = Color(0.55, 0.65, 0.78)
@export var fog_density: float = 0.01
@export var fog_aerial_perspective: float = 0.35
@export var ssao_intensity: float = 0.45
