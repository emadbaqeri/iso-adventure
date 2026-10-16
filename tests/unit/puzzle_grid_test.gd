extends GdUnitTestSuite


func test_can_move_into_free_cell() -> void:
	var blocked: Dictionary = {}
	var occupied: Dictionary = {Vector2i(0, 0): null}
	assert_bool(
		PuzzleGrid.can_move_from(Vector2i(0, 0), Vector2i(1, 0), blocked, occupied)
	).is_true()


func test_cannot_move_into_blocked_cell() -> void:
	var blocked: Dictionary = {Vector2i(1, 0): true}
	var occupied: Dictionary = {Vector2i(0, 0): null}
	assert_bool(
		PuzzleGrid.can_move_from(Vector2i(0, 0), Vector2i(1, 0), blocked, occupied)
	).is_false()


func test_cannot_move_into_occupied_cell() -> void:
	var blocked: Dictionary = {}
	var occupied: Dictionary = {Vector2i(0, 0): null, Vector2i(1, 0): null}
	assert_bool(
		PuzzleGrid.can_move_from(Vector2i(0, 0), Vector2i(1, 0), blocked, occupied)
	).is_false()


func test_snap_world_aligns_to_tile_grid() -> void:
	var snapped := PuzzleGrid.snap_world(Vector3(5.1, 0.0, -3.9))
	assert_vector(snapped).is_equal(Vector3(6.0, 0.0, -4.0))
