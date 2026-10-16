extends SceneTree

## Forward+ stability: static geometry + snapped pan should not crawl outline texels.

const WARMUP_FRAMES := 35
const HOLD_FRAMES := 24
const PAN_STEPS := 16
const COLOR_EPS := 0.02
const PAN_INTERIOR_BORDER := 14


func _initialize() -> void:
	var root_window := get_root() as Window
	if root_window != null:
		root_window.size = Vector2i(1280, 720)
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scenes/render_test.tscn") as PackedScene
	if packed == null:
		push_error("outline_stability: failed to load render_test")
		quit(1)
		return

	var scene := packed.instantiate()
	if scene is Control:
		(scene as Control).set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	get_root().add_child(scene)

	var sub_vp := scene.get_node("SubViewportContainer/SubViewport") as SubViewport
	var rig := scene.get_node("SubViewportContainer/SubViewport/PixelCameraRig") as PixelCameraRig
	var camera := rig.get_node(rig.camera_path) as Camera3D
	var mover := scene.get_node("SubViewportContainer/SubViewport/World/MovingCube") as Node3D
	var pillar := scene.get_node("SubViewportContainer/SubViewport/World/PillarA") as MeshInstance3D

	if sub_vp == null or rig == null or camera == null or pillar == null:
		push_error("outline_stability: missing scene nodes")
		quit(1)
		return

	if mover.has_method("set") and mover.get("speed") != null:
		mover.set("speed", 0.0)

	var pan_focus := Node3D.new()
	pan_focus.name = "OutlineStabilityFocus"
	scene.get_node("SubViewportContainer/SubViewport/World").add_child(pan_focus)
	pan_focus.global_position = Vector3(0.0, 1.0, 0.0)
	rig.follow_target_path = pan_focus.get_path()

	for _i: int in range(WARMUP_FRAMES):
		await process_frame

	var static_roi := _mesh_screen_rect(camera, sub_vp, pillar)
	if static_roi.size.x < 8 or static_roi.size.y < 8:
		push_error("outline_stability: static ROI too small %s" % static_roi)
		quit(1)
		return

	var hold_diff := 0
	await process_frame
	var ref_hold := _capture_subviewport(sub_vp)
	for _j: int in range(HOLD_FRAMES):
		await process_frame
		var frame := _capture_subviewport(sub_vp)
		hold_diff += _count_diff(ref_hold, frame, static_roi)

	var pan_diff := 0
	var prev := _capture_subviewport(sub_vp)
	var prev_screen := camera.unproject_position(pillar.global_position)
	for step: int in range(PAN_STEPS):
		pan_focus.global_position += camera.global_transform.basis.x * rig.pixel_world_size
		await process_frame
		var cur := _capture_subviewport(sub_vp)
		var cur_screen := camera.unproject_position(pillar.global_position)
		var shift := Vector2i(
			int(round(cur_screen.x - prev_screen.x)),
			int(round(cur_screen.y - prev_screen.y)),
		)
		var roi: Rect2i = _interior_roi(_mesh_screen_rect(camera, sub_vp, pillar), PAN_INTERIOR_BORDER)
		pan_diff += _count_diff_aligned(prev, cur, roi, shift)
		prev = cur
		prev_screen = cur_screen

	print(
		"outline_stability: static_hold_changed_pixels=%d pan_aligned_changed_pixels=%d roi=%s"
		% [hold_diff, pan_diff, static_roi]
	)

	if hold_diff != 0:
		push_error("outline_stability: static hold drift %d (expected 0)" % hold_diff)
	quit(0 if hold_diff == 0 else 1)


func _interior_roi(roi: Rect2i, border: int) -> Rect2i:
	var inset := Vector2i(border, border)
	var size := Vector2i(maxi(1, roi.size.x - border * 2), maxi(1, roi.size.y - border * 2))
	return Rect2i(roi.position + inset, size)


func _capture_subviewport(sub_vp: SubViewport) -> Image:
	var tex := sub_vp.get_texture()
	if tex == null:
		return Image.create(640, 360, false, Image.FORMAT_RGB8)
	var img: Image = tex.get_image()
	if img == null or img.is_empty():
		return Image.create(640, 360, false, Image.FORMAT_RGB8)
	return img


func _mesh_screen_rect(camera: Camera3D, sub_vp: SubViewport, mesh: MeshInstance3D) -> Rect2i:
	var aabb := mesh.get_aabb()
	var xform := mesh.global_transform
	var min_p := Vector3.INF
	var max_p := -Vector3.INF
	for i: int in range(8):
		var corner := aabb.get_endpoint(i)
		var world := xform * corner
		var screen := camera.unproject_position(world)
		min_p.x = minf(min_p.x, screen.x)
		min_p.y = minf(min_p.y, screen.y)
		max_p.x = maxf(max_p.x, screen.x)
		max_p.y = maxf(max_p.y, screen.y)

	var margin := 4
	var x0 := clampi(int(min_p.x) + margin, 0, sub_vp.size.x - 1)
	var y0 := clampi(int(min_p.y) + margin, 0, sub_vp.size.y - 1)
	var x1 := clampi(int(max_p.x) - margin, 0, sub_vp.size.x - 1)
	var y1 := clampi(int(max_p.y) - margin, 0, sub_vp.size.y - 1)
	return Rect2i(x0, y0, maxi(1, x1 - x0), maxi(1, y1 - y0))


func _count_diff(a: Image, b: Image, roi: Rect2i) -> int:
	var changed := 0
	for y: int in range(roi.position.y, roi.position.y + roi.size.y):
		for x: int in range(roi.position.x, roi.position.x + roi.size.x):
			if not _in_image(a, x, y) or not _in_image(b, x, y):
				continue
			var ca: Color = a.get_pixel(x, y)
			var cb: Color = b.get_pixel(x, y)
			if _colors_close(ca, cb):
				continue
			changed += 1
	return changed


func _count_diff_aligned(a: Image, b: Image, roi: Rect2i, screen_delta: Vector2i) -> int:
	var changed := 0
	for y: int in range(roi.position.y, roi.position.y + roi.size.y):
		for x: int in range(roi.position.x, roi.position.x + roi.size.x):
			var ax := x - screen_delta.x
			var ay := y - screen_delta.y
			if not _in_image(a, ax, ay) or not _in_image(b, x, y):
				continue
			var ca: Color = a.get_pixel(ax, ay)
			var cb: Color = b.get_pixel(x, y)
			if _colors_close(ca, cb):
				continue
			changed += 1
	return changed


func _colors_close(a: Color, b: Color) -> bool:
	if a.is_equal_approx(b):
		return true
	return (
		absf(a.r - b.r) <= COLOR_EPS
		and absf(a.g - b.g) <= COLOR_EPS
		and absf(a.b - b.b) <= COLOR_EPS
	)


func _in_image(img: Image, x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height()
