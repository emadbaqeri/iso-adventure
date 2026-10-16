extends GdUnitTestSuite


func test_should_door_open_requires_all_switches() -> void:
	assert_bool(PuzzleController.should_door_open([true, true])).is_true()
	assert_bool(PuzzleController.should_door_open([true, false])).is_false()
	assert_bool(PuzzleController.should_door_open([false, false])).is_false()
	assert_bool(PuzzleController.should_door_open([])).is_false()


func test_switch_release_closes_door() -> void:
	var runner := scene_runner("res://tests/fixtures/puzzle_door_harness.tscn")
	await _wait(runner, 4)
	var controller := runner.scene().get_node("PuzzleController") as PuzzleController
	var door := runner.scene().get_node("Door") as Door
	var switch_a := runner.scene().get_node("SwitchA") as PressureSwitch
	var switch_b := runner.scene().get_node("SwitchB") as PressureSwitch
	switch_a._update_pressed(true)
	switch_b._update_pressed(true)
	await _wait(runner, 6)
	assert_bool(door.is_open()).is_true()
	switch_a._update_pressed(false)
	await _wait(runner, 6)
	assert_bool(door.is_open()).is_false()


func _wait(runner: GdUnitSceneRunner, steps: int) -> void:
	for _i: int in range(steps):
		await runner.await_input_processed()
