class_name SlimeIdleState
extends SlimeState


func physics_update(delta: float) -> void:
	var slime := machine.owner_body as SlimeEnemy
	if slime == null:
		return
	if slime.hurt_lock_time > 0.0:
		return
	slime.step_gravity(delta)
	slime.velocity.x = move_toward(slime.velocity.x, 0.0, 12.0 * delta)
	slime.velocity.z = move_toward(slime.velocity.z, 0.0, 12.0 * delta)
	slime.move_slide()
	if slime.distance_to_player() <= slime.detection_range:
		machine.change_state(&"Chase")
