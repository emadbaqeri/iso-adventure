class_name Door
extends StaticBody3D

signal open_state_changed(is_open: bool)

@export var slide_distance: float = 2.6
@export var move_tween_seconds: float = 0.35

var _closed_y: float = 0.0
var _is_open: bool = false
var _tween: Tween


func _ready() -> void:
	_closed_y = position.y


func get_grid_cell() -> Vector2i:
	return PuzzleGrid.world_to_cell(global_position)


func set_open(should_open: bool, instant: bool = false) -> void:
	if should_open != _is_open:
		_is_open = should_open
		open_state_changed.emit(_is_open)
	var target_y := _closed_y + slide_distance if should_open else _closed_y
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_set_collision_enabled(not should_open)
	if instant:
		position.y = target_y
		return
	_tween = create_tween()
	_tween.tween_property(self, "position:y", target_y, move_tween_seconds).set_trans(
		Tween.TRANS_QUAD
	).set_ease(Tween.EASE_IN_OUT)


func is_open() -> bool:
	return _is_open


func _set_collision_enabled(enabled: bool) -> void:
	var collision := get_node_or_null("CollisionShape3D") as CollisionShape3D
	if collision != null:
		collision.disabled = not enabled
