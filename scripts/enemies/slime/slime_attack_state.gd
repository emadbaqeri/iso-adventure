class_name SlimeAttackState
extends SlimeState


func enter() -> void:
	var slime := machine.owner_body as SlimeEnemy
	if slime == null:
		return
	slime.telegraph_elapsed = 0.0
	slime.lunge_elapsed = 0.0
	slime.lunge_direction = slime.direction_to_player_flat()
	slime.set_telegraph_visual(true)
	slime.set_attack_hitbox_active(false)


func exit() -> void:
	var slime := machine.owner_body as SlimeEnemy
	if slime != null:
		slime.set_telegraph_visual(false)
		slime.set_attack_hitbox_active(false)


func physics_update(delta: float) -> void:
	var slime := machine.owner_body as SlimeEnemy
	if slime == null:
		return
	slime.step_gravity(delta)
	if slime.telegraph_elapsed < slime.telegraph_time:
		slime.telegraph_elapsed += delta
		slime.velocity.x = 0.0
		slime.velocity.z = 0.0
		slime.move_slide()
		return
	slime.set_telegraph_visual(false)
	slime.lunge_elapsed += delta
	slime.set_attack_hitbox_active(true)
	var dir := slime.lunge_direction
	slime.velocity.x = dir.x * slime.lunge_speed
	slime.velocity.z = dir.z * slime.lunge_speed
	slime.move_slide()
	if slime.lunge_elapsed >= slime.lunge_time:
		machine.change_state(&"Chase")
