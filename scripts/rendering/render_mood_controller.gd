class_name RenderMoodController
extends Node

@export var world_environment_path: NodePath
@export var key_light_path: NodePath
@export var mood_presets: Array[RenderMoodResource] = []

var _mood_index: int = 0


func _ready() -> void:
	if mood_presets.is_empty():
		push_warning("RenderMoodController: no mood presets configured")
		return
	apply_mood(mood_presets[0])


func cycle_mood() -> void:
	if mood_presets.is_empty():
		return
	_mood_index = (_mood_index + 1) % mood_presets.size()
	apply_mood(mood_presets[_mood_index])


func apply_mood(mood: RenderMoodResource) -> void:
	if mood == null:
		return

	var env_node := get_node_or_null(world_environment_path) as WorldEnvironment
	if env_node != null and env_node.environment != null:
		var env := env_node.environment
		env.ambient_light_color = mood.ambient_color
		env.ambient_light_energy = mood.ambient_energy
		env.fog_enabled = mood.fog_enabled
		env.fog_light_color = mood.fog_color
		env.fog_density = mood.fog_density
		env.fog_aerial_perspective = mood.fog_aerial_perspective
		env.ssao_enabled = mood.ssao_intensity > 0.01
		if env.ssao_enabled:
			env.ssao_intensity = mood.ssao_intensity
			env.ssao_radius = 0.45
			env.ssao_power = 1.4

	if env_node != null and env_node.environment != null:
		var sky := env_node.environment.sky
		if sky != null and sky.sky_material is ProceduralSkyMaterial:
			var sky_mat := sky.sky_material as ProceduralSkyMaterial
			sky_mat.sky_top_color = mood.sky_top_color
			sky_mat.sky_horizon_color = mood.sky_horizon_color

	var key := get_node_or_null(key_light_path) as DirectionalLight3D
	if key != null:
		key.light_color = mood.key_light_color
		key.light_energy = mood.key_light_energy

	print("Mood: %s" % mood.mood_name)
