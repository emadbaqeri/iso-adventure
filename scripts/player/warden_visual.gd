class_name WardenVisual
extends Node3D

## Drives imported glTF clips from the player state machine (Idle / Move / Attack).

const STATE_ANIMATIONS: Dictionary = {
	&"Idle": &"idle",
	&"Move": &"run",
	&"Attack": &"attack",
}

@export var run_speed_reference: float = 7.5
@export var run_anim_speed_min: float = 0.65
@export var run_anim_speed_max: float = 1.45

var _animation_player: AnimationPlayer
var _animation_tree: AnimationTree
var _state_playback: AnimationNodeStateMachinePlayback
var _player: PlayerController
var _current_state: StringName = &""
var _palette_material: StandardMaterial3D
var _base_albedo: Color = Color.WHITE


func _ready() -> void:
	_player = _find_player()
	_animation_player = _find_animation_player()
	_setup_animation_tree()
	_setup_palette_material()
	_connect_state_machine()
	_play_for_state(_current_state if _current_state != &"" else &"Idle")


func _physics_process(_delta: float) -> void:
	if _animation_player == null or _player == null:
		return
	if _current_state != &"Move":
		return
	var horiz := Vector2(_player.velocity.x, _player.velocity.z).length()
	var t := clampf(horiz / run_speed_reference, 0.0, 1.0)
	var speed := lerpf(run_anim_speed_min, run_anim_speed_max, t)
	if _animation_player.current_animation == String(STATE_ANIMATIONS[&"Move"]):
		_animation_player.speed_scale = speed


func get_animation_name_for_state(state_name: StringName) -> StringName:
	return STATE_ANIMATIONS.get(state_name, &"idle")


func apply_damage_tint(tint: Color) -> void:
	if _palette_material != null:
		_palette_material.albedo_color = tint


func reset_damage_tint() -> void:
	if _palette_material != null:
		_palette_material.albedo_color = _base_albedo


func _find_player() -> PlayerController:
	var node: Node = self
	while node != null:
		if node is PlayerController:
			return node as PlayerController
		node = node.get_parent()
	return null


func _find_animation_player() -> AnimationPlayer:
	var found := find_child("AnimationPlayer", true, false) as AnimationPlayer
	if found != null:
		return found
	for child: Node in get_children():
		var nested := child.find_child("AnimationPlayer", true, false) as AnimationPlayer
		if nested != null:
			return nested
	return null


func _connect_state_machine() -> void:
	if _player == null:
		return
	var sm := _player.get_node_or_null("PlayerStateMachine") as PlayerStateMachine
	if sm == null:
		return
	if not sm.state_changed.is_connected(_on_state_changed):
		sm.state_changed.connect(_on_state_changed)
	_current_state = sm.get_current_state_name()


func _on_state_changed(_previous: StringName, current: StringName) -> void:
	_play_for_state(current)


func _play_for_state(state_name: StringName) -> void:
	_current_state = state_name
	if _animation_player == null:
		return
	var anim_name := String(get_animation_name_for_state(state_name))
	if not _animation_player.has_animation(anim_name):
		push_warning("WardenVisual: missing animation '%s'" % anim_name)
		return
	if _state_playback != null:
		_state_playback.travel(anim_name)
	elif _animation_player.current_animation != anim_name:
		_animation_player.play(anim_name)
	if state_name == &"Move":
		_animation_player.speed_scale = 1.0
	elif state_name == &"Idle":
		_animation_player.speed_scale = 1.0
	else:
		_animation_player.speed_scale = 1.0


func _setup_animation_tree() -> void:
	_animation_tree = get_node_or_null("AnimationTree") as AnimationTree
	if _animation_player == null:
		return
	if _animation_tree == null:
		_animation_tree = AnimationTree.new()
		_animation_tree.name = "AnimationTree"
		add_child(_animation_tree)
	var state_machine := AnimationNodeStateMachine.new()
	for anim_key: StringName in STATE_ANIMATIONS.values():
		var anim_node := AnimationNodeAnimation.new()
		anim_node.animation = String(anim_key)
		state_machine.add_node(String(anim_key), anim_node)
	for from_anim: String in ["idle", "run", "attack"]:
		for to_anim: String in ["idle", "run", "attack"]:
			if from_anim == to_anim:
				continue
			var transition := AnimationNodeStateMachineTransition.new()
			transition.xfade_time = 0.08
			state_machine.add_transition(StringName(from_anim), StringName(to_anim), transition)
	var entry := AnimationNodeStateMachineTransition.new()
	entry.xfade_time = 0.0
	state_machine.add_transition(&"Start", &"idle", entry)
	_animation_tree.tree_root = state_machine
	_animation_tree.anim_player = _animation_tree.get_path_to(_animation_player)
	_animation_tree.active = true
	_state_playback = _animation_tree.get("parameters/playback") as AnimationNodeStateMachinePlayback


func _setup_palette_material() -> void:
	var palette := load("res://materials/lowpoly_palette_warden.tres") as StandardMaterial3D
	if palette == null:
		return
	_palette_material = palette.duplicate() as StandardMaterial3D
	_base_albedo = _palette_material.albedo_color
	_apply_material_to_meshes(self)


func _apply_material_to_meshes(node: Node) -> void:
	if node is MeshInstance3D:
		var mesh := node as MeshInstance3D
		if _palette_material != null and mesh.mesh != null:
			for surface_idx: int in mesh.mesh.get_surface_count():
				mesh.set_surface_override_material(surface_idx, _palette_material)
	for child: Node in node.get_children():
		_apply_material_to_meshes(child)
