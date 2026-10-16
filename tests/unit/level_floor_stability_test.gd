extends GdUnitTestSuite

const PHYSICS_STEP := 1.0 / 60.0
const HOLD_SECONDS := 1.0


func test_player_spawn_stays_on_floor() -> void:
	var runner := scene_runner("res://scenes/levels/test_room.tscn")
	var player := runner.scene().get_node("Player") as PlayerController
	var spawn := runner.scene().get_node("PlayerSpawn") as Marker3D
	player.global_position = spawn.global_position
	await _hold_on_floor(runner, player)


func test_puzzle_entry_stays_on_floor() -> void:
	var runner := scene_runner("res://scenes/levels/test_room.tscn")
	var player := runner.scene().get_node("Player") as PlayerController
	var entry := runner.scene().get_node("PuzzleEntrySpawn") as Marker3D
	player.global_position = entry.global_position
	await _hold_on_floor(runner, player)


func _hold_on_floor(runner: GdUnitSceneRunner, player: PlayerController) -> void:
	var steps := int(HOLD_SECONDS / PHYSICS_STEP)
	var space := player.get_world_3d().direct_space_state
	for _i: int in range(steps):
		await runner.simulate_frames(1)
		assert_bool(FloorProbe.has_floor_at(space, player.global_position)).is_true()
		assert_float(player.global_position.y).is_greater(-2.0)
