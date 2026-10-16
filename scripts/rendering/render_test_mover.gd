extends Node3D

@export var amplitude: float = 2.5
@export var speed: float = 0.7
@export var camera_rig_path: NodePath = ^"../../PixelCameraRig"

var _origin: Vector3
var _time: float = 0.0
var _move_axis: Vector3 = Vector3.RIGHT


func _ready() -> void:
	_origin = global_position
	var rig := get_node_or_null(camera_rig_path) as PixelCameraRig
	if rig != null:
		var camera := rig.get_node_or_null(rig.camera_path) as Camera3D
		if camera != null:
			_move_axis = camera.global_transform.basis.x.normalized()


func _physics_process(delta: float) -> void:
	_time += delta
	var offset := _move_axis * (sin(_time * speed) * amplitude)
	global_position = _origin + offset
