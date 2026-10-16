extends Node

## Global melee hit impact: brief hitstop + optional camera shake.

const HITSTOP_SECONDS := 0.06

var _camera_rig: IsoCameraRig
var _hitstop_running: bool = false


func register_camera_rig(rig: IsoCameraRig) -> void:
	_camera_rig = rig


func trigger_melee_hit() -> void:
	_apply_hitstop()
	if _camera_rig != null:
		_camera_rig.apply_shake()


func _apply_hitstop() -> void:
	if _hitstop_running:
		return
	_hitstop_running = true
	Engine.time_scale = 0.0
	await get_tree().create_timer(HITSTOP_SECONDS, true, false, true).timeout
	Engine.time_scale = 1.0
	_hitstop_running = false
