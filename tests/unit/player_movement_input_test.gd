extends GdUnitTestSuite


func test_deadzone_constant_is_at_least_point_two() -> void:
	assert_float(PlayerMovementInput.MOVE_DEADZONE).is_greater_equal(0.2)
