class_name PuzzleController
extends Node3D

signal puzzle_solved

@export var switch_paths: Array[NodePath] = []
@export var door_path: NodePath
@export var block_paths: Array[NodePath] = []
@export var goal_path: NodePath
@export var solved_label_path: NodePath = NodePath("PuzzleHud/MarginContainer/VBox/SolvedLabel")
@export var blocked_cell_offsets: Array[Vector2i] = []

var _door: Door
var _solved_label: Label
var _switches: Array[PressureSwitch] = []
var _blocks: Array[PushableBlock] = []
var _goal: PuzzleGoal
var _occupied_cells: Dictionary = {}
var _blocked_lookup: Dictionary = {}
var _solved: bool = false


func _ready() -> void:
	_rebuild_blocked_lookup()
	_door = get_node_or_null(door_path) as Door
	if _door != null:
		_door.open_state_changed.connect(_on_door_open_changed)
		call_deferred("_register_door_cell")
	_goal = get_node_or_null(goal_path) as PuzzleGoal
	for path: NodePath in switch_paths:
		var switch := get_node_or_null(path) as PressureSwitch
		if switch == null:
			continue
		_switches.append(switch)
		switch.pressed_changed.connect(_on_switch_pressed_changed)
	for path: NodePath in block_paths:
		var block := get_node_or_null(path) as PushableBlock
		if block != null:
			_blocks.append(block)
	if _goal != null:
		_goal.goal_reached.connect(_on_goal_reached)
	_solved_label = get_node_or_null(solved_label_path) as Label
	if _solved_label != null:
		_solved_label.visible = false
	_update_door()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("puzzle_reset"):
		reset_blocks()


func register_block_cell(block: PushableBlock, cell: Vector2i) -> void:
	_occupied_cells[cell] = block


func unregister_block_cell(block: PushableBlock) -> void:
	for cell: Variant in _occupied_cells.keys():
		if _occupied_cells[cell] == block:
			_occupied_cells.erase(cell)


func can_block_move(from_cell: Vector2i, direction: Vector2i) -> bool:
	return PuzzleGrid.can_move_from(from_cell, direction, _blocked_lookup, _occupied_cells)


func reset_blocks() -> void:
	_solved = false
	if _solved_label != null:
		_solved_label.visible = false
	for block: PushableBlock in _blocks:
		if block != null and is_instance_valid(block):
			block.reset_to_spawn()
	_update_door()


static func should_door_open(switch_states: Array[bool]) -> bool:
	if switch_states.is_empty():
		return false
	for pressed: bool in switch_states:
		if not pressed:
			return false
	return true


func _register_door_cell() -> void:
	if _door == null:
		return
	_blocked_lookup[_door.get_grid_cell()] = true


func _on_door_open_changed(is_open: bool) -> void:
	if _door == null:
		return
	var cell := _door.get_grid_cell()
	if is_open:
		_blocked_lookup.erase(cell)
	else:
		_blocked_lookup[cell] = true


func _on_switch_pressed_changed(_pressed: bool) -> void:
	_update_door()


func _update_door() -> void:
	if _door == null:
		return
	var states: Array[bool] = []
	for switch: PressureSwitch in _switches:
		states.append(switch.is_pressed())
	_door.set_open(should_door_open(states))


func _on_goal_reached() -> void:
	if _solved:
		return
	_solved = true
	if _solved_label != null:
		_solved_label.visible = true
		_solved_label.text = "Puzzle solved!"
	puzzle_solved.emit()


func _rebuild_blocked_lookup() -> void:
	_blocked_lookup.clear()
	var origin := PuzzleGrid.world_to_cell(global_position)
	for offset: Vector2i in blocked_cell_offsets:
		_blocked_lookup[origin + offset] = true
