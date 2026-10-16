class_name PuzzleRoomAccess
extends StaticBody3D

@export var room_progress_path: NodePath
@export var slide_distance: float = 2.8
@export var move_tween_seconds: float = 0.45

var _progress: RoomProgressHud
var _closed_x: float = 0.0
var _opened: bool = false
var _tween: Tween


func _ready() -> void:
	_closed_x = position.x
	_progress = get_node_or_null(room_progress_path) as RoomProgressHud
	if _progress != null:
		_progress.room_cleared.connect(_on_room_cleared)
	call_deferred("_try_open_if_already_cleared")


func _try_open_if_already_cleared() -> void:
	if _progress != null and _progress.is_room_cleared():
		_open_gate()


func _on_room_cleared() -> void:
	_open_gate()


func force_open() -> void:
	_open_gate(true)


func _open_gate(instant: bool = false) -> void:
	if _opened and not instant:
		return
	_opened = true
	if _tween != null and _tween.is_valid():
		_tween.kill()
	var target_x := _closed_x + slide_distance
	_set_collision_enabled(false)
	if instant:
		position.x = target_x
		return
	_tween = create_tween()
	_tween.tween_property(self, "position:x", target_x, move_tween_seconds).set_trans(
		Tween.TRANS_QUAD
	).set_ease(Tween.EASE_IN_OUT)


func _set_collision_enabled(enabled: bool) -> void:
	var collision := get_node_or_null("CollisionShape3D") as CollisionShape3D
	if collision != null:
		collision.disabled = not enabled
