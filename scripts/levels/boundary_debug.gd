extends Node

signal visibility_changed(is_visible: bool)

var _visible: bool = false


func is_visible() -> bool:
	return _visible


func _ready() -> void:
	visibility_changed.connect(_on_visibility_changed)
	call_deferred("_on_visibility_changed", _visible)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_boundary_debug"):
		_visible = not _visible
		visibility_changed.emit(_visible)


func _on_visibility_changed(should_show: bool) -> void:
	for node: Node in get_tree().get_nodes_in_group("level_boundary"):
		if node is LevelBoundarySegment:
			(node as LevelBoundarySegment).set_debug_visible(should_show)
