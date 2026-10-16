class_name PuzzleGoal
extends Area3D

signal goal_reached

@export var glow_energy: float = 2.4

var _mesh: MeshInstance3D


func _ready() -> void:
	_mesh = get_node_or_null("PedestalMesh") as MeshInstance3D
	if _mesh != null:
		var mat := _mesh.get_active_material(0) as StandardMaterial3D
		if mat != null:
			mat.emission_enabled = true
			mat.emission = Color(0.45, 0.85, 1.0, 1.0)
			mat.emission_energy_multiplier = glow_energy
	body_entered.connect(_on_body_entered)
	monitoring = true
	monitorable = false


func _on_body_entered(body: Node3D) -> void:
	if body is PlayerController:
		goal_reached.emit()
