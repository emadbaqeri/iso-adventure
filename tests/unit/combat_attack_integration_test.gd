extends GdUnitTestSuite

const HARNESS_SCENE := "res://tests/fixtures/combat_attack_harness.tscn"


func test_player_attack_reduces_slime_health() -> void:
	var runner := scene_runner(HARNESS_SCENE)
	await _wait_physics(runner, 4)
	var player := runner.scene().get_node("Player") as PlayerController
	var slime := runner.scene().get_node("Slime") as SlimeEnemy
	var health := slime.get_node("HealthComponent") as HealthComponent
	slime.state_machine.player = player
	player.snap_to_facing(Vector3.FORWARD)
	assert_int(health.current_health).is_equal(3)
	runner.simulate_action_press("attack")
	await _wait_physics(runner, 24)
	runner.simulate_action_release("attack")
	await _wait_physics(runner, 16)
	assert_int(health.current_health).is_less(3)


func _wait_physics(runner: GdUnitSceneRunner, steps: int) -> void:
	for _i: int in range(steps):
		await runner.await_input_processed()
