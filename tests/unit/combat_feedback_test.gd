extends GdUnitTestSuite


func test_slime_health_billboard_hidden_until_damaged() -> void:
	var runner := scene_runner("res://scenes/enemies/slime.tscn")
	await _wait(runner, 2)
	var slime := runner.scene() as SlimeEnemy
	var billboard := slime.get_node("HealthBillboard") as SlimeHealthBillboard
	assert_bool(billboard.visible).is_false()
	slime.health.apply_damage(1)
	await _wait(runner, 2)
	assert_bool(billboard.visible).is_true()


func test_room_progress_shows_cleared_when_slime_dies() -> void:
	var runner := scene_runner("res://tests/fixtures/room_progress_harness.tscn")
	await _wait(runner, 6)
	var hud := runner.scene().get_node("RoomProgressHud") as RoomProgressHud
	var slime := runner.scene().get_node("Slime") as SlimeEnemy
	var cleared := hud.get_node("MarginContainer/VBox/ClearedLabel") as Label
	assert_bool(cleared.visible).is_false()
	slime.health.invincibility_duration = 0.0
	for _i: int in range(3):
		slime.health.apply_damage(1)
		await _wait(runner, 2)
	await _wait(runner, 4)
	assert_bool(cleared.visible).is_true()


func _wait(runner: GdUnitSceneRunner, steps: int) -> void:
	for _i: int in range(steps):
		await runner.await_input_processed()
