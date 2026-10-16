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

@onready var _state_machine: PlayerStateMachine = $PlayerStateMachine


func _physics_process(delta: float) -> void:
	_state_machine.physics_update(delta)


func get_input_vector() -> Vector2:
	return Input.get_vector("move_left", "move_right", "move_up", "move_down")


func get_world_move_direction() -> Vector3:
	return IsoMoveMath.input_to_world_direction(
		get_input_vector(), iso_pitch_degrees, iso_yaw_degrees
	)


func physics_step(delta: float, direction: Vector3, is_moving: bool) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	var target_velocity := direction * move_speed
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

	move_and_slide()
