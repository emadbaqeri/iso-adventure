class_name PlayerAttackState
extends PlayerState

const ATTACK_TIME := 0.25
const HITBOX_ON := 0.06
const HITBOX_OFF := 0.16

var _elapsed: float = 0.0
var _hitbox_enabled: bool = false


func enter() -> void:
	_elapsed = 0.0
	_hitbox_enabled = false
	var controller := machine.owner_body as PlayerController
	if controller != null:
		controller.snap_to_facing(controller.get_facing_direction())
		controller.begin_attack_visual()


func exit() -> void:
	var controller := machine.owner_body as PlayerController
	if controller != null:
		controller.end_attack_visual()
		controller.set_attack_hitbox_active(false)


func physics_update(delta: float) -> void:
	var controller := machine.owner_body as PlayerController
	if controller == null:
		return

	_elapsed += delta
	_update_hitbox(controller)

	var facing := controller.get_facing_direction()
	controller.physics_step(delta, facing, false, controller.attack_move_multiplier)

	if _elapsed >= ATTACK_TIME:
		controller.start_attack_cooldown()
		if controller.has_move_input():
			machine.change_state(&"Move")
		else:
			machine.change_state(&"Idle")


func _update_hitbox(controller: PlayerController) -> void:
	var should_hit := _elapsed >= HITBOX_ON and _elapsed < HITBOX_OFF
	if should_hit:
		var window := HITBOX_OFF - HITBOX_ON
		var progress := (_elapsed - HITBOX_ON) / window
		if not _hitbox_enabled:
			controller.begin_melee_swing()
		controller.set_melee_swing_progress(progress)
	elif _hitbox_enabled:
		controller.end_melee_swing()
	if should_hit == _hitbox_enabled:
		return
	_hitbox_enabled = should_hit
	controller.set_attack_hitbox_active(should_hit)
