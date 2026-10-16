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

@onready var _state_machine: PlayerStateMachine = $PlayerStateMachine
@onready var _health: HealthComponent = $HealthComponent
@onready var _attack_hitbox: HitboxComponent = $AttackPivot/AttackHitbox
@onready var _nose_visual: MeshInstance3D = $Visual/Nose
@onready var _body_visual: MeshInstance3D = $Visual/Body

var _cooldown_left: float = 0.0
var _last_facing: Vector3 = Vector3.FORWARD
var _invincible_flash_tick: float = 0.0
var _damage_flash_time: float = 0.0


func _ready() -> void:
	add_to_group("player")
	_attack_hitbox.owner_root = self
	_health.damaged.connect(_on_damaged)
	_health.died.connect(_on_died)


func _physics_process(delta: float) -> void:
	if _cooldown_left > 0.0:
		_cooldown_left -= delta
	_tick_damage_flash(delta)
	_tick_invincible_flash(delta)
	_state_machine.physics_update(delta)


func get_input_vector() -> Vector2:
	return Input.get_vector("move_left", "move_right", "move_up", "move_down")


func get_world_move_direction() -> Vector3:
	return IsoMoveMath.input_to_world_direction(
		get_input_vector(), iso_pitch_degrees, iso_yaw_degrees
	)


func get_facing_direction() -> Vector3:
	var move_dir := get_world_move_direction()
	if move_dir.length_squared() > 0.0001:
		_last_facing = move_dir
	return _last_facing


func can_attack() -> bool:
	return _cooldown_left <= 0.0 and _health.is_alive()


func try_begin_attack() -> bool:
	if not can_attack():
		return false
	if _state_machine.get_current_state_name() == &"Attack":
		return false
	_state_machine.change_state(&"Attack")
	return true


func start_attack_cooldown() -> void:
	_cooldown_left = attack_cooldown


func set_attack_hitbox_active(active: bool) -> void:
	_attack_hitbox.position = Vector3(0.0, 0.75, -0.85)
	if active:
		_attack_hitbox.activate()
	else:
		_attack_hitbox.deactivate()


func begin_attack_visual() -> void:
	_nose_visual.scale = Vector3(1.2, 1.2, 2.0)


func end_attack_visual() -> void:
	_nose_visual.scale = Vector3.ONE
	set_attack_hitbox_active(false)


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

	var speed_scale := move_multiplier
	var target_velocity := direction * move_speed * speed_scale
	var rate := acceleration if is_moving else deceleration
	velocity.x = move_toward(velocity.x, target_velocity.x, rate * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, rate * delta)

	if not is_moving:
		if absf(velocity.x) < 0.05:
			velocity.x = 0.0
		if absf(velocity.z) < 0.05:
			velocity.z = 0.0

	if is_moving and direction.length_squared() > 0.0001:
		var target_yaw := PlayerFacingMath.direction_to_yaw(direction)
		rotation.y = PlayerFacingMath.rotate_yaw_toward(
			rotation.y, target_yaw, delta, rotation_speed
		)
		_last_facing = direction.normalized()

	move_and_slide()


func _on_damaged(_amount: int, _remaining: int) -> void:
	_flash_damage_color()


func _on_died() -> void:
	set_physics_process(false)
	await get_tree().create_timer(0.35).timeout
	get_tree().reload_current_scene()


func _tick_invincible_flash(delta: float) -> void:
	if not _health.invincible:
		_invincible_flash_tick = 0.0
		return
	_invincible_flash_tick -= delta
	if _invincible_flash_tick <= 0.0:
		_flash_damage_color(Color(1.0, 1.0, 1.0), 0.06)
		_invincible_flash_tick = 0.08


func _flash_damage_color(_color: Color = Color(1.0, 0.35, 0.35), duration: float = 0.12) -> void:
	_damage_flash_time = duration
	_body_visual.scale = Vector3(1.08, 0.92, 1.08)
	_nose_visual.scale = Vector3(1.2, 1.2, 1.2)


func _tick_damage_flash(delta: float) -> void:
	if _damage_flash_time <= 0.0:
		return
	_damage_flash_time -= delta
	if _damage_flash_time <= 0.0:
		_body_visual.scale = Vector3.ONE
		_nose_visual.scale = Vector3.ONE
