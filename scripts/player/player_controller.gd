class_name PlayerController
extends CharacterBody3D

@export var move_speed: float = 5.0
@export var acceleration: float = 22.0
@export var deceleration: float = 18.0
@export var rotation_speed: float = 14.0
@export var gravity: float = 28.0
@export var iso_yaw_degrees: float = 45.0

@onready var _state_machine: PlayerStateMachine = $PlayerStateMachine


func _physics_process(delta: float) -> void:
	_state_machine.physics_update(delta)


func get_input_vector() -> Vector2:
	return Input.get_vector("move_left", "move_right", "move_up", "move_down")


func get_world_move_direction() -> Vector3:
	return IsoMoveMath.input_to_world_direction(get_input_vector(), iso_yaw_degrees)


func physics_step(delta: float, direction: Vector3, is_moving: bool) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	var target_velocity := direction * move_speed
	var rate := acceleration if is_moving else deceleration
	velocity.x = move_toward(velocity.x, target_velocity.x, rate * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, rate * delta)

	if is_moving and direction.length_squared() > 0.0001:
		var target_angle := atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target_angle, minf(1.0, rotation_speed * delta))

	move_and_slide()
