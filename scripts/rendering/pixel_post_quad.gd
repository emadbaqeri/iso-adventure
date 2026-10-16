extends MeshInstance3D

## Fullscreen ortho quad attached to the active camera (not the rig root).

@export var camera_path: NodePath = ^".."
@export var render_aspect: float = 640.0 / 360.0

var _camera: Camera3D
var _quad: QuadMesh


func _ready() -> void:
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	_quad = QuadMesh.new()
	mesh = _quad
	_camera = get_node_or_null(camera_path) as Camera3D
	visible = false
	_pick_post_shader()
	if material_override is ShaderMaterial:
		(material_override as ShaderMaterial).render_priority = 127
	_update_quad_size()
	await get_tree().process_frame
	await get_tree().process_frame
	visible = true


func _pick_post_shader() -> void:
	var shader_path := "res://shaders/pixel_post_compat.gdshader"
	if _uses_forward_plus():
		shader_path = "res://shaders/pixel_post.gdshader"
	var shader := load(shader_path) as Shader
	if shader == null:
		push_error("PixelPostQuad: failed to load %s" % shader_path)
		return
	var mat := ShaderMaterial.new()
	if material_override is ShaderMaterial:
		var old := material_override as ShaderMaterial
		mat.set_shader_parameter("viewport_size", old.get_shader_parameter("viewport_size"))
		mat.set_shader_parameter("use_palette", old.get_shader_parameter("use_palette"))
		mat.set_shader_parameter("palette_tex", old.get_shader_parameter("palette_tex"))
		mat.set_shader_parameter("outline_light", old.get_shader_parameter("outline_light"))
		mat.set_shader_parameter("outline_darken", old.get_shader_parameter("outline_darken"))
	mat.shader = shader
	material_override = mat


func _uses_forward_plus() -> bool:
	if _is_opengl_compatibility_driver():
		return false
	return RenderingServer.get_rendering_device() != null


func _is_opengl_compatibility_driver() -> bool:
	var args := OS.get_cmdline_args()
	for i: int in range(args.size()):
		if args[i] == "--rendering-driver" and i + 1 < args.size():
			var driver: String = args[i + 1]
			return driver == "opengl3" or driver == "gl_compatibility"
	return false


func _process(_delta: float) -> void:
	_update_quad_size()


func _update_quad_size() -> void:
	if _camera == null or _quad == null:
		return
	var height := _camera.size * 2.0
	var width := height * render_aspect
	_quad.size = Vector2(width, height)
	position = Vector3(0.0, 0.0, -0.25)
	rotation_degrees = Vector3(0.0, 180.0, 0.0)
