extends GdUnitTestSuite

const PLAYER_SCENE := "res://scenes/player/player.tscn"


func test_trail_uses_material_override_not_surface_zero() -> void:
	var runner := scene_runner(PLAYER_SCENE)
	await _wait(runner, 4)
	var trail := runner.scene().get_node("SwordRig/SwingPivot/Trail") as MeshInstance3D
	assert_object(trail.material_override).is_not_null()
	_begin_combo(runner.scene())
	_advance_combo(runner.scene(), 0.12)
	await _wait(runner, 2)
	assert_object(trail.material_override).is_not_null()


func test_blade_tip_points_up_at_rest() -> void:
	var runner := scene_runner(PLAYER_SCENE)
	await _wait(runner, 8)
	var rig := runner.scene().get_node("SwordRig") as PlayerSwordRig
	assert_float(rig.get_blade_tip_up_alignment()).is_greater_equal(0.75)


func test_iaido_phase_durations_are_fast() -> void:
	var runner := scene_runner(PLAYER_SCENE)
	await _wait(runner, 2)
	var rig := runner.scene().get_node("SwordRig") as PlayerSwordRig
	assert_float(rig.wind_up_duration).is_less_equal(0.03)
	assert_float(rig.strike_duration).is_less_equal(0.09)
	assert_float(rig.recovery_duration).is_greater_equal(0.18)


func test_attack_snaps_to_strike_start_on_press() -> void:
	var runner := scene_runner(PLAYER_SCENE)
	await _wait(runner, 4)
	var player := runner.scene() as PlayerController
	var rig := player.get_node("SwordRig") as PlayerSwordRig
	var pivot := rig.get_node("SwingPivot") as Node3D
	var before := rig.global_position
	_begin_combo(player)
	assert_float(rig.global_position.distance_to(before)).is_greater(0.05)
	assert_float(absf(pivot.rotation.y - deg_to_rad(-70.0))).is_less(0.2)


func test_strike_phase_starts_right_after_wind_up() -> void:
	var runner := scene_runner(PLAYER_SCENE)
	await _wait(runner, 2)
	var rig := runner.scene().get_node("SwordRig") as PlayerSwordRig
	_begin_combo(runner.scene())
	_advance_combo(runner.scene(), rig.wind_up_duration)
	assert_bool(rig.is_strike_phase()).is_true()


func test_late_recovery_accepts_attack_buffer() -> void:
	var runner := scene_runner(PLAYER_SCENE)
	await _wait(runner, 2)
	var player := runner.scene() as PlayerController
	var rig := player.get_node("SwordRig") as PlayerSwordRig
	_begin_combo(player)
	var pre_strike := rig.wind_up_duration + rig.strike_duration
	_advance_combo(player, pre_strike + rig.recovery_duration * 0.7)
	assert_bool(rig.accepts_attack_buffer()).is_true()
	assert_bool(player.try_buffer_attack_input()).is_true()


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
	var elapsed := 0.0
	var step := 1.0 / 60.0
	while elapsed + 0.0001 < seconds:
		rig.advance_attack_combo(step)
		elapsed += step


func _wait(runner: GdUnitSceneRunner, steps: int) -> void:
	for _i: int in range(steps):
		await runner.await_input_processed()
