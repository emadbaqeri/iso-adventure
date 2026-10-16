extends GdUnitTestSuite

const PLAYER_SCENE := "res://scenes/player/player.tscn"


func test_sword_rig_has_wide_swing_arc() -> void:
	var runner := scene_runner(PLAYER_SCENE)
	await _wait(runner, 2)
	var rig := runner.scene().get_node("AttackPivot/SwordRig") as PlayerSwordRig
	assert_float(rig.swing_arc_degrees()).is_greater_equal(120.0)


func test_swing_progress_moves_pivot_without_zero_scale() -> void:
	var runner := scene_runner(PLAYER_SCENE)
	await _wait(runner, 2)
	var pivot := runner.scene().get_node("AttackPivot/SwordRig/SwingPivot") as Node3D
	var start_y := pivot.rotation.y
	rig_begin(runner.scene())
	rig_set_progress(runner.scene(), 1.0)
	assert_float(absf(pivot.rotation.y - start_y)).is_greater(0.5)
	var scale := pivot.scale
	assert_float(scale.x).is_greater(0.05)
	assert_float(scale.y).is_greater(0.05)
	assert_float(scale.z).is_greater(0.05)


func rig_begin(player_root: Node) -> void:
	var rig := player_root.get_node("AttackPivot/SwordRig") as PlayerSwordRig
	rig.begin_swing()


func rig_set_progress(player_root: Node, progress: float) -> void:
	var rig := player_root.get_node("AttackPivot/SwordRig") as PlayerSwordRig
	rig.set_swing_progress(progress)


func _wait(runner: GdUnitSceneRunner, steps: int) -> void:
	for _i: int in range(steps):
		await runner.await_input_processed()
