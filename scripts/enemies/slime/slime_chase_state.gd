class_name SlimeChaseState
extends SlimeState


func physics_update(delta: float) -> void:
	var slime := machine.owner_body as SlimeEnemy
	if slime == null:
		return
	if slime.hurt_lock_time > 0.0:
		return
	var dist := slime.distance_to_player()
	if dist > slime.detection_range * 1.25:
		machine.change_state(&"Idle")
		return
	if dist <= slime.attack_range:
		machine.change_state(&"Attack")
		return
	var dir := slime.get_chase_direction()
	slime.step_gravity(delta)
	slime.velocity.x = dir.x * slime.chase_speed
	slime.velocity.z = dir.z * slime.chase_speed
	if dir.length_squared() > 0.0001:
		SafeTransform3D.look_flat_y(slime, dir)
	slime.move_slide()
