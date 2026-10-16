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

var _camera: Camera3D


func _ready() -> void:
	_camera = get_node_or_null(camera_path) as Camera3D
	if _camera != null:
		_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
		_camera.size = ortho_size
	rotation_degrees = Vector3(-pitch_degrees, yaw_degrees, 0.0)


func _physics_process(delta: float) -> void:
	if follow_target_path == NodePath():
		return
	var target := get_node_or_null(follow_target_path) as Node3D
	if target == null:
		return
	var desired := target.global_position + follow_offset
	var t := minf(1.0, follow_smooth * delta)
	global_position = global_position.lerp(desired, t)
