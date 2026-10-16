extends GdUnitTestSuite

const SLIME_SCENE := "res://scenes/enemies/slime.tscn"


func test_starts_in_idle() -> void:
	var runner := scene_runner(SLIME_SCENE)
	await _wait_physics(runner, 2)
	var sm := runner.scene().get_node("SlimeStateMachine") as SlimeStateMachine
	assert_str(String(sm.get_current_state_name())).is_equal("Idle")


func test_idle_to_chase_when_player_near() -> void:
	var runner := scene_runner(SLIME_SCENE)
	var slime := runner.scene() as SlimeEnemy
	var player: CharacterBody3D = CharacterBody3D.new()
	auto_free(player)
	player.add_to_group("player")
	runner.scene().get_parent().add_child(player)
	player.global_position = slime.global_position + Vector3(6, 0, 0)
	slime.state_machine.player = player
	await _wait_physics(runner, 4)
	var state_name := String(slime.state_machine.get_current_state_name())
	assert_str(state_name).is_equal("Chase")


func test_chase_to_attack_in_range() -> void:
	var runner := scene_runner(SLIME_SCENE)
	var slime := runner.scene() as SlimeEnemy
	slime.state_machine.change_state(&"Chase")
	var player: CharacterBody3D = CharacterBody3D.new()
	auto_free(player)
	player.add_to_group("player")
	runner.scene().get_parent().add_child(player)
	player.global_position = slime.global_position + Vector3(1.5, 0, 0)
	slime.state_machine.player = player
	await _wait_physics(runner, 4)
	assert_str(String(slime.state_machine.get_current_state_name())).is_equal("Attack")


func test_damage_transitions_to_hurt() -> void:
	var runner := scene_runner(SLIME_SCENE)
	var slime := runner.scene() as SlimeEnemy
	await _wait_physics(runner, 2)
	slime.health.apply_damage(1)
	await _wait_physics(runner, 2)
	assert_str(String(slime.state_machine.get_current_state_name())).is_equal("Hurt")


func test_three_hits_leads_to_dead() -> void:
	var runner := scene_runner(SLIME_SCENE)
	var slime := runner.scene() as SlimeEnemy
	slime.health.invincibility_duration = 0.0
	await _wait_physics(runner, 2)
	for _i: int in range(3):
		slime.health.apply_damage(1)
		await _wait_physics(runner, 2)
	assert_str(String(slime.state_machine.get_current_state_name())).is_equal("Dead")


func _wait_physics(runner: GdUnitSceneRunner, steps: int) -> void:
	for _i: int in range(steps):
		await runner.await_input_processed()
