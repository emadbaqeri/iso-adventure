class_name SlimeDeadState
extends SlimeState

const DEATH_VISIBLE_TIME := 0.4
const SQUASH_TIME := 0.07

var _elapsed: float = 0.0
var _burst_spawned: bool = false


func enter() -> void:
	_elapsed = 0.0
	_burst_spawned = false
	var slime := machine.owner_body as SlimeEnemy
	if slime == null:
		return
	slime.set_attack_hitbox_active(false)
	slime.collision_layer = 0
	slime.collision_mask = 0
	if slime.hurtbox != null:
		slime.hurtbox.monitoring = false
		slime.hurtbox.collision_layer = 0
	slime.velocity = Vector3.ZERO
	var billboard := slime.get_node_or_null("HealthBillboard") as SlimeHealthBillboard
	if billboard != null:
		billboard.visible = false
	_play_death_sequence(slime)


func physics_update(delta: float) -> void:
	var slime := machine.owner_body as SlimeEnemy
	if slime == null:
		return
	_elapsed += delta
	if _elapsed >= DEATH_VISIBLE_TIME:
		slime.queue_free()


func _play_death_sequence(slime: SlimeEnemy) -> void:
	var visual := slime.visual
	if visual == null:
		_spawn_burst(slime)
		return
	var tween := slime.create_tween()
	tween.tween_property(visual, "scale", Vector3(1.35, 0.38, 1.35), SQUASH_TIME)
	tween.tween_callback(func() -> void:
		visual.visible = false
		_spawn_burst(slime)
	)


func _spawn_burst(slime: SlimeEnemy) -> void:
	if _burst_spawned:
		return
	_burst_spawned = true
	var parent := slime.get_parent()
	if parent == null:
		parent = slime.get_tree().current_scene
	DeathBurstFx.spawn(slime.global_position + Vector3(0.0, 0.55, 0.0), parent, slime.get_burst_tint())
