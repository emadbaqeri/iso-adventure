class_name RenderMoodController
extends Node

const MIN_VIEWPORT_DIM := 16

@export var world_environment_path: NodePath
@export var key_light_path: NodePath
@export var rim_light_path: NodePath
@export var cel_material_paths: Array[NodePath] = []
@export var composite_material_path: NodePath
@export var post_outline_quad_path: NodePath
@export var mood_presets: Array[RenderMoodResource] = []
@export var mood_toggle_action: StringName = &"cycle_mood"

var _mood_index: int = 0


func _ready() -> void:
	if mood_presets.is_empty():
		push_warning("RenderMoodController: no mood presets configured")
		return
	call_deferred("_apply_initial_mood")


func _apply_initial_mood() -> void:
	for _i: int in range(4):
		if _viewport_large_enough_for_effects():
			break
		await get_tree().process_frame
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
		var ssao_ok := _viewport_large_enough_for_effects()
		env.ssao_enabled = ssao_ok and mood.ssao_intensity > 0.01
		if env.ssao_enabled:
			env.ssao_intensity = mood.ssao_intensity
			env.ssao_radius = 0.35
			env.ssao_power = 1.4
		env.glow_enabled = false
		env.ssil_enabled = false

	var key := get_node_or_null(key_light_path) as DirectionalLight3D
	if key != null:
		key.light_color = mood.key_light_color
		key.light_energy = mood.key_light_energy

	var rim := get_node_or_null(rim_light_path) as DirectionalLight3D
	if rim != null:
		rim.light_color = mood.rim_tint
		rim.light_energy = mood.rim_strength * 2.4

	for path: NodePath in cel_material_paths:
		var mat := _resolve_material(path)
		if mat == null:
			continue
		mat.set_shader_parameter("band_count", mood.band_count)
		mat.set_shader_parameter("band_shadow", mood.shadow_tint)
		mat.set_shader_parameter("band_mid", mood.mid_tint)
		mat.set_shader_parameter("band_highlight", mood.highlight_tint)
		mat.set_shader_parameter("rim_tint", mood.rim_tint)
		mat.set_shader_parameter("rim_strength", mood.rim_strength)

	var outline_mat := _resolve_post_outline_material()
	if outline_mat != null:
		outline_mat.set_shader_parameter("outline_dark", mood.outline_dark)
		outline_mat.set_shader_parameter("outline_light", mood.outline_light)

	print("Mood: %s" % mood.mood_name)


func _viewport_large_enough_for_effects() -> bool:
	var vp := get_viewport()
	if vp == null:
		return false
	var size := vp.get_visible_rect().size
	return int(size.x) >= MIN_VIEWPORT_DIM and int(size.y) >= MIN_VIEWPORT_DIM


func _resolve_material(path: NodePath) -> ShaderMaterial:
	var node := get_node_or_null(path)
	if node is MeshInstance3D:
		var mesh := node as MeshInstance3D
		var from_override := _material_as_shader(mesh.material_override)
		if from_override != null:
			return from_override
		return _material_as_shader(mesh.get_surface_override_material(0))
	return null


func _resolve_post_outline_material() -> ShaderMaterial:
	if post_outline_quad_path != NodePath():
		var quad := get_node_or_null(post_outline_quad_path)
		if quad is MeshInstance3D:
			return _material_as_shader((quad as MeshInstance3D).material_override)
	if composite_material_path != NodePath():
		var node := get_node_or_null(composite_material_path)
		if node is SubViewportContainer:
			return _material_as_shader((node as SubViewportContainer).material)
	return null


func _material_as_shader(mat: Material) -> ShaderMaterial:
	if mat == null:
		return null
	if mat is ShaderMaterial:
		return mat as ShaderMaterial
	return null
