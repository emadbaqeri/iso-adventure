class_name PixelRenderRoot
extends Control

## Centers the low-res SubViewport and upscales with nearest filtering at integer scale.

const MIN_SUBVIEWPORT_SIZE := Vector2i(64, 64)

@export var render_size: Vector2i = Vector2i(640, 360)
@export var sub_viewport_container_path: NodePath = ^"SubViewportContainer"
@export var sub_viewport_path: NodePath = ^"SubViewportContainer/SubViewport"
@export var camera_rig_path: NodePath = ^"SubViewportContainer/SubViewport/PixelCameraRig"
@export var camera_path: NodePath = ^"SubViewportContainer/SubViewport/PixelCameraRig/Camera3D"
@export var composite_material: ShaderMaterial

@export var quantize_palette: bool = false:
	set(value):
		if _quantize_palette == value:
			return
		_quantize_palette = value
		_apply_composite_uniforms()
	get:
		return _quantize_palette

var _quantize_palette: bool = false

@export var palette_texture: Texture2D
@export var band_dither: bool = false
@export var mood_controller_path: NodePath

var _container: SubViewportContainer
var _sub_viewport: SubViewport
var _camera: Camera3D
var _stretch_enabled: bool = false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_container = get_node(sub_viewport_container_path) as SubViewportContainer
	_sub_viewport = get_node(sub_viewport_path) as SubViewport
	_container.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_container.stretch = false

	_ensure_subviewport_size()
	if composite_material != null:
		_container.material = composite_material

	_camera = get_node_or_null(camera_path) as Camera3D
	_apply_composite_uniforms()
	get_viewport().size_changed.connect(_on_resized)
	await get_tree().process_frame
	_enable_stretch_layout()
	for _i: int in range(2):
		await get_tree().process_frame
	_on_resized()


func _ensure_subviewport_size() -> void:
	if _sub_viewport == null:
		return
	var safe := Vector2i(
		maxi(render_size.x, MIN_SUBVIEWPORT_SIZE.x),
		maxi(render_size.y, MIN_SUBVIEWPORT_SIZE.y),
	)
	if _sub_viewport.size != safe:
		_sub_viewport.size = safe


func _enable_stretch_layout() -> void:
	_ensure_subviewport_size()
	_container.stretch = true
	_stretch_enabled = true
	_on_resized()


func _process(_delta: float) -> void:
	size = get_viewport().get_visible_rect().size
	_apply_sub_pixel_offset()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"cycle_mood"):
		var mood := get_node_or_null(mood_controller_path) as RenderMoodController
		if mood != null:
			mood.cycle_mood()
		return
	if event.is_action_pressed(&"toggle_band_dither"):
		band_dither = not band_dither
		var mood_ctrl := get_node_or_null(mood_controller_path) as RenderMoodController
		if mood_ctrl != null:
			mood_ctrl.reapply_current_mood()


func _composite_material() -> ShaderMaterial:
	if composite_material != null:
		return composite_material
	return _container.material as ShaderMaterial


func _apply_composite_uniforms() -> void:
	var mat := _composite_material()
	if mat == null:
		return
	mat.set_shader_parameter("use_palette", _quantize_palette)
	if palette_texture != null:
		mat.set_shader_parameter("palette_tex", palette_texture)
	mat.set_shader_parameter("viewport_size", Vector2(_sub_viewport.size if _sub_viewport else render_size))


func _apply_sub_pixel_offset() -> void:
	if _container == null or _camera == null:
		return
	var rig := get_node_or_null(camera_rig_path) as PixelCameraRig
	if rig == null:
		return
	var scale := integer_scale()
	var vp_offset := PixelCameraMath.remainder_to_viewport_offset_unproject(
		_camera,
		rig.sub_pixel_offset,
		rig.pixel_world_size,
	)
	_container.position = _container_base_position - vp_offset * float(scale)


func integer_scale() -> int:
	return PixelCameraMath.integer_upscale_factor(_window_size_i(), render_size)


func _window_size_i() -> Vector2i:
	var vp_size := Vector2i(get_viewport().get_visible_rect().size)
	if vp_size.x > 0 and vp_size.y > 0:
		return vp_size
	var win := DisplayServer.window_get_size()
	if win.x > 0 and win.y > 0:
		return win
	var root := get_tree().root
	if root is Window:
		return (root as Window).size
	return render_size


var _container_base_position: Vector2 = Vector2.ZERO


func _on_resized() -> void:
	if _container == null or not _stretch_enabled:
		return
	var scale := integer_scale()
	var display_size := Vector2(render_size) * float(scale)
	_container.stretch_shrink = scale
	_container.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_container.size = display_size
	var view_size := Vector2(_window_size_i())
	_container_base_position = (view_size - display_size) * 0.5
	_container.position = _container_base_position
	_apply_sub_pixel_offset()
