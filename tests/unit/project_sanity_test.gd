extends GdUnitTestSuite


func test_godot_major_version_is_four() -> void:
	var version_info: Dictionary = Engine.get_version_info()
	assert_int(version_info["major"]).is_equal(4)


func test_main_scene_path_is_set() -> void:
	var main_scene: String = ProjectSettings.get_setting("application/run/main_scene")
	assert_str(main_scene).is_equal("res://scenes/main.tscn")
