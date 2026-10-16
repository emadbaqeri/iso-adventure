extends GdUnitTestSuite


func test_units_per_pixel_matches_ortho_height() -> void:
	var upp := PixelCameraMath.units_per_pixel(14.0, 360)
	assert_float(upp).is_equal_approx(14.0 * 2.0 / 360.0, 0.0001)


func test_integer_upscale_picks_largest_integer_fit() -> void:
	assert_int(PixelCameraMath.integer_upscale_factor(Vector2i(1280, 720), Vector2i(640, 360))).is_equal(2)
	assert_int(PixelCameraMath.integer_upscale_factor(Vector2i(800, 450), Vector2i(640, 360))).is_equal(1)


func test_snap_camera_origin_snaps_xy_in_camera_space() -> void:
	var basis := Basis.IDENTITY
	var origin := Vector3(0.037, 0.019, 10.0)
	var result: Dictionary = PixelCameraMath.snap_camera_origin(basis, origin, 14.0, 360)
	var snapped: Vector3 = result["snapped_world"]
	assert_float(snapped.x).is_equal(0.0)
	assert_float(snapped.y).is_equal(0.0)
	assert_float(snapped.z).is_equal(10.0)
	var sub: Vector2 = result["sub_pixel"]
	var upp := PixelCameraMath.units_per_pixel(14.0, 360)
	assert_float(sub.x).is_equal_approx(0.037 / upp, 0.0001)
	assert_float(sub.y).is_equal_approx(0.019 / upp, 0.0001)


func test_remainder_world_delta_uses_camera_right_up_axes() -> void:
	var basis := Basis.IDENTITY
	var upp := 0.1
	var delta := PixelCameraMath.remainder_world_delta(basis, Vector2(0.5, 0.25), upp)
	assert_that(delta).is_equal(Vector3(0.05, 0.025, 0.0))


func test_snap_on_camera_plane_preserves_depth_axis() -> void:
	var basis := Basis(
		Vector3(0.707, 0.0, -0.707),
		Vector3(0.0, 1.0, 0.0),
		Vector3(0.707, 0.0, 0.707),
	)
	var world := Vector3(1.23, 4.56, 7.89)
	var upp := 0.2
	var result := PixelCameraMath.snap_on_camera_plane(basis, world, upp)
	var local_after: Vector3 = basis.inverse() * result["snapped_world"]
	assert_float(fmod(local_after.x, upp)).is_equal_approx(0.0, 0.0001)
	assert_float(fmod(local_after.y, upp)).is_equal_approx(0.0, 0.0001)
	assert_float(local_after.z).is_equal_approx((basis.inverse() * world).z, 0.0001)
