extends Node3D

@export var amplitude: float = 2.5
@export var speed: float = 0.7
@export var camera_rig_path: NodePath = ^"../../PixelCameraRig"
@export var render_height: int = 360

var _origin: Vector3
var _time: float = 0.0
var _move_axis: Vector3 = Vector3.RIGHT


func _ready() -> void:
	process_physics_priority = 110
	_origin = global_position
	var rig := get_node_or_null(camera_rig_path) as PixelCameraRig
	if rig != null:
		var camera := rig.get_node_or_null(rig.camera_path) as Camera3D
		if camera != null:
			_move_axis = camera.global_transform.basis.x.normalized()


func _physics_process(delta: float) -> void:
	if is_zero_approx(speed):
		return
	_time += delta
	var rig := get_node_or_null(camera_rig_path) as PixelCameraRig
	var camera: Camera3D = null
	if rig != null:
		camera = rig.get_node_or_null(rig.camera_path) as Camera3D
	if camera == null:
		global_position = _origin + _move_axis * (sin(_time * speed) * amplitude)
		return

	var pixel := PixelCameraMath.units_per_pixel(camera.size, render_height)
	var desired := _origin + _move_axis * (sin(_time * speed) * amplitude)
	var snap := PixelCameraMath.snap_on_camera_plane(camera.global_transform.basis, desired, pixel)
	global_position = snap["snapped_world"]
