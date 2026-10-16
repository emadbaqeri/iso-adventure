extends SceneTree

## Boot test_room under Forward+; exercise gate + puzzle door collision toggles. CI greps stderr for ERROR lines.

const WARMUP_FRAMES := 24
const RUN_FRAMES := 36
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
	await process_frame
	await process_frame
	_exercise_gate_and_door(scene)
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


func _exercise_gate_and_door(scene: Node) -> void:
	var gate := scene.get_node_or_null("PuzzleAccessGate") as PuzzleRoomAccess
	if gate != null:
		gate.force_open()
	var puzzle := scene.get_node_or_null("PuzzleRoom")
	if puzzle == null:
		return
	var door := puzzle.get_node_or_null("Door") as Door
	if door != null:
		door.set_open(true, false)
		door.set_open(false, true)
		door.set_open(true, true)
