extends GdUnitTestSuite

const PLAYER_SCENE := "res://scenes/player/player.tscn"


func test_starts_in_idle() -> void:
	var runner := scene_runner(PLAYER_SCENE)
	await _wait_physics(runner, 2)
	var sm := runner.scene().get_node("PlayerStateMachine") as PlayerStateMachine
	assert_str(String(sm.get_current_state_name())).is_equal("Idle")


func test_idle_to_move_on_input() -> void:
	var runner := scene_runner(PLAYER_SCENE)
	await _wait_physics(runner, 2)
	runner.simulate_action_press("move_up")
	await _wait_physics(runner, 8)
	var sm := runner.scene().get_node("PlayerStateMachine") as PlayerStateMachine
	assert_str(String(sm.get_current_state_name())).is_equal("Move")
	runner.simulate_action_release("move_up")
	await _wait_physics(runner, 8)
	assert_str(String(sm.get_current_state_name())).is_equal("Idle")


func test_state_changed_signal() -> void:
	var runner := scene_runner(PLAYER_SCENE)
	await _wait_physics(runner, 2)
	var sm := runner.scene().get_node("PlayerStateMachine") as PlayerStateMachine
	monitor_signals(sm, false)
	runner.simulate_action_press("move_right")
	await _wait_physics(runner, 8)
	await assert_signal(sm).is_emitted("state_changed", &"Idle", &"Move")
	runner.simulate_action_release("move_right")
	await _wait_physics(runner, 8)
	await assert_signal(sm).is_emitted("state_changed", &"Move", &"Idle")


func test_manual_change_state_emits_signal() -> void:
	var runner := scene_runner(PLAYER_SCENE)
	var sm := runner.scene().get_node("PlayerStateMachine") as PlayerStateMachine
	monitor_signals(sm, false)
	sm.change_state(&"Move")
	await assert_signal(sm).is_emitted("state_changed", &"Idle", &"Move")
	sm.change_state(&"Idle")
	await assert_signal(sm).is_emitted("state_changed", &"Move", &"Idle")


func _wait_physics(runner: GdUnitSceneRunner, steps: int) -> void:
	for _i: int in range(steps):
		await runner.await_input_processed()
