class_name LevelPerimeterBounds
extends Node3D

@export var floor_center: Vector3 = Vector3(4.0, 0.0, 0.0)
@export var half_size_x: float = 17.0
@export var half_size_z: float = 13.0
@export var wall_height: float = 4.0
@export var wall_thickness: float = 1.0

const SEGMENT_SCENE := preload("res://scenes/levels/level_boundary_segment.tscn")


func _ready() -> void:
	_build_perimeter()


func _build_perimeter() -> void:
	var north_z := floor_center.z - half_size_z - wall_thickness * 0.5
	var south_z := floor_center.z + half_size_z + wall_thickness * 0.5
	var west_x := floor_center.x - half_size_x - wall_thickness * 0.5
	var east_x := floor_center.x + half_size_x + wall_thickness * 0.5
	var span_x := half_size_x * 2.0 + wall_thickness
	var span_z := half_size_z * 2.0 + wall_thickness
	_add_segment(
		Vector3(floor_center.x, wall_height * 0.5, north_z), Vector3(span_x, wall_height, wall_thickness)
	)
	_add_segment(
		Vector3(floor_center.x, wall_height * 0.5, south_z), Vector3(span_x, wall_height, wall_thickness)
	)
	_add_segment(
		Vector3(west_x, wall_height * 0.5, floor_center.z), Vector3(wall_thickness, wall_height, span_z)
	)
	_add_segment(
		Vector3(east_x, wall_height * 0.5, floor_center.z), Vector3(wall_thickness, wall_height, span_z)
	)


func _add_segment(center: Vector3, size: Vector3) -> void:
	var segment := SEGMENT_SCENE.instantiate() as LevelBoundarySegment
	segment.position = center
	var collision := segment.get_node("CollisionShape3D") as CollisionShape3D
	var box := BoxShape3D.new()
	box.size = size
	collision.shape = box
	var debug_mesh := segment.get_node("DebugMesh") as MeshInstance3D
	var debug_box := BoxMesh.new()
	debug_box.size = size
	debug_mesh.mesh = debug_box
	add_child(segment)
