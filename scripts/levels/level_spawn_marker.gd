class_name LevelSpawnMarker
extends Marker3D

@export var marker_id: StringName = &"default"


func _ready() -> void:
	add_to_group("level_spawn")
	if marker_id == &"default":
		add_to_group("level_spawn_default")
