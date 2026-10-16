extends Node3D

@export var mood_controller_path: NodePath = ^"MoodController"


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(&"cycle_mood"):
		return
	var mood := get_node_or_null(mood_controller_path) as RenderMoodController
	if mood != null:
		mood.cycle_mood()
