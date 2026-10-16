class_name PushableBlock
extends StaticBody3D

signal grid_cell_changed(from_cell: Vector2i, to_cell: Vector2i)

@export var push_hold_seconds: float = 0.3
@export var move_tween_seconds: float = 0.22
@export var controller_path: NodePath

var _controller: PuzzleController
var _grid_cell: Vector2i
var _spawn_cell: Vector2i
var _spawn_y: float = 0.0
var _push_time: float = 0.0
var _push_direction: Vector2i = Vector2i.ZERO
var _is_moving: bool = false
var _tween: Tween


func _ready() -> void:
	add_to_group("puzzle_block")
	_controller = get_node_or_null(controller_path) as PuzzleController
	_spawn_y = global_position.y
	global_position = PuzzleGrid.snap_world(global_position)
	_grid_cell = PuzzleGrid.world_to_cell(global_position)
	_spawn_cell = _grid_cell
	_register_cell()


func _physics_process(delta: float) -> void:
	if _is_moving:
		return
	var player := _find_player()
	if player == null:
		_reset_push()
		return
	var direction := _push_direction_from_player(player)
	if direction == Vector2i.ZERO:
		_reset_push()
		return
	if direction != _push_direction:
		_push_direction = direction
		_push_time = 0.0
	_push_time += delta
	if _push_time >= push_hold_seconds:
		_try_push(direction)
		_reset_push()


func reset_to_spawn() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_is_moving = false
	_unregister_cell()
	global_position = PuzzleGrid.cell_to_world(_spawn_cell, _spawn_y)
	_grid_cell = _spawn_cell
	_register_cell()
	_reset_push()


func get_grid_cell() -> Vector2i:
	return _grid_cell


func _register_cell() -> void:
	if _controller != null:
		_controller.register_block_cell(self, _grid_cell)


func _unregister_cell() -> void:
	if _controller != null:
		_controller.unregister_block_cell(self)


func _try_push(direction: Vector2i) -> void:
	if _controller == null:
		return
	if not _controller.can_block_move(_grid_cell, direction):
		return
	var target_cell := _grid_cell + direction
	_unregister_cell()
	_is_moving = true
	var from_world := global_position
	var to_world := PuzzleGrid.cell_to_world(target_cell, _spawn_y)
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "global_position", to_world, move_tween_seconds).set_trans(
		Tween.TRANS_QUAD
	).set_ease(Tween.EASE_OUT)
	_tween.finished.connect(
		func() -> void:
			_is_moving = false
			var from_cell := _grid_cell
			_grid_cell = target_cell
			global_position = to_world
			_register_cell()
			grid_cell_changed.emit(from_cell, target_cell)
	,
		CONNECT_ONE_SHOT
	)


func _find_player() -> PlayerController:
	for node: Node in get_tree().get_nodes_in_group("player"):
		return node as PlayerController
	return null


func _push_direction_from_player(player: PlayerController) -> Vector2i:
	var move := player.get_world_move_direction()
	if move.length_squared() < 0.04:
		return Vector2i.ZERO
	var to_block := global_position - player.global_position
	to_block.y = 0.0
	if to_block.length_squared() < 0.04:
		return Vector2i.ZERO
	if move.dot(to_block.normalized()) < 0.25:
		return Vector2i.ZERO
	return PuzzleGrid.cardinal_from_world_delta(move)


func _reset_push() -> void:
	_push_time = 0.0
	_push_direction = Vector2i.ZERO
