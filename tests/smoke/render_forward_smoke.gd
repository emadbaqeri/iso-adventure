extends SceneTree

## Boot render_test under Forward+ for a few frames; CI greps stderr for ERROR lines.

const WARMUP_FRAMES := 20
const RUN_FRAMES := 30
const PHYSICS_STEP := 1.0 / 60.0


func _initialize() -> void:
	var root_window := get_root() as Window
	if root_window != null:
		root_window.size = Vector2i(1280, 720)
	call_deferred("_boot")


func _boot() -> void:
	var packed := load("res://scenes/levels/test_room.tscn") as PackedScene
	if packed == null:
		push_error("render_forward_smoke: failed to load test_room")
		quit(1)
		return
	var scene := packed.instantiate()
	get_root().add_child(scene)
	var player := scene.get_node_or_null("Player") as PlayerController
	if player != null:
		player.begin_melee_attack()
	for _i: int in range(WARMUP_FRAMES + RUN_FRAMES):
		if player != null:
			player.advance_melee_attack(PHYSICS_STEP)
		await process_frame
	if player != null:
		player.cancel_melee_attack()
	print("render_forward_smoke: OK")
	quit(0)
