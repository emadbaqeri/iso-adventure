class_name PressureSwitch
extends Area3D

signal pressed_changed(is_pressed: bool)

@export var allow_player: bool = false
@export var press_depth: float = 0.12
@export var move_tween_seconds: float = 0.12

var _is_pressed: bool = false
var _bodies: Dictionary = {}
var _mesh: MeshInstance3D
var _rest_y: float = 0.0
var _rest_color: Color = Color.WHITE
var _pressed_color: Color = Color(0.35, 0.95, 0.45, 1.0)
var _tween: Tween


func _ready() -> void:
	_mesh = get_node_or_null("PlateMesh") as MeshInstance3D
	if _mesh != null:
		_rest_y = _mesh.position.y
		var mat := _mesh.get_active_material(0) as StandardMaterial3D
		if mat != null:
			_mesh.set_surface_override_material(0, mat.duplicate())
			mat = _mesh.get_surface_override_material(0) as StandardMaterial3D
			_rest_color = mat.albedo_color
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	monitoring = true
	monitorable = false
	_update_pressed(false)


func is_pressed() -> bool:
	return _is_pressed


func _on_body_entered(body: Node3D) -> void:
	if not _is_valid_body(body):
		return
	_bodies[body.get_instance_id()] = true
	_recalculate()


func _on_body_exited(body: Node3D) -> void:
	_bodies.erase(body.get_instance_id())
	_recalculate()


func _is_valid_body(body: Node3D) -> bool:
	if body is PushableBlock:
		return true
	if allow_player and body is PlayerController:
		return true
	return false


func _recalculate() -> void:
	var pressed := not _bodies.is_empty()
	if pressed == _is_pressed:
		return
	_update_pressed(pressed)


func _update_pressed(pressed: bool) -> void:
	_is_pressed = pressed
	_animate_plate(pressed)
	pressed_changed.emit(pressed)


func _animate_plate(pressed: bool) -> void:
	if _mesh == null:
		return
	var target_y := _rest_y - press_depth if pressed else _rest_y
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.parallel().tween_property(_mesh, "position:y", target_y, move_tween_seconds)
	var mat := _mesh.get_active_material(0) as StandardMaterial3D
	if mat != null:
		var target_color := _pressed_color if pressed else _rest_color
		_tween.parallel().tween_property(mat, "albedo_color", target_color, move_tween_seconds)
