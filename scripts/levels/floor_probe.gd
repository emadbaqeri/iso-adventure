class_name FloorProbe
extends Object

const WORLD_MASK := CombatLayers.WORLD


static func has_floor_at(
	space: PhysicsDirectSpaceState3D,
	origin: Vector3,
	max_distance: float = 6.0
) -> bool:
	var from := origin + Vector3(0.0, 2.5, 0.0)
	var to := origin + Vector3(0.0, -max_distance, 0.0)
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = WORLD_MASK
	query.collide_with_bodies = true
	query.collide_with_areas = false
	var hit: Dictionary = space.intersect_ray(query)
	return not hit.is_empty()
