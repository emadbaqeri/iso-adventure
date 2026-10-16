extends GdUnitTestSuite

const PITCH := 35.0
const YAW := 45.0
const FOLLOW_OFFSET := Vector3(7.0, 9.0, 7.0)


func test_zero_input_returns_zero() -> void:
	var dir := IsoMoveMath.input_to_world_direction(Vector2.ZERO, PITCH, YAW)
	assert_vector(dir).is_equal(Vector3.ZERO)


func test_move_up_is_screen_up_toward_camera_on_ground() -> void:
	var to_camera := Vector3(FOLLOW_OFFSET.x, 0.0, FOLLOW_OFFSET.z).normalized()
	var dir := IsoMoveMath.input_to_world_direction(Vector2(0.0, 1.0), PITCH, YAW)
	assert_float(dir.dot(to_camera)).is_greater(0.85)
	assert_float(dir.y).is_equal_approx(0.0, 0.0001)


func test_move_down_walks_away_from_camera_on_ground() -> void:
	var to_camera := Vector3(FOLLOW_OFFSET.x, 0.0, FOLLOW_OFFSET.z).normalized()
	var dir := IsoMoveMath.input_to_world_direction(Vector2(0.0, -1.0), PITCH, YAW)
	assert_float(dir.dot(to_camera)).is_less(-0.85)


func test_move_right_is_perpendicular_to_screen_up() -> void:
	var up := IsoMoveMath.input_to_world_direction(Vector2(0.0, 1.0), PITCH, YAW)
	var right := IsoMoveMath.input_to_world_direction(Vector2(1.0, 0.0), PITCH, YAW)
	assert_float(absf(up.dot(right))).is_less(0.05)
	assert_float(right.length()).is_equal_approx(1.0, 0.0001)


func test_move_left_opposes_move_right() -> void:
	var right := IsoMoveMath.input_to_world_direction(Vector2(1.0, 0.0), PITCH, YAW)
	var left := IsoMoveMath.input_to_world_direction(Vector2(-1.0, 0.0), PITCH, YAW)
	assert_float(left.dot(right)).is_equal_approx(-1.0, 0.0001)


func test_diagonal_up_right_is_normalized() -> void:
	var dir := IsoMoveMath.input_to_world_direction(Vector2(1.0, 1.0), PITCH, YAW)
	assert_float(dir.length()).is_equal_approx(1.0, 0.0001)


func test_move_up_opposes_camera_ground_forward() -> void:
	var forward := IsoMoveMath.camera_ground_forward(PITCH, YAW)
	var from_input := IsoMoveMath.input_to_world_direction(Vector2(0.0, 1.0), PITCH, YAW)
	assert_vector(from_input).is_equal_approx(-forward, Vector3(0.0001, 0.0001, 0.0001))
