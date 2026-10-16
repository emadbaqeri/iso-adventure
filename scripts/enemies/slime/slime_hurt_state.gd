class_name SlimeHurtState
extends SlimeState

const HURT_TIME := 0.22


var _elapsed: float = 0.0


func enter() -> void:
	_elapsed = 0.0
	var slime := machine.owner_body as SlimeEnemy
	if slime == null:
		return
	slime.hurt_lock_time = HURT_TIME
	slime.set_attack_hitbox_active(false)
	var player := slime.get_player()
	if player != null:
		slime.apply_knockback(player.global_position)


func physics_update(delta: float) -> void:
	var slime := machine.owner_body as SlimeEnemy
	if slime == null:
		return
	_elapsed += delta
	slime.step_gravity(delta)
	slime.velocity.x = move_toward(slime.velocity.x, 0.0, 18.0 * delta)
	slime.velocity.z = move_toward(slime.velocity.z, 0.0, 18.0 * delta)
	slime.move_slide()
	if _elapsed >= HURT_TIME and slime.health.is_alive():
		if slime.distance_to_player() <= slime.attack_range:
			machine.change_state(&"Attack")
		elif slime.distance_to_player() <= slime.detection_range:
			machine.change_state(&"Chase")
		else:
			machine.change_state(&"Idle")
