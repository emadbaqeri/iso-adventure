class_name PlayerController
extends CharacterBody3D

@export_group("Movement")
@export var move_speed: float = 7.5
## Rate to reach top speed (~0.13s at defaults).
@export var acceleration: float = 58.0
## Rate to stop (~0.1s at defaults).
@export var deceleration: float = 75.0
@export var gravity: float = 28.0

@export_group("Facing")
## Higher = snappier turn toward move direction.
@export var rotation_speed: float = 36.0

@export_group("Isometric Camera")
@export var iso_pitch_degrees: float = 35.0
@export var iso_yaw_degrees: float = 45.0

@export_group("Combat")
@export var attack_cooldown: float = 0.45
@export var attack_move_multiplier: float = 0.35
@export var hit_knockback_strength: float = 5.5
@export var hit_knockback_decay: float = 18.0
@export var hit_knockback_duration: float = 0.18

@onready var _state_machine: PlayerStateMachine = $PlayerStateMachine
@onready var _health: HealthComponent = $HealthComponent
@onready var _hurtbox: HurtboxComponent = $Hurtbox
@onready var _sword_rig: PlayerSwordRig = $SwordRig
@onready var _attack_hitbox: HitboxComponent = _sword_rig.get_hitbox()
@onready var _visual: Node3D = $Visual
@onready var _body_mesh: MeshInstance3D = $Visual/Body
@onready var _nose_mesh: MeshInstance3D = $Visual/Nose

var _cooldown_left: float = 0.0
var _last_facing: Vector3 = Vector3.FORWARD
var _hit_knockback: Vector3 = Vector3.ZERO
var _knockback_time_left: float = 0.0
var _damage_flash_time: float = 0.0
var _body_base_color: Color = Color.WHITE
var _nose_base_color: Color = Color.WHITE


func _ready() -> void:
	add_to_group("player")
	_attack_hitbox.owner_root = self
	_duplicate_visual_materials()
	_cache_visual_colors()
	_hurtbox.hit_received.connect(_on_hurtbox_hit)
	_health.damaged.connect(_on_damaged)
	_health.died.connect(_on_died)


func _physics_process(delta: float) -> void:
	if _cooldown_left > 0.0:
		_cooldown_left -= delta
	_tick_damage_flash(delta)
	_tick_knockback(delta)
	_state_machine.physics_update(delta)


func get_input_vector() -> Vector2:
	return PlayerMovementInput.read_move_vector()


func get_world_move_direction() -> Vector3:
	return IsoMoveMath.input_to_world_direction(
		get_input_vector(), iso_pitch_degrees, iso_yaw_degrees
	)


func has_move_input() -> bool:
	return PlayerMovementInput.has_move_input()


func get_facing_direction() -> Vector3:
	if has_move_input():
		var move_dir := get_world_move_direction()
		if move_dir.length_squared() > 0.0001:
			_last_facing = move_dir
	return _last_facing


func get_mesh_forward_flat() -> Vector3:
	var forward := -global_transform.basis.z
	forward.y = 0.0
	if forward.length_squared() < 1e-8:
		return _last_facing
	return forward.normalized()


func snap_to_facing(direction: Vector3) -> void:
	if direction.length_squared() < 1e-8:
		return
	_last_facing = direction.normalized()
	rotation.y = PlayerFacingMath.direction_to_yaw(_last_facing)


func can_attack() -> bool:
	return (
		_cooldown_left <= 0.0
		and _health.is_alive()
		and _sword_rig.is_ready_for_attack()
	)


func try_begin_attack() -> bool:
	if not can_attack():
		return false
	if _state_machine.get_current_state_name() == &"Attack":
		return false
	_state_machine.change_state(&"Attack")
	return true


func start_attack_cooldown() -> void:
	_cooldown_left = attack_cooldown


func get_facing_yaw() -> float:
	return PlayerFacingMath.direction_to_yaw(get_mesh_forward_flat())


func set_attack_hitbox_active(active: bool) -> void:
	if active:
		_attack_hitbox.activate()
		_attack_hitbox.call_deferred("_apply_overlaps")
	else:
		_attack_hitbox.deactivate()


func get_melee_attack_duration() -> float:
	return _sword_rig.get_attack_total_duration()


func begin_melee_attack() -> void:
	_sword_rig.begin_attack_combo(get_facing_yaw())


func advance_melee_attack(delta: float) -> bool:
	return _sword_rig.advance_attack_combo(delta)


func is_melee_strike_active() -> bool:
	return _sword_rig.is_strike_phase()


func cancel_melee_attack() -> void:
	_sword_rig.cancel_attack_combo()
	set_attack_hitbox_active(false)


func apply_hit_knockback(from_world: Vector3) -> void:
	var push := global_position - from_world
	push.y = 0.0
	if push.length_squared() < 1e-6:
		push = _last_facing * -1.0
	push = push.normalized()
	_hit_knockback = push * hit_knockback_strength
	_knockback_time_left = hit_knockback_duration


func is_in_hit_knockback() -> bool:
	return _knockback_time_left > 0.0


func physics_step(
	delta: float,
	direction: Vector3,
	is_moving: bool,
	move_multiplier: float = 1.0
) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	var allow_move_input := is_moving and has_move_input() and not is_in_hit_knockback()

	if is_in_hit_knockback():
		velocity.x = _hit_knockback.x
		velocity.z = _hit_knockback.z
	elif allow_move_input:
		var speed_scale := move_multiplier
		var target_velocity := direction * move_speed * speed_scale
		velocity.x = move_toward(velocity.x, target_velocity.x, acceleration * delta)
		velocity.z = move_toward(velocity.z, target_velocity.z, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)
		velocity.z = move_toward(velocity.z, 0.0, deceleration * delta)
		if absf(velocity.x) < 0.05:
			velocity.x = 0.0
		if absf(velocity.z) < 0.05:
			velocity.z = 0.0

	if allow_move_input and direction.length_squared() > 0.0001:
		var target_yaw := PlayerFacingMath.direction_to_yaw(direction)
		rotation.y = PlayerFacingMath.rotate_yaw_toward(
			rotation.y, target_yaw, delta, rotation_speed
		)
		_last_facing = direction.normalized()

	move_and_slide()


func _on_hurtbox_hit(_damage: int, source: Node) -> void:
	var from_pos := global_position
	if source is Node3D:
		from_pos = (source as Node3D).global_position
	apply_hit_knockback(from_pos)


func _on_damaged(_amount: int, _remaining: int) -> void:
	_flash_damage_material()


func _on_died() -> void:
	set_physics_process(false)
	await get_tree().create_timer(0.35).timeout
	get_tree().reload_current_scene()


func _tick_knockback(delta: float) -> void:
	if _knockback_time_left <= 0.0:
		_hit_knockback = Vector3.ZERO
		return
	_knockback_time_left -= delta
	var decay := hit_knockback_decay * delta
	_hit_knockback = _hit_knockback.move_toward(Vector3.ZERO, decay)
	if _knockback_time_left <= 0.0:
		_hit_knockback = Vector3.ZERO
		velocity.x = 0.0
		velocity.z = 0.0


func _duplicate_visual_materials() -> void:
	for mesh: MeshInstance3D in [_body_mesh, _nose_mesh]:
		var shared := mesh.get_surface_override_material(0) as StandardMaterial3D
		if shared != null:
			mesh.set_surface_override_material(0, shared.duplicate())


func _cache_visual_colors() -> void:
	var body_mat := _body_mesh.get_surface_override_material(0) as StandardMaterial3D
	if body_mat != null:
		_body_base_color = body_mat.albedo_color
	var nose_mat := _nose_mesh.get_surface_override_material(0) as StandardMaterial3D
	if nose_mat != null:
		_nose_base_color = nose_mat.albedo_color


func _flash_damage_material(
	color: Color = Color(1.0, 0.35, 0.35),
	duration: float = 0.12
) -> void:
	_damage_flash_time = duration
	_set_visual_colors(color, color)


func _tick_damage_flash(delta: float) -> void:
	if _damage_flash_time <= 0.0:
		return
	_damage_flash_time -= delta
	if _damage_flash_time <= 0.0:
		_set_visual_colors(_body_base_color, _nose_base_color)


func _set_visual_colors(body_color: Color, nose_color: Color) -> void:
	var body_mat := _body_mesh.get_surface_override_material(0) as StandardMaterial3D
	if body_mat != null:
		body_mat.albedo_color = body_color
	var nose_mat := _nose_mesh.get_surface_override_material(0) as StandardMaterial3D
	if nose_mat != null:
		nose_mat.albedo_color = nose_color
