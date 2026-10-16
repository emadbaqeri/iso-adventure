extends GdUnitTestSuite

const PLAYER_SCENE := "res://scenes/player/player.tscn"


func test_trail_uses_material_override_not_surface_zero() -> void:
	var runner := scene_runner(PLAYER_SCENE)
	await _wait(runner, 4)
	var trail := runner.scene().get_node("SwordRig/SwingPivot/Trail") as MeshInstance3D
	assert_object(trail.material_override).is_not_null()
	_begin_combo(runner.scene())
	_advance_combo(runner.scene(), 0.18)
	await _wait(runner, 2)
	assert_object(trail.material_override).is_not_null()


func test_blade_tip_points_up_at_rest() -> void:
	var runner := scene_runner(PLAYER_SCENE)
	await _wait(runner, 8)
	var rig := runner.scene().get_node("SwordRig") as PlayerSwordRig
	assert_float(rig.get_blade_tip_up_alignment()).is_greater_equal(0.75)


func test_attack_phase_durations_match_exports() -> void:
	var runner := scene_runner(PLAYER_SCENE)
	await _wait(runner, 2)
	var rig := runner.scene().get_node("SwordRig") as PlayerSwordRig
	var total := rig.get_attack_total_duration()
	assert_float(total).is_equal(rig.wind_up_duration + rig.strike_duration + rig.recovery_duration)
	_begin_combo(runner.scene())
	assert_str(String(rig.get_attack_phase_name())).is_equal("wind_up")
	_advance_combo(runner.scene(), rig.wind_up_duration * 0.5)
	assert_str(String(rig.get_attack_phase_name())).is_equal("wind_up")
	_advance_combo(runner.scene(), rig.wind_up_duration)
	assert_str(String(rig.get_attack_phase_name())).is_equal("strike")
	_advance_combo(runner.scene(), rig.strike_duration)
	assert_str(String(rig.get_attack_phase_name())).is_equal("recovery")


func test_sword_floats_top_level_with_spring_exports() -> void:
	var runner := scene_runner(PLAYER_SCENE)
	await _wait(runner, 2)
	var rig := runner.scene().get_node("SwordRig") as PlayerSwordRig
	assert_bool(rig.is_top_level_floater()).is_true()
	assert_float(rig.spring_stiffness).is_greater(0.0)
	assert_float(rig.bob_amplitude).is_greater_equal(0.04)


func test_sword_rig_has_wide_swing_arc() -> void:
	var runner := scene_runner(PLAYER_SCENE)
	await _wait(runner, 2)
	var rig := runner.scene().get_node("SwordRig") as PlayerSwordRig
	assert_float(rig.swing_arc_degrees()).is_greater_equal(120.0)


func _begin_combo(player_root: Node) -> void:
	var rig := player_root.get_node("SwordRig") as PlayerSwordRig
	var player := player_root as PlayerController
	rig.begin_attack_combo(player.get_facing_yaw())


func _advance_combo(player_root: Node, seconds: float) -> void:
	var rig := player_root.get_node("SwordRig") as PlayerSwordRig
	var steps := int(seconds / (1.0 / 60.0))
	for _i: int in range(maxi(steps, 1)):
		rig.advance_attack_combo(1.0 / 60.0)


func _wait(runner: GdUnitSceneRunner, steps: int) -> void:
	for _i: int in range(steps):
		await runner.await_input_processed()
