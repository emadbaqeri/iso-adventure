class_name PlayerMovementInput
extends RefCounted

## Shared deadzone for keyboard + gamepad move axes (matches InputMap).
const MOVE_DEADZONE := 0.25


static func read_move_vector() -> Vector2:
	var raw := Input.get_vector(
		"move_left", "move_right", "move_up", "move_down", MOVE_DEADZONE
	)
	if raw.length_squared() < MOVE_DEADZONE * MOVE_DEADZONE:
		return Vector2.ZERO
	return raw


static func has_move_input() -> bool:
	return read_move_vector().length_squared() > 0.0
