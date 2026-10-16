extends NavigationRegion3D


func _ready() -> void:
	add_to_group("navigation_region")
	call_deferred("_bake_from_world")


func _bake_from_world() -> void:
	var world := get_parent()
	if world == null:
		return
	var nav := navigation_mesh.duplicate() as NavigationMesh
	var geometry := NavigationMeshSourceGeometryData3D.new()
	NavigationServer3D.parse_source_geometry_data(nav, geometry, world)
	NavigationServer3D.bake_from_source_geometry_data(nav, geometry)
	navigation_mesh = nav
