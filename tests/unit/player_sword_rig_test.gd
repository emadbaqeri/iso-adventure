extends GdUnitTestSuite

const PLAYER_SCENE := "res://scenes/player/player.tscn"


func test_trail_uses_material_override_not_surface_zero() -> void:
	var runner := scene_runner(PLAYER_SCENE)
	await _wait(runner, 4)
	var trail := runner.scene().get_node("SwordRig/SwingPivot/Trail") as MeshInstance3D
	assert_object(trail.material_override).is_not_null()
	_request_attack(runner.scene())
	await _wait(runner, 2)
	assert_object(trail.material_override).is_not_null()


func test_blade_tip_points_up_at_rest() -> void:
	var runner := scene_runner(PLAYER_SCENE)
	await _wait(runner, 8)
	var rig := runner.scene().get_node("SwordRig") as PlayerSwordRig
	assert_float(rig.get_blade_tip_up_alignment()).is_greater_equal(0.75)


func test_strike_active_first_frame_after_attack_request() -> void:
	var runner := scene_runner(PLAYER_SCENE)
	await _wait(runner, 4)
	var player := runner.scene() as PlayerController
	var rig := player.get_node("SwordRig") as PlayerSwordRig
	var yaw_before := rig.get_swing_pivot_yaw()
	assert_bool(player.request_attack()).is_true()
	assert_bool(rig.is_strike_phase()).is_true()
	assert_float(absf(rig.get_swing_pivot_yaw() - yaw_before)).is_greater(0.001)


func test_iaido_has_no_wind_up_hold() -> void:
	var runner := scene_runner(PLAYER_SCENE)
	await _wait(runner, 2)
	var rig := runner.scene().get_node("SwordRig") as PlayerSwordRig
	assert_float(rig.wind_up_duration).is_less_equal(0.001)
	assert_float(rig.strike_duration).is_less_equal(0.09)


func test_can_attack_while_sword_spring_returning() -> void:
	var runner := scene_runner(PLAYER_SCENE)
	await _wait(runner, 2)
	var player := runner.scene() as PlayerController
	var rig := player.get_node("SwordRig") as PlayerSwordRig
	rig.begin_attack_combo(player.get_facing_yaw())
	_advance_combo(player, rig.get_attack_total_duration() + 0.01)
	assert_bool(rig.is_combo_active()).is_false()
	assert_bool(rig.can_accept_attack_input()).is_true()
	assert_bool(player.can_attack()).is_true()


func test_recovery_press_restarts_strike_immediately() -> void:
	var runner := scene_runner(PLAYER_SCENE)
	await _wait(runner, 2)
	var player := runner.scene() as PlayerController
	var rig := player.get_node("SwordRig") as PlayerSwordRig
	rig.begin_attack_combo(player.get_facing_yaw())
	_advance_combo(player, rig.wind_up_duration + rig.strike_duration + 0.02)
	assert_bool(rig.is_in_recovery()).is_true()
	assert_bool(player.try_interrupt_recovery_attack()).is_true()
	assert_bool(rig.is_strike_phase()).is_true()


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


func _request_attack(player_root: Node) -> void:
	var player := player_root as PlayerController
	player.request_attack()


func _advance_combo(player_root: Node, seconds: float) -> void:
	var rig := player_root.get_node("SwordRig") as PlayerSwordRig
	var elapsed := 0.0
	var step := rig.get_default_physics_step()
	while elapsed + 0.0001 < seconds:
		rig.advance_attack_combo(step)
		elapsed += step


func _wait(runner: GdUnitSceneRunner, steps: int) -> void:
	for _i: int in range(steps):
		await runner.await_input_processed()
