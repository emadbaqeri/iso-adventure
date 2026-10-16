class_name PixelRenderRoot
extends Control

## Centers the low-res SubViewport and upscales with nearest filtering at integer scale.

@export var render_size: Vector2i = Vector2i(640, 360)
@export var sub_viewport_container_path: NodePath = ^"SubViewportContainer"
@export var sub_viewport_path: NodePath = ^"SubViewportContainer/SubViewport"
@export var camera_rig_path: NodePath = ^"SubViewportContainer/SubViewport/PixelCameraRig"
@export var camera_path: NodePath = ^"SubViewportContainer/SubViewport/PixelCameraRig/Camera3D"

@export var quantize_palette: bool = false:
	set(value):
		if _quantize_palette == value:
			return
		_quantize_palette = value
		_apply_post_uniforms()
	get:
		return _quantize_palette

var _quantize_palette: bool = false

@export var palette_texture: Texture2D
@export var mood_controller_path: NodePath

var _container: SubViewportContainer
var _post_material: ShaderMaterial
var _camera: Camera3D


func _ready() -> void:
	_container = get_node(sub_viewport_container_path) as SubViewportContainer
	_container.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_container.stretch = false

	var sub_vp := get_node(sub_viewport_path) as SubViewport
	sub_vp.size = render_size
	_camera = get_node_or_null(camera_path) as Camera3D

	_cache_post_material()
	_apply_post_uniforms()
	resized.connect(_on_resized)
	_on_resized()


func _process(_delta: float) -> void:
	_apply_sub_pixel_offset()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(&"cycle_mood"):
		return
	var mood := get_node_or_null(mood_controller_path) as RenderMoodController
	if mood != null:
		mood.cycle_mood()


func _cache_post_material() -> void:
	var sub_vp := get_node(sub_viewport_path) as SubViewport
	var quad := sub_vp.get_node_or_null("PixelCameraRig/PostProcessQuad") as MeshInstance3D
	if quad == null:
		return
	_post_material = quad.material_override as ShaderMaterial
	if _post_material == null:
		_post_material = quad.get_surface_override_material(0) as ShaderMaterial


func _apply_post_uniforms() -> void:
	if _post_material == null:
		return
	_post_material.set_shader_parameter("use_palette", _quantize_palette)
	if palette_texture != null:
		_post_material.set_shader_parameter("palette_tex", palette_texture)
	_post_material.set_shader_parameter("viewport_size", Vector2(render_size))


func _apply_sub_pixel_offset() -> void:
	if _container == null:
		return
	var rig := get_node_or_null(camera_rig_path) as PixelCameraRig
	if rig == null or _camera == null:
		return
	var scale := integer_scale()
	var vp_offset := PixelCameraMath.remainder_to_viewport_offset_unproject(
		_camera,
		rig.sub_pixel_offset,
		rig.pixel_world_size,
	)
	_container.position = _container_base_position - vp_offset * float(scale)


func integer_scale() -> int:
	return PixelCameraMath.integer_upscale_factor(size, render_size)


var _container_base_position: Vector2 = Vector2.ZERO


func _on_resized() -> void:
	if _container == null:
		return
	var scale := integer_scale()
	var display_size := Vector2(render_size) * float(scale)
	_container.custom_minimum_size = display_size
	_container.size = display_size
	_container_base_position = (size - display_size) * 0.5
	_container.position = _container_base_position
	_apply_sub_pixel_offset()
