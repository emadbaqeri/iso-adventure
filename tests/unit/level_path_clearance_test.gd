extends GdUnitTestSuite


func test_spawn_to_pedestal_path_is_unblocked() -> void:
	var runner := scene_runner("res://scenes/levels/test_room.tscn")
	await _wait(runner, 4)
	var scene := runner.scene()
	var player := scene.get_node("Player") as PlayerController
	var gate := scene.get_node("PuzzleAccessGate") as PuzzleRoomAccess
	var puzzle := scene.get_node("PuzzleRoom")
	var switch_a := puzzle.get_node("Switches/SwitchA") as PressureSwitch
	var switch_b := puzzle.get_node("Switches/SwitchB") as PressureSwitch
	gate.force_open()
	switch_a._update_pressed(true)
	switch_b._update_pressed(true)
	var door := puzzle.get_node("Door") as Door
	door.set_open(true, true)
	await _wait(runner, 4)
	var points: Array[Vector3] = [
		player.global_position,
		Vector3(4.0, 0.0, -1.0),
		Vector3(9.0, 0.0, -1.0),
		Vector3(10.5, 0.0, -1.0),
		Vector3(12.0, 0.0, -2.0),
		Vector3(12.0, 0.0, 0.0),
		Vector3(12.0, 0.0, 2.0),
		puzzle.get_node("Goal").global_position,
	]
	var space := player.get_world_3d().direct_space_state
	assert_bool(PathClearanceProbe.path_is_clear(space, points)).is_true()


func _wait(runner: GdUnitSceneRunner, steps: int) -> void:
	for _i: int in range(steps):
		await runner.simulate_frames(1)
