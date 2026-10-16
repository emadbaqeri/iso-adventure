class_name IsoCameraRig
extends Node3D

## Orthographic isometric follow camera (~35° pitch, 45° yaw).

@export var camera_path: NodePath = ^"Camera3D"
@export var follow_target_path: NodePath
@export var follow_offset: Vector3 = Vector3(7.0, 9.0, 7.0)
@export var follow_smooth: float = 6.0
@export var pitch_degrees: float = 35.0
@export var yaw_degrees: float = 45.0
@export var ortho_size: float = 14.0

@export_group("Combat Feedback")
@export var shake_enabled: bool = true
@export var shake_strength: float = 0.14
@export var shake_duration: float = 0.12

var _camera: Camera3D
var _base_camera_position: Vector3 = Vector3.ZERO
var _shake_time_left: float = 0.0
var _shake_strength_current: float = 0.0


func _ready() -> void:
	_camera = get_node_or_null(camera_path) as Camera3D
	if _camera != null:
		_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
		_camera.size = ortho_size
		_base_camera_position = _camera.position
	rotation_degrees = Vector3(-pitch_degrees, yaw_degrees, 0.0)
	var feedback := get_node_or_null("/root/CombatFeedback")
	if feedback != null and feedback.has_method("register_camera_rig"):
		feedback.register_camera_rig(self)


func apply_shake(strength: float = -1.0, duration: float = -1.0) -> void:
	if not shake_enabled or _camera == null:
		return
	var use_strength := shake_strength if strength < 0.0 else strength
	var use_duration := shake_duration if duration < 0.0 else duration
	_shake_strength_current = maxf(_shake_strength_current, use_strength)
	_shake_time_left = maxf(_shake_time_left, use_duration)


func _physics_process(delta: float) -> void:
	if follow_target_path == NodePath():
		return
	var target := get_node_or_null(follow_target_path) as Node3D
	if target == null:
		return
	var desired := target.global_position + follow_offset
	var t := minf(1.0, follow_smooth * delta)
	global_position = global_position.lerp(desired, t)
	_update_shake(delta)


func _update_shake(delta: float) -> void:
	if _camera == null:
		return
	if _shake_time_left <= 0.0:
		_camera.position = _base_camera_position
		_shake_strength_current = 0.0
		return
	_shake_time_left -= delta
	var falloff := clampf(_shake_time_left / shake_duration, 0.0, 1.0)
	var offset := Vector3(
		randf_range(-1.0, 1.0),
		randf_range(-1.0, 1.0),
		randf_range(-1.0, 1.0)
	) * _shake_strength_current * falloff
	_camera.position = _base_camera_position + offset
