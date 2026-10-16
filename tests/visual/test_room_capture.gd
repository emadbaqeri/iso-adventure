extends SceneTree

const WARMUP := 45


func _initialize() -> void:
	var root_window := get_root() as Window
	if root_window != null:
		root_window.size = Vector2i(1280, 720)
	call_deferred("_capture")


func _capture() -> void:
	var packed := load("res://scenes/levels/test_room.tscn") as PackedScene
	if packed == null:
		push_error("test_room_capture: failed to load test_room")
		quit(1)
		return
	var scene := packed.instantiate()
	get_root().add_child(scene)
	var player := scene.get_node_or_null("Player") as PlayerController
	if player != null:
		player.rotation.y = deg_to_rad(200.0)
		player.global_position += Vector3(0.5, 0, 0.5)
	for _i: int in range(WARMUP):
		await process_frame
	var base := "/workspace/docs/screenshots"
	DirAccess.make_dir_recursive_absolute(base)
	var tex := (get_root() as Window).get_texture()
	if tex == null:
		push_error("test_room_capture: no window texture")
		quit(1)
		return
	var img := tex.get_image()
	var err := img.save_png("%s/warden_test_room.png" % base)
	print("test_room_capture: saved warden_test_room.png err=%s" % err)
	quit(0 if err == OK else 1)
