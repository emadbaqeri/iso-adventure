class_name PlayerFallSafety
extends Node

@export var player_path: NodePath
@export var fall_y_threshold: float = -10.0

var _player: PlayerController
var _last_safe_position: Vector3 = Vector3.ZERO
var _has_safe_position: bool = false


func _ready() -> void:
	call_deferred("_bind_player")


func _bind_player() -> void:
	_player = get_node_or_null(player_path) as PlayerController
	if _player != null:
		_last_safe_position = _player.global_position
		_has_safe_position = true


func _physics_process(_delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	var space := _player.get_world_3d().direct_space_state
	if FloorProbe.has_floor_at(space, _player.global_position):
		_last_safe_position = _player.global_position
		_has_safe_position = true
	if _player.global_position.y < fall_y_threshold:
		_recover_player()


func _recover_player() -> void:
	if _has_safe_position:
		_player.global_position = _last_safe_position
		_player.velocity = Vector3.ZERO
		return
	get_tree().reload_current_scene()
