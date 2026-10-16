extends SceneTree

const WARMUP := 15
const CAPTURES := 10
const GAP := 4

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
	if scene is Control:
		var control := scene as Control
		control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		control.set_size(Vector2(1280, 720))
	if _root != null:
		_root.size = Vector2i(1280, 720)
	_mood = scene.get_node("SubViewportContainer/SubViewport/MoodController") as RenderMoodController
	call_deferred("_capture_sequence")


func _capture_sequence() -> void:
	for _i: int in range(WARMUP):
		await process_frame

	if _mood != null and _mood.mood_presets.size() > 0:
		_mood.apply_mood(_mood.mood_presets[0])

	for index: int in range(CAPTURES):
		_save_capture(index)
		if index == 4 and _mood != null:
			_mood.cycle_mood()
		for _j: int in range(GAP):
			await process_frame

	quit(0)


func _save_capture(index: int) -> void:
	var base := "/workspace/docs/screenshots"
	DirAccess.make_dir_recursive_absolute(base)
	var tex := _root.get_texture()
	if tex == null:
		push_error("No window texture")
		return
	var img := tex.get_image()
	if img == null:
		push_error("No image")
		return
	var path := "%s/frame_%02d.png" % [base, index]
	var err := img.save_png(path)
	print("capture %s err=%s size=%s" % [path, err, img.get_size()])
