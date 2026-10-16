extends SceneTree

const WARMUP := 45
const CAPTURES := 10
const GAP := 4

var _root: Window
var _scene: Node
var _mood: RenderMoodController
var _sub_viewport: SubViewport


func _initialize() -> void:
	_root = get_root() as Window
	if _root != null:
		_root.size = Vector2i(1280, 720)
	var packed := load("res://scenes/render_test.tscn") as PackedScene
	if packed == null:
		push_error("Failed to load render_test")
		quit(1)
		return
	_scene = packed.instantiate()
	_root.add_child(_scene)
	if _scene is Control:
		(_scene as Control).set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_sub_viewport = _scene.get_node("SubViewportContainer/SubViewport") as SubViewport
	_mood = _scene.get_node("SubViewportContainer/SubViewport/MoodController") as RenderMoodController
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
	var img := _grab_image()
	if img == null:
		push_error("No frame image at index %d" % index)
		return
	var path := "%s/frame_%02d.png" % [base, index]
	var save_img := img.duplicate()
	var target := Vector2i(1280, 720)
	if save_img.get_width() < target.x:
		var factor: int = target.x / save_img.get_width()
		save_img.resize(save_img.get_width() * factor, save_img.get_height() * factor, Image.INTERPOLATE_NEAREST)
	var err: Error = save_img.save_png(path)
	print("capture %s err=%s size=%s renderer=%s" % [path, err, save_img.get_size(), _renderer_label()])


func _grab_image() -> Image:
	if _root != null and _root.get_texture() != null:
		var win_img := _root.get_texture().get_image()
		if win_img != null and win_img.get_width() >= 640:
			return win_img
	if _sub_viewport == null:
		return null
	var vp_tex := _sub_viewport.get_texture()
	if vp_tex == null or vp_tex.get_width() < 16:
		return null
	return vp_tex.get_image()


func _renderer_label() -> String:
	if RenderingServer.get_rendering_device() != null:
		return "Forward+"
	return "Compatibility"
