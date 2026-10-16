class_name PathClearanceProbe
extends Object

const WORLD_MASK := CombatLayers.WORLD
const PLAYER_RADIUS := 0.35
const WAIST_HEIGHT := 1.0


static func motion_clear(
	space: PhysicsDirectSpaceState3D,
	from: Vector3,
	to: Vector3
) -> bool:
	var motion := to - from
	motion.y = 0.0
	var distance := motion.length()
	if distance < 0.0001:
		return true
	var steps := maxi(4, int(ceil(distance / 0.75)))
	for step_index: int in range(steps + 1):
		var t := float(step_index) / float(steps)
		var sample := from.lerp(to, t)
		if _body_blocks_motion(space, sample):
			return false
	return true


static func _body_blocks_motion(space: PhysicsDirectSpaceState3D, point: Vector3) -> bool:
	var shape := SphereShape3D.new()
	shape.radius = PLAYER_RADIUS
	var params := PhysicsShapeQueryParameters3D.new()
	params.shape = shape
	params.transform = Transform3D(Basis.IDENTITY, point + Vector3(0.0, WAIST_HEIGHT, 0.0))
	params.collision_mask = WORLD_MASK
	params.collide_with_bodies = true
	params.collide_with_areas = false
	var hits: Array[Dictionary] = space.intersect_shape(params, 16)
	for hit: Dictionary in hits:
		var collider := hit.get("collider") as Node
		if collider == null:
			continue
		if collider.is_in_group("level_floor"):
			continue
		return true
	return false


static func path_is_clear(space: PhysicsDirectSpaceState3D, points: Array[Vector3]) -> bool:
	if points.is_empty():
		return false
	if not FloorProbe.has_floor_at(space, points[0]):
		return false
	for index: int in range(points.size() - 1):
		if not motion_clear(space, points[index], points[index + 1]):
			return false
	return FloorProbe.has_floor_at(space, points[points.size() - 1])
