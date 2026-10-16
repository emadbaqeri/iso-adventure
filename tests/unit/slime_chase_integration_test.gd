extends GdUnitTestSuite

const DIRECT_HARNESS := "res://tests/fixtures/chase_direct_harness.tscn"
const WALL_HARNESS := "res://tests/fixtures/chase_wall_harness.tscn"
const CHASE_PHYSICS_STEPS := 60


func test_direct_chase_decreases_distance_to_player() -> void:
	var runner := scene_runner(DIRECT_HARNESS)
	await _wait_physics(runner, 4)
	var slime := runner.scene().get_node("Slime") as SlimeEnemy
	var player := runner.scene().get_node("Player") as Node3D
	_begin_chase(slime, player)
	var start_dist := slime.distance_to_player()
	assert_float(start_dist).is_greater(4.0)
	await _wait_physics(runner, CHASE_PHYSICS_STEPS)
	var end_dist := slime.distance_to_player()
	assert_float(end_dist).is_less(start_dist - 1.5)


func test_nav_chase_around_wall_decreases_distance() -> void:
	var runner := scene_runner(WALL_HARNESS)
	await _wait_physics(runner, 12)
	var slime := runner.scene().get_node("Slime") as SlimeEnemy
	var player := runner.scene().get_node("Player") as Node3D
	_begin_chase(slime, player)
	var start_dist := slime.distance_to_player()
	assert_float(start_dist).is_greater(10.0)
	await _wait_physics(runner, CHASE_PHYSICS_STEPS)
	var end_dist := slime.distance_to_player()
	assert_float(end_dist).is_less(start_dist - 2.0)
	var chase_dir := slime.get_chase_direction()
	var to_player := (player.global_position - slime.global_position).normalized()
	assert_float(chase_dir.dot(to_player)).is_greater_equal(0.0)


func _begin_chase(slime: SlimeEnemy, player: Node3D) -> void:
	slime.state_machine.player = player
	slime.state_machine.change_state(&"Chase")
	slime.navigation_agent.target_position = player.global_position


func _wait_physics(runner: GdUnitSceneRunner, steps: int) -> void:
	for _i: int in range(steps):
		await runner.await_input_processed()
