extends GdUnitTestSuite


func test_zero_input_returns_zero() -> void:
	var dir := IsoMoveMath.input_to_world_direction(Vector2.ZERO, 45.0)
	assert_vector(dir).is_equal(Vector3.ZERO)


func test_move_up_at_iso_yaw_45() -> void:
	var dir := IsoMoveMath.input_to_world_direction(Vector2(0.0, 1.0), 45.0)
	assert_float(dir.x).is_equal_approx(-0.7071068, 0.0001)
	assert_float(dir.y).is_equal_approx(0.0, 0.0001)
	assert_float(dir.z).is_equal_approx(-0.7071068, 0.0001)


func test_move_right_at_iso_yaw_45() -> void:
	var dir := IsoMoveMath.input_to_world_direction(Vector2(1.0, 0.0), 45.0)
	assert_float(dir.x).is_equal_approx(0.7071068, 0.0001)
	assert_float(dir.z).is_equal_approx(-0.7071068, 0.0001)


func test_diagonal_is_normalized() -> void:
	var dir := IsoMoveMath.input_to_world_direction(Vector2(1.0, 1.0), 45.0)
	assert_float(dir.length()).is_equal_approx(1.0, 0.0001)
