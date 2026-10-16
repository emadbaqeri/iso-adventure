class_name PlayerSwordRig
extends Node3D

enum FollowMode { FLOAT, ATTACK, RETURN }

const SWING_ARC_DEGREES := 140.0
const SWING_START_DEG := -70.0
const SWING_END_DEG := 70.0
const REST_SIDE_YAW_DEG := -62.0
## Blade extends along local -Z; +90° X points tip at the sky.
const REST_BLADE_PITCH_DEG := 90.0
const BLADE_REACH := 0.92
const TRAIL_INNER := 0.52
const TRAIL_OUTER := 1.02

@export_group("Attack Phases")
@export var wind_up_duration: float = 0.0
@export var strike_duration: float = 0.08
@export var recovery_duration: float = 0.2

@export_group("Hover Follow")
@export var spring_stiffness: float = 42.0
@export var spring_damping: float = 8.5
@export var shoulder_offset: Vector3 = Vector3(0.46, 0.88, 0.06)
@export var bob_amplitude: float = 0.05
@export var bob_speed: float = 2.4
@export var sway_degrees: float = 4.5

@export_group("Sword Materials")
@export var blade_material: Material
@export var guard_material: Material
@export var hilt_material: Material

@onready var _swing_pivot: Node3D = $SwingPivot
@onready var _sword_root: Node3D = $SwingPivot/Sword
@onready var _blade: MeshInstance3D = $SwingPivot/Sword/Blade
@onready var _guard: MeshInstance3D = $SwingPivot/Sword/Guard
@onready var _hilt: MeshInstance3D = $SwingPivot/Sword/Hilt
@onready var _trail: MeshInstance3D = $SwingPivot/Trail
@onready var _hitbox: Area3D = $SwingPivot/AttackHitbox

var _player: PlayerController
var _linear_velocity: Vector3 = Vector3.ZERO
var _mode: FollowMode = FollowMode.FLOAT
var _time: float = 0.0
var _trail_material: StandardMaterial3D
var _trail_from_angle: float = 0.0
var _trail_to_angle: float = 0.0
var _swing_facing_yaw: float = 0.0
var _attack_time: float = 0.0
var _combo_active: bool = false
var _strike_origin_position: Vector3 = Vector3.ZERO


func _ready() -> void:
	top_level = true
	_player = get_parent() as PlayerController
	_apply_materials()
	_setup_trail_material()
	global_position = _hover_anchor_world()
	global_rotation = _hover_rotation_basis().get_rotation_quaternion().get_euler()
	_apply_rest_pose()
	_trail.visible = false


func _physics_process(delta: float) -> void:
	_time += delta
	if _player == null or not is_instance_valid(_player):
		return
	if _combo_active:
		return
	match _mode:
		FollowMode.FLOAT, FollowMode.RETURN:
			_update_hover_follow(delta)


func get_hitbox() -> HitboxComponent:
	return _hitbox as HitboxComponent


func get_default_physics_step() -> float:
	var hz := float(Engine.physics_ticks_per_second)
	if hz <= 0.0:
		return 1.0 / 60.0
	return 1.0 / hz


func get_attack_total_duration() -> float:
	return wind_up_duration + strike_duration + recovery_duration


func get_attack_phase_name() -> StringName:
	if not _combo_active:
		return &"idle"
	if _attack_time < wind_up_duration:
		return &"wind_up"
	if _attack_time < wind_up_duration + strike_duration:
		return &"strike"
	return &"recovery"


func is_combo_active() -> bool:
	return _combo_active


func can_accept_attack_input() -> bool:
	if not _combo_active:
		return true
	return is_in_recovery()


func is_in_recovery() -> bool:
	return _combo_active and get_attack_phase_name() == &"recovery"


func is_strike_phase() -> bool:
	if not _combo_active:
		return false
	return (
		_attack_time >= wind_up_duration
		and _attack_time < wind_up_duration + strike_duration
	)


func get_swing_pivot_yaw() -> float:
	return _swing_pivot.rotation.y


func is_top_level_floater() -> bool:
	return top_level


func swing_arc_degrees() -> float:
	return SWING_ARC_DEGREES


func get_blade_tip_up_alignment() -> float:
	var tip_dir := (_blade.global_position - _hilt.global_position).normalized()
	return tip_dir.dot(Vector3.UP)


func begin_attack_combo(facing_yaw: float) -> void:
	_combo_active = true
	_mode = FollowMode.ATTACK
	_swing_facing_yaw = facing_yaw
	_linear_velocity = Vector3.ZERO
	_strike_origin_position = global_position
	_trail.visible = false
	_trail.mesh = null
	_trail_from_angle = _swing_pivot.rotation.y
	_trail_to_angle = _trail_from_angle
	global_rotation = Vector3(0.0, _swing_facing_yaw, 0.0)
	var step := get_default_physics_step()
	_attack_time = step
	_apply_attack_sample(_attack_time)


func advance_attack_combo(delta: float) -> bool:
	if not _combo_active:
		return false
	_attack_time += delta
	var total := get_attack_total_duration()
	if _attack_time >= total:
		_finish_attack_combo()
		return false
	_apply_attack_sample(_attack_time)
	return true


func cancel_attack_combo() -> void:
	if not _combo_active:
		return
	_finish_attack_combo()


func _finish_attack_combo() -> void:
	_combo_active = false
	_mode = FollowMode.RETURN
	_fade_trail_out()
	_apply_rest_pose()


func _apply_attack_sample(elapsed: float) -> void:
	global_rotation = Vector3(0.0, _swing_facing_yaw, 0.0)
	if elapsed < wind_up_duration:
		_apply_wind_up()
	elif elapsed < wind_up_duration + strike_duration:
		var strike_t := (elapsed - wind_up_duration) / strike_duration
		_apply_strike(strike_t)
	else:
		var recovery_elapsed := elapsed - wind_up_duration - strike_duration
		_apply_recovery(recovery_elapsed / recovery_duration)


func _apply_wind_up() -> void:
	_apply_strike(0.0)


func _apply_strike(t: float) -> void:
	var eased := _ease_in_cubic(clampf(t, 0.0, 1.0))
	var center := _swing_center_world()
	global_position = _strike_origin_position.lerp(center, minf(eased * 1.75, 1.0))
	var angle := deg_to_rad(lerpf(SWING_START_DEG, SWING_END_DEG, eased))
	_swing_pivot.rotation.y = angle
	_sword_root.rotation.x = deg_to_rad(lerpf(REST_BLADE_PITCH_DEG, 0.0, minf(eased * 1.35, 1.0)))
	_trail.visible = true
	if _trail_material != null:
		_trail_material.albedo_color.a = 0.42
	_trail_to_angle = angle
	_rebuild_trail_mesh()
	_align_hitbox_to_sword()


func _apply_recovery(t: float) -> void:
	var eased := _ease_in_out_quad(clampf(t, 0.0, 1.0))
	var anchor := _hover_anchor_world()
	global_position = global_position.lerp(anchor, eased * 0.35)
	_mode = FollowMode.RETURN
	var yaw := lerpf(SWING_END_DEG, REST_SIDE_YAW_DEG, eased)
	_swing_pivot.rotation = Vector3(0.0, deg_to_rad(yaw), 0.0)
	_sword_root.rotation.x = deg_to_rad(lerpf(0.0, REST_BLADE_PITCH_DEG, eased))


func _update_hover_follow(delta: float) -> void:
	var anchor := _hover_anchor_world()
	_spring_position_toward(anchor, delta)
	var target_quat := _hover_rotation_basis().get_rotation_quaternion()
	var blend := 1.0 - exp(-10.0 * delta)
	global_rotation = Quaternion.from_euler(global_rotation).slerp(target_quat, blend).get_euler()
	_apply_rest_pose()
	if _mode == FollowMode.RETURN:
		var yaw_delta := absf(wrapf(
			_swing_pivot.rotation.y - deg_to_rad(REST_SIDE_YAW_DEG), -PI, PI
		))
		if global_position.distance_to(anchor) < 0.04 and yaw_delta < 0.05:
			_mode = FollowMode.FLOAT


func _spring_position_toward(target: Vector3, delta: float) -> void:
	var displacement := target - global_position
	var acceleration := displacement * spring_stiffness - _linear_velocity * spring_damping
	_linear_velocity += acceleration * delta
	global_position += _linear_velocity * delta


func _hover_anchor_world() -> Vector3:
	var bob := sin(_time * bob_speed) * bob_amplitude
	if _player == null:
		return global_position
	var basis := _player.global_transform.basis
	var offset := basis.x * shoulder_offset.x
	offset += Vector3.UP * shoulder_offset.y
	offset += basis.z * shoulder_offset.z
	return _player.global_position + offset + Vector3(0.0, bob, 0.0)


func _hover_rotation_basis() -> Basis:
	if _player == null:
		return Basis.IDENTITY
	var yaw := _player.rotation.y
	var sway_y := deg_to_rad(sin(_time * bob_speed * 0.85) * sway_degrees)
	var sway_z := deg_to_rad(cos(_time * bob_speed * 0.6) * sway_degrees * 0.5)
	return Basis.from_euler(Vector3(0.0, yaw + sway_y, sway_z))


func _swing_center_world() -> Vector3:
	if _player == null:
		return global_position
	return _player.global_position + Vector3(0.0, 0.78, 0.0)


func _apply_rest_pose() -> void:
	if _combo_active:
		return
	var side_sway := deg_to_rad(sin(_time * bob_speed * 1.1) * sway_degrees * 0.6)
	_swing_pivot.rotation = Vector3(0.0, deg_to_rad(REST_SIDE_YAW_DEG) + side_sway, 0.0)
	_sword_root.rotation.x = deg_to_rad(REST_BLADE_PITCH_DEG)


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
	_trail.material_override = _trail_material


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
		_trail_from_angle = 0.0
		_trail_to_angle = 0.0
	)


func _set_trail_alpha(alpha: float) -> void:
	if _trail_material == null:
		return
	var c := _trail_material.albedo_color
	c.a = alpha
	_trail_material.albedo_color = c


static func _ease_in_cubic(t: float) -> float:
	return t * t * t


static func _ease_in_out_quad(t: float) -> float:
	if t < 0.5:
		return 2.0 * t * t
	return 1.0 - pow(-2.0 * t + 2.0, 2.0) / 2.0
