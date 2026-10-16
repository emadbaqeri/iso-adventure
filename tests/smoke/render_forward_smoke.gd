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
	var packed := load("res://scenes/render_test.tscn") as PackedScene
	if packed == null:
		push_error("render_forward_smoke: failed to load render_test")
		quit(1)
		return
	var scene := packed.instantiate()
	get_root().add_child(scene)
	for _i: int in range(WARMUP_FRAMES + RUN_FRAMES):
		await process_frame
	print("render_forward_smoke: OK")
	quit(0)
