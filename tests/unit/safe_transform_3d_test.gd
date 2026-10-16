extends GdUnitTestSuite


func test_clamp_uniform_scale_never_zero() -> void:
	assert_float(SafeTransform3D.clamp_uniform_scale(0.0)).is_equal(
		SafeTransform3D.MIN_UNIFORM_SCALE
	)
	assert_float(SafeTransform3D.clamp_uniform_scale(1.0)).is_equal(1.0)
