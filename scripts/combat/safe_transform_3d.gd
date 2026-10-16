class_name SafeTransform3D
extends Object

## Minimum uniform scale before hiding the node (never set scale to 0).
const MIN_UNIFORM_SCALE := 0.05


static func clamp_uniform_scale(scale_factor: float) -> float:
	return maxf(scale_factor, MIN_UNIFORM_SCALE)


static func apply_uniform_scale(node: Node3D, scale_factor: float) -> void:
	node.scale = Vector3.ONE * clamp_uniform_scale(scale_factor)


static func look_flat_y(node: Node3D, world_direction: Vector3, up: Vector3 = Vector3.UP) -> void:
	var dir := world_direction
	dir.y = 0.0
	if dir.length_squared() < 1e-8:
		return
	dir = dir.normalized()
	var up_dir := up.normalized()
	if absf(dir.dot(up_dir)) > 0.999:
		return
	var target := node.global_position + dir
	if target.distance_squared_to(node.global_position) < 1e-10:
		return
	node.look_at(target, up_dir)
