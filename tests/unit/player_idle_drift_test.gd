extends GdUnitTestSuite

const IDLE_HARNESS := "res://tests/fixtures/player_idle_harness.tscn"
const IDLE_PHYSICS_STEPS := 120


func test_velocity_stays_near_zero_without_input_or_hits() -> void:
	var runner := scene_runner(IDLE_HARNESS)
	await _wait_physics(runner, 8)
	var player := runner.scene().get_node("Player") as PlayerController
	var start_xz := Vector2(player.global_position.x, player.global_position.z)
	for _i: int in range(IDLE_PHYSICS_STEPS):
		await runner.await_input_processed()
		var horizontal_speed := Vector2(player.velocity.x, player.velocity.z).length()
		assert_float(horizontal_speed).is_less_equal(0.15)
	var end_xz := Vector2(player.global_position.x, player.global_position.z)
	assert_float(start_xz.distance_to(end_xz)).is_less_equal(0.35)
	assert_bool(player.is_in_hit_knockback()).is_false()


func _wait_physics(runner: GdUnitSceneRunner, steps: int) -> void:
	for _i: int in range(steps):
		await runner.await_input_processed()
