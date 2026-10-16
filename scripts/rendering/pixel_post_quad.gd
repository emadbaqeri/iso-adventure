extends MeshInstance3D

## Fullscreen ortho quad in front of the camera for spatial post-processing.

@export var camera_path: NodePath = ^"../Camera3D"
@export var render_aspect: float = 640.0 / 360.0

var _camera: Camera3D
var _quad: QuadMesh


func _ready() -> void:
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	_quad = QuadMesh.new()
	mesh = _quad
	_camera = get_node_or_null(camera_path) as Camera3D
	if material_override is ShaderMaterial:
		(material_override as ShaderMaterial).render_priority = 127
	_update_quad_size()


func _process(_delta: float) -> void:
	_update_quad_size()


func _update_quad_size() -> void:
	if _camera == null or _quad == null:
		return
	var height := _camera.size * 2.0
	var width := height * render_aspect
	_quad.size = Vector2(width, height)
	position = Vector3(0.0, 0.0, -1.0)
	rotation_degrees = Vector3(0.0, 180.0, 0.0)
