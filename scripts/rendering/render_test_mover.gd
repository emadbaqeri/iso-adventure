extends Node3D

@export var amplitude: float = 2.5
@export var speed: float = 0.7

var _origin: Vector3
var _time: float = 0.0


func _ready() -> void:
	_origin = global_position


func _process(delta: float) -> void:
	_time += delta
	global_position = _origin + Vector3(sin(_time * speed) * amplitude, 0.0, 0.0)
