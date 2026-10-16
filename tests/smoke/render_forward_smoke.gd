extends SceneTree

## Boot render_test under Forward+ for a few frames; CI greps stderr for ERROR lines.

const WARMUP_FRAMES := 20
const RUN_FRAMES := 15


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
		player.begin_melee_swing()
		player.set_melee_swing_progress(0.65)
	for _i: int in range(WARMUP_FRAMES + RUN_FRAMES):
		await process_frame
	if player != null:
		player.end_attack_visual()
	print("render_forward_smoke: OK")
	quit(0)
