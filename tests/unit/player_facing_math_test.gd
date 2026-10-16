extends GdUnitTestSuite

const PITCH := 35.0
const YAW := 45.0


func test_opposite_move_directions_yaw_differs_by_pi() -> void:
	var down := IsoMoveMath.input_to_world_direction(Vector2(0.0, -1.0), PITCH, YAW)
	var up := IsoMoveMath.input_to_world_direction(Vector2(0.0, 1.0), PITCH, YAW)
	var yaw_down := PlayerFacingMath.direction_to_yaw(down)
	var yaw_up := PlayerFacingMath.direction_to_yaw(up)
	assert_float(absf(angle_difference(yaw_down, yaw_up))).is_equal_approx(PI, 0.001)


func test_180_reversal_reaches_forward_yaw() -> void:
	var down := IsoMoveMath.input_to_world_direction(Vector2(0.0, -1.0), PITCH, YAW)
	var up := IsoMoveMath.input_to_world_direction(Vector2(0.0, 1.0), PITCH, YAW)
	var current_yaw := PlayerFacingMath.direction_to_yaw(down)
	var target_yaw := PlayerFacingMath.direction_to_yaw(up)
	for _i: int in range(40):
		current_yaw = PlayerFacingMath.rotate_yaw_toward(current_yaw, target_yaw, 1.0 / 60.0, 36.0)
	assert_float(absf(angle_difference(current_yaw, target_yaw))).is_less(0.08)


func test_rotate_yaw_toward_steps_across_pi_boundary() -> void:
	var current := PI * 0.99
	var target := -PI * 0.99
	var next := PlayerFacingMath.rotate_yaw_toward(current, target, 1.0 / 60.0, 36.0)
	assert_float(absf(angle_difference(next, current))).is_greater(0.01)
