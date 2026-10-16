extends Node

## Global scene reload on reset_scene input (Backspace / gamepad Back).


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("reset_scene"):
		get_tree().call_deferred("reload_current_scene")
