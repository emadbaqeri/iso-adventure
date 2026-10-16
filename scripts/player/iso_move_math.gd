class_name IsoMoveMath
extends RefCounted

## Camera-relative ground movement for fixed isometric yaw (matches IsoCameraRig).


static func input_to_world_direction(input: Vector2, iso_yaw_degrees: float) -> Vector3:
	if input.length_squared() < 0.0001:
		return Vector3.ZERO
	var yaw := deg_to_rad(iso_yaw_degrees)
	var x := input.x
	var y := input.y
	var direction := Vector3(
		x * cos(yaw) - y * sin(yaw),
		0.0,
		-x * sin(yaw) - y * cos(yaw)
	)
	return direction.normalized()
