class_name PlayerAttackState
extends PlayerState

var _hitbox_enabled: bool = false


func enter() -> void:
	_hitbox_enabled = false
	var controller := machine.owner_body as PlayerController
	if controller == null:
		return
	controller.snap_to_facing(controller.get_facing_direction())
	controller.begin_melee_attack()


func exit() -> void:
	var controller := machine.owner_body as PlayerController
	if controller == null:
		return
	controller.cancel_melee_attack()
	controller.set_attack_hitbox_active(false)


func physics_update(delta: float) -> void:
	var controller := machine.owner_body as PlayerController
	if controller == null:
		return

	var still_attacking := controller.advance_melee_attack(delta)
	_update_hitbox(controller)

	var facing := controller.get_facing_direction()
	controller.physics_step(delta, facing, false, controller.attack_move_multiplier)

	if not still_attacking:
		controller.start_attack_cooldown()
		if controller.has_move_input():
			machine.change_state(&"Move")
		else:
			machine.change_state(&"Idle")


func _update_hitbox(controller: PlayerController) -> void:
	var should_hit := controller.is_melee_strike_active()
	if should_hit == _hitbox_enabled:
		return
	_hitbox_enabled = should_hit
	controller.set_attack_hitbox_active(should_hit)
