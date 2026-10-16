class_name IsoMoveMath
extends RefCounted

## Camera-relative ground movement using the same euler as IsoCameraRig (~pitch, yaw).


static func rig_basis(pitch_degrees: float, yaw_degrees: float) -> Basis:
	return Basis.from_euler(Vector3(deg_to_rad(-pitch_degrees), deg_to_rad(yaw_degrees), 0.0))


static func camera_ground_forward(pitch_degrees: float, yaw_degrees: float) -> Vector3:
	var basis := rig_basis(pitch_degrees, yaw_degrees)
	var forward := Vector3(-basis.z.x, 0.0, -basis.z.z)
	if forward.length_squared() < 0.0001:
		return Vector3(0.0, 0.0, 1.0)
	return forward.normalized()


static func camera_ground_right(pitch_degrees: float, yaw_degrees: float) -> Vector3:
	var basis := rig_basis(pitch_degrees, yaw_degrees)
	var right := Vector3(basis.x.x, 0.0, basis.x.z)
	if right.length_squared() < 0.0001:
		return Vector3(1.0, 0.0, 0.0)
	return right.normalized()


static func input_to_world_direction(
	input: Vector2, pitch_degrees: float, yaw_degrees: float
) -> Vector3:
	if input.length_squared() < 0.0001:
		return Vector3.ZERO
	var right := camera_ground_right(pitch_degrees, yaw_degrees)
	var forward := camera_ground_forward(pitch_degrees, yaw_degrees)
	# Positive move_up (input.y) walks toward screen top = opposite of camera look on XZ.
	var direction := right * input.x - forward * input.y
	return direction.normalized()
