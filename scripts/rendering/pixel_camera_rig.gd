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
var _camera_local: Transform3D


func _ready() -> void:
	process_priority = 100
	_camera = get_node_or_null(camera_path) as Camera3D
	if _camera == null:
		push_error("PixelCameraRig: missing Camera3D at %s" % camera_path)
		return
	_camera_local = _camera.transform
	call_deferred("_snap_once")


func _snap_once() -> void:
	_physics_process(0.0)


func _physics_process(_delta: float) -> void:
	if _camera == null:
		return

	pixel_world_size = PixelCameraMath.units_per_pixel(_camera.size, render_height)
	var basis := _camera.global_transform.basis

	var focus := global_position
	if follow_target_path != NodePath():
		var target := get_node_or_null(follow_target_path) as Node3D
		if target != null:
			focus = target.global_position + follow_offset

	var desired_cam_origin := focus + basis * _camera_local.origin
	var snap := PixelCameraMath.snap_camera_origin(
		basis,
		desired_cam_origin,
		_camera.size,
		render_height,
	)
	var snapped_cam_origin: Vector3 = snap["snapped_world"]
	sub_pixel_offset = snap["sub_pixel"]
	global_position = snapped_cam_origin - basis * _camera_local.origin
	_apply_sub_pixel_camera_offset()


func _apply_sub_pixel_camera_offset() -> void:
	if _camera == null:
		return
	# Fractional snap remainder in render-viewport pixels (ortho); keeps the world locked to the texel grid.
	_camera.frustum_offset = Vector2(-sub_pixel_offset.x, -sub_pixel_offset.y)
