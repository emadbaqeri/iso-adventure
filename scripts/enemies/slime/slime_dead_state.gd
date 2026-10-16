class_name SlimeDeadState
extends SlimeState

const FADE_TIME := 0.35

var _elapsed: float = 0.0


func enter() -> void:
	_elapsed = 0.0
	var slime := machine.owner_body as SlimeEnemy
	if slime == null:
		return
	slime.set_attack_hitbox_active(false)
	slime.collision_layer = 0
	slime.collision_mask = 0
	if slime.hurtbox != null:
		slime.hurtbox.monitoring = false
		slime.hurtbox.collision_layer = 0


func physics_update(delta: float) -> void:
	var slime := machine.owner_body as SlimeEnemy
	if slime == null:
		return
	_elapsed += delta
	if _elapsed >= FADE_TIME:
		slime.visible = false
		slime.queue_free()
		return
	var t := clampf(_elapsed / FADE_TIME, 0.0, 1.0)
	SafeTransform3D.apply_uniform_scale(slime, 1.0 - t)
