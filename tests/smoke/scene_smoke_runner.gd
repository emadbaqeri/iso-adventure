extends SceneTree

## Headless smoke test: instantiate every scene under res://scenes/.


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: PackedStringArray = await _run_smoke()
	if failures.is_empty():
		print("Scene smoke: OK (%d scenes)" % _count_scenes())
		quit(0)
	else:
		for message: String in failures:
			push_error(message)
		quit(1)


func _count_scenes() -> int:
	var paths: Array[String] = []
	_collect_tscn_paths("res://scenes/", paths)
	return paths.size()


func _run_smoke() -> PackedStringArray:
	var failures: PackedStringArray = []
	var paths: Array[String] = []
	_collect_tscn_paths("res://scenes/", paths)
	if paths.is_empty():
		failures.append("No .tscn files found under res://scenes/")
		return failures
	for scene_path: String in paths:
		var packed: PackedScene = load(scene_path) as PackedScene
		if packed == null:
			failures.append("Failed to load: %s" % scene_path)
			continue
		var instance: Node = packed.instantiate()
		if instance == null:
			failures.append("Failed to instantiate: %s" % scene_path)
			continue
		if (
			scene_path.ends_with("render_test.tscn")
			or scene_path.ends_with("test_room.tscn")
			or scene_path.ends_with("puzzle_room.tscn")
		):
			get_root().add_child(instance)
			for _i: int in range(8):
				await process_frame
			instance.queue_free()
			await process_frame
		else:
			instance.free()
	return failures


func _collect_tscn_paths(dir_path: String, out: Array[String]) -> void:
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		push_error("Cannot open directory: %s" % dir_path)
		return
	dir.list_dir_begin()
	var entry: String = dir.get_next()
	while entry != "":
		if dir.current_is_dir() and not entry.begins_with("."):
			_collect_tscn_paths(dir_path.path_join(entry), out)
		elif entry.ends_with(".tscn"):
			out.append(dir_path.path_join(entry))
		entry = dir.get_next()
	dir.list_dir_end()
