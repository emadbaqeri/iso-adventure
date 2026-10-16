extends GdUnitTestSuite

const WARDEN_VISUAL_SCENE := "res://scenes/player/warden_visual.tscn"
const PLAYER_SCENE := "res://scenes/player/player.tscn"


func test_maps_player_states_to_animation_names() -> void:
	var runner := scene_runner(WARDEN_VISUAL_SCENE)
	var visual := runner.scene() as WardenVisual
	assert_object(visual).is_not_null()
	assert_str(String(visual.get_animation_name_for_state(&"Idle"))).is_equal("idle")
	assert_str(String(visual.get_animation_name_for_state(&"Move"))).is_equal("run")
	assert_str(String(visual.get_animation_name_for_state(&"Attack"))).is_equal("attack")


func test_player_instances_warden_visual() -> void:
	var runner := scene_runner(PLAYER_SCENE)
	await _wait_physics(runner, 2)
	var visual := runner.scene().get_node("Visual/WardenVisual") as WardenVisual
	assert_object(visual).is_not_null()
	var ap := visual.find_child("AnimationPlayer", true, false) as AnimationPlayer
	assert_object(ap).is_not_null()
	assert_array(ap.get_animation_list()).contains("idle")
	assert_array(ap.get_animation_list()).contains("run")
	assert_array(ap.get_animation_list()).contains("attack")


func _wait_physics(runner: GdUnitSceneRunner, steps: int) -> void:
	for _i: int in range(steps):
		await runner.await_input_processed()
