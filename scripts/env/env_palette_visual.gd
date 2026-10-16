class_name EnvPaletteVisual
extends Node3D

## Applies shared env palette material to imported glTF meshes (nearest-filter flat color).

const PALETTE_MAT := preload("res://materials/lowpoly_palette_env.tres")


func _ready() -> void:
	var mat := PALETTE_MAT.duplicate() as StandardMaterial3D
	_apply_material(self, mat)


func _apply_material(node: Node, mat: StandardMaterial3D) -> void:
	if node is MeshInstance3D:
		var mesh := node as MeshInstance3D
		if mesh.mesh != null:
			for surface_idx: int in mesh.mesh.get_surface_count():
				mesh.set_surface_override_material(surface_idx, mat)
	for child: Node in node.get_children():
		_apply_material(child, mat)
