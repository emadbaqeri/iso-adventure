class_name PlayerStateMachine
extends Node

signal state_changed(previous: StringName, current: StringName)

@export var initial_state: StringName = &"Idle"

var owner_body: CharacterBody3D

var _states: Dictionary = {}
var _current: PlayerState
var _current_name: StringName = &""


func _ready() -> void:
	owner_body = owner as CharacterBody3D
	for child: Node in get_children():
		if child is PlayerState:
			var state := child as PlayerState
			_states[state.name] = state
			state.machine = self
	if not _states.has(initial_state):
		push_error("PlayerStateMachine: missing initial state %s" % String(initial_state))
		return
	change_state(initial_state)


func get_current_state_name() -> StringName:
	return _current_name


func change_state(state_name: StringName) -> void:
	if _current_name == state_name:
		return
	if not _states.has(state_name):
		push_error("PlayerStateMachine: unknown state %s" % String(state_name))
		return
	var previous := _current_name
	if _current != null:
		_current.exit()
	_current = _states[state_name] as PlayerState
	_current_name = state_name
	_current.enter()
	state_changed.emit(previous, state_name)


func physics_update(delta: float) -> void:
	if _current != null:
		_current.physics_update(delta)
