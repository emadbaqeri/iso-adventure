class_name PlayerIdleState
extends PlayerState


func physics_update(delta: float) -> void:
	var controller := machine.owner_body as PlayerController
	if controller == null:
		return
	if Input.is_action_just_pressed("attack") and controller.try_begin_attack():
		return
	if controller.get_input_vector().length_squared() > 0.01:
		machine.change_state(&"Move")
		return
	controller.physics_step(delta, Vector3.ZERO, false)
