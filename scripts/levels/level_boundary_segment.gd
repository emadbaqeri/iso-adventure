class_name LevelBoundarySegment
extends StaticBody3D

@export var debug_color: Color = Color(1.0, 0.2, 0.2, 0.35)

var _debug_mesh: MeshInstance3D


func _ready() -> void:
	add_to_group("level_boundary")
	_debug_mesh = get_node_or_null("DebugMesh") as MeshInstance3D
	_apply_debug_visible(BoundaryDebug.is_visible())


func set_debug_visible(should_show: bool) -> void:
	_apply_debug_visible(should_show)


func _apply_debug_visible(should_show: bool) -> void:
	if _debug_mesh == null:
		return
	if _debug_mesh.material_override == null and _debug_mesh.mesh != null:
		var mat := StandardMaterial3D.new()
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color = debug_color
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		_debug_mesh.material_override = mat
	_debug_mesh.visible = should_show
