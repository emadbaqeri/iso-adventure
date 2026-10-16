class_name SlimeHealthBillboard
extends Node3D

const DOT_SPACING := 0.22
const DOT_RADIUS := 0.07

@export var health_path: NodePath = NodePath("../HealthComponent")
@export var height_offset: float = 1.15

var _health: HealthComponent
var _dots: Array[MeshInstance3D] = []
var _revealed: bool = false


func _ready() -> void:
	position = Vector3(0.0, height_offset, 0.0)
	_health = get_node_or_null(health_path) as HealthComponent
	if _health == null:
		return
	_build_dots(_health.max_health)
	_health.damaged.connect(_on_damaged)
	_update_dots(_health.current_health)
	visible = false


func _process(_delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var cam_basis := camera.global_transform.basis
	global_transform.basis = Basis(cam_basis.x, cam_basis.y, cam_basis.z)


func _build_dots(count: int) -> void:
	_dots.clear()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.95, 0.25, 0.28)
	mat.emission_enabled = true
	mat.emission = Color(0.6, 0.1, 0.12)
	var mesh := SphereMesh.new()
	mesh.radius = DOT_RADIUS
	mesh.height = DOT_RADIUS * 2.0
	var start_x := -DOT_SPACING * (count - 1) * 0.5
	for i: int in range(count):
		var dot := MeshInstance3D.new()
		dot.mesh = mesh
		dot.set_surface_override_material(0, mat)
		dot.position = Vector3(start_x + i * DOT_SPACING, 0.0, 0.0)
		add_child(dot)
		_dots.append(dot)


func _on_damaged(_amount: int, remaining: int) -> void:
	if not _revealed:
		_revealed = true
		visible = true
	_update_dots(remaining)


func _update_dots(remaining: int) -> void:
	for i: int in range(_dots.size()):
		_dots[i].visible = i < remaining
