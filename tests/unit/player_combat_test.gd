extends GdUnitTestSuite

const PLAYER_SCENE := "res://scenes/player/player.tscn"


func test_attack_input_from_idle() -> void:
	var runner := scene_runner(PLAYER_SCENE)
	await _wait_physics(runner, 2)
	runner.simulate_action_press("attack")
	await _wait_physics(runner, 2)
	var sm := runner.scene().get_node("PlayerStateMachine") as PlayerStateMachine
	assert_str(String(sm.get_current_state_name())).is_equal("Attack")


func test_player_health_iframes_after_hit() -> void:
	var runner := scene_runner(PLAYER_SCENE)
	var player := runner.scene() as PlayerController
	var health := player.get_node("HealthComponent") as HealthComponent
	health.invincibility_duration = 0.4
	await _wait_physics(runner, 2)
	assert_bool(health.apply_damage(1)).is_true()
	assert_bool(health.invincible).is_true()
	assert_bool(health.apply_damage(1)).is_false()
	assert_int(health.current_health).is_equal(4)


func _wait_physics(runner: GdUnitSceneRunner, steps: int) -> void:
	for _i: int in range(steps):
		await runner.await_input_processed()
