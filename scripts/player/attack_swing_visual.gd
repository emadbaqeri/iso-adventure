class_name AttackSwingVisual
extends MeshInstance3D

const SWING_COLOR := Color(0.92, 0.97, 1.0, 0.55)


func _ready() -> void:
	visible = false
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = SWING_COLOR
	mat.emission_enabled = true
	mat.emission = Color(0.75, 0.9, 1.0) * 0.4
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	set_surface_override_material(0, mat)


func set_active(active: bool) -> void:
	visible = active
	if not active:
		scale = Vector3.ONE
		return
	scale = Vector3(0.55, 0.25, 0.85)
	rotation_degrees = Vector3(-12.0, 0.0, 0.0)
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector3(1.05, 0.4, 1.15), 0.05)
	tween.tween_property(self, "scale", Vector3(0.75, 0.2, 0.95), 0.06)
