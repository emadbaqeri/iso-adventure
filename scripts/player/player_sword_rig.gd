class_name PlayerSwordRig
extends Node3D

## Low-poly sword + arc swing; hitbox rides the swing pivot.

const SWING_ARC_DEGREES := 140.0
const SWING_START_DEG := -70.0
const SWING_END_DEG := 70.0
const REST_YAW_DEG := -58.0
const BLADE_REACH := 0.92
const TRAIL_INNER := 0.52
const TRAIL_OUTER := 1.02

@export var blade_material: Material
@export var guard_material: Material
@export var hilt_material: Material

@onready var _swing_pivot: Node3D = $SwingPivot
@onready var _blade: MeshInstance3D = $SwingPivot/Sword/Blade
@onready var _guard: MeshInstance3D = $SwingPivot/Sword/Guard
@onready var _hilt: MeshInstance3D = $SwingPivot/Sword/Hilt
@onready var _trail: MeshInstance3D = $SwingPivot/Trail
@onready var _hitbox: Area3D = $SwingPivot/AttackHitbox

var _trail_material: StandardMaterial3D
var _trail_from_angle: float = 0.0
var _trail_to_angle: float = 0.0
var _swinging: bool = false


func _ready() -> void:
	position = Vector3(0.0, 0.75, 0.0)
	_apply_materials()
	_setup_trail_material()
	_return_to_rest(false)


func get_hitbox() -> HitboxComponent:
	return _hitbox as HitboxComponent


func return_to_rest(animate_trail_fade: bool = true) -> void:
	_swinging = false
	_swing_pivot.rotation.y = deg_to_rad(REST_YAW_DEG)
	_align_hitbox_to_sword()
	if animate_trail_fade:
		_fade_trail_out()
	else:
		_trail.visible = false


func begin_swing() -> void:
	_swinging = true
	_trail_from_angle = deg_to_rad(SWING_START_DEG)
	_trail_to_angle = _trail_from_angle
	_trail.visible = true
	if _trail_material != null:
		_trail_material.albedo_color.a = 0.42
	set_swing_progress(0.0)


func set_swing_progress(progress: float) -> void:
	var t := clampf(progress, 0.0, 1.0)
	var angle := deg_to_rad(lerpf(SWING_START_DEG, SWING_END_DEG, t))
	_swing_pivot.rotation.y = angle
	_trail_to_angle = angle
	_rebuild_trail_mesh()
	_align_hitbox_to_sword()


func swing_arc_degrees() -> float:
	return SWING_ARC_DEGREES


func _apply_materials() -> void:
	if blade_material != null:
		_blade.set_surface_override_material(0, blade_material)
	if guard_material != null:
		_guard.set_surface_override_material(0, guard_material)
	if hilt_material != null:
		_hilt.set_surface_override_material(0, hilt_material)


func _setup_trail_material() -> void:
	_trail_material = StandardMaterial3D.new()
	_trail_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_trail_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_trail_material.albedo_color = Color(0.55, 0.72, 0.95, 0.42)
	_trail_material.emission_enabled = true
	_trail_material.emission = Color(0.35, 0.55, 0.85) * 0.25
	_trail.set_surface_override_material(0, _trail_material)
	_trail.visible = false


func _return_to_rest(_animate: bool) -> void:
	return_to_rest(false)


func _align_hitbox_to_sword() -> void:
	_hitbox.position = Vector3(0.0, 0.0, -BLADE_REACH * 0.55)
	_hitbox.rotation.y = 0.0


func _rebuild_trail_mesh() -> void:
	var from_a := _trail_from_angle
	var to_a := _trail_to_angle
	if absf(to_a - from_a) < 0.02:
		_trail.mesh = null
		return
	var segments := 10
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	for i: int in range(segments + 1):
		var f := float(i) / float(segments)
		var angle := lerpf(from_a, to_a, f)
		var dir := Vector3(sin(angle), 0.0, -cos(angle))
		verts.append(dir * TRAIL_INNER)
		verts.append(dir * TRAIL_OUTER)
		normals.append(Vector3.UP)
		normals.append(Vector3.UP)
		uvs.append(Vector2(f, 0.0))
		uvs.append(Vector2(f, 1.0))
	for i: int in range(segments):
		var base := i * 2
		indices.append(base)
		indices.append(base + 2)
		indices.append(base + 1)
		indices.append(base + 1)
		indices.append(base + 2)
		indices.append(base + 3)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	_trail.mesh = mesh


func _fade_trail_out() -> void:
	if _trail_material == null:
		_trail.visible = false
		return
	var tween := create_tween()
	tween.tween_method(_set_trail_alpha, _trail_material.albedo_color.a, 0.0, 0.12)
	tween.tween_callback(func() -> void:
		_trail.visible = false
		_trail.mesh = null
	)


func _set_trail_alpha(alpha: float) -> void:
	if _trail_material == null:
		return
	var c := _trail_material.albedo_color
	c.a = alpha
	_trail_material.albedo_color = c
