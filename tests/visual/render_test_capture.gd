extends SceneTree

const WARMUP := 40
const GAP := 6

var _root: Window
var _mood: RenderMoodController


func _initialize() -> void:
	_root = get_root() as Window
	if _root != null:
		_root.size = Vector2i(1280, 720)
	var packed := load("res://scenes/render_test.tscn") as PackedScene
	if packed == null:
		push_error("Failed to load render_test")
		quit(1)
		return
	var scene := packed.instantiate()
	_root.add_child(scene)
	_mood = scene.get_node("MoodController") as RenderMoodController
	call_deferred("_capture_sequence")


func _capture_sequence() -> void:
	for _i: int in range(WARMUP):
		await process_frame

	if _mood != null and _mood.mood_presets.size() > 0:
		_mood.apply_mood(_mood.mood_presets[0])
	for _j: int in range(GAP):
		await process_frame
	_save_capture("warm_day.png")

	if _mood != null and _mood.mood_presets.size() > 1:
		_mood.apply_mood(_mood.mood_presets[1])
	for _k: int in range(GAP):
		await process_frame
	_save_capture("cool_dungeon.png")

	quit(0)


func _save_capture(filename: String) -> void:
	var base := "/workspace/docs/screenshots"
	DirAccess.make_dir_recursive_absolute(base)
	var tex := _root.get_texture()
	if tex == null:
		push_error("No window texture for capture")
		return
	var img: Image = tex.get_image()
	if img == null or img.is_empty():
		push_error("Empty capture image")
		return
	var path := "%s/%s" % [base, filename]
	var err: Error = img.save_png(path)
	print("capture %s err=%s size=%s" % [path, err, img.get_size()])
