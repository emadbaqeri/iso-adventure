class_name PixelCameraRig
extends Node3D

## Orthographic isometric rig; snaps camera origin to the render pixel grid each frame.

@export var camera_path: NodePath = ^"Camera3D"
@export var render_height: int = 360
@export var follow_target_path: NodePath
@export var follow_offset: Vector3 = Vector3.ZERO

var sub_pixel_offset: Vector2 = Vector2.ZERO
var pixel_world_size: float = 1.0

var _camera: Camera3D


func _ready() -> void:
	process_priority = 100
	_camera = get_node_or_null(camera_path) as Camera3D
	if _camera == null:
		push_error("PixelCameraRig: missing Camera3D at %s" % camera_path)


func _physics_process(_delta: float) -> void:
	if _camera == null:
		return

	if follow_target_path != NodePath():
		var target := get_node_or_null(follow_target_path) as Node3D
		if target != null:
			global_position = target.global_position + follow_offset

	pixel_world_size = PixelCameraMath.units_per_pixel(_camera.size, render_height)
	var cam_origin := _camera.global_position
	var snap := PixelCameraMath.snap_camera_origin(
		_camera.global_transform.basis,
		cam_origin,
		_camera.size,
		render_height,
	)
	global_position += snap["snapped_world"] - cam_origin
	sub_pixel_offset = snap["sub_pixel"]
