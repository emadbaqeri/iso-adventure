class_name PlayerFacingMath
extends RefCounted

## Yaw for CharacterBody3D (-Z forward) and rotation that handles 180° reversals.


static func direction_to_yaw(direction: Vector3) -> float:
	var flat := Vector3(direction.x, 0.0, direction.z)
	if flat.length_squared() < 0.0001:
		return 0.0
	# Godot models face -Z; atan2(x, z) alone is opposite to move direction.
	return wrapf(atan2(flat.x, flat.z) + PI, -PI, PI)


static func rotate_yaw_toward(
	current_yaw: float, target_yaw: float, delta: float, turn_speed: float
) -> float:
	var diff := angle_difference(current_yaw, target_yaw)
	if is_zero_approx(diff):
		return target_yaw
	var weight := minf(1.0, turn_speed * delta)
	# lerp_angle can stall when |diff| ≈ π; step explicitly along the shortest arc.
	if absf(diff) >= PI - 0.001:
		var step := weight * PI
		if step >= absf(diff):
			return target_yaw
		return current_yaw + signf(diff) * step
	return lerp_angle(current_yaw, target_yaw, weight)
