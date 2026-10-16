class_name RoomProgressHud
extends CanvasLayer

@export var slime_group: StringName = &"enemy_slime"

var _slimes: Array[SlimeEnemy] = []
var _total: int = 0
var _count_label: Label
var _cleared_label: Label


func _ready() -> void:
	_count_label = get_node_or_null("MarginContainer/VBox/SlimeCountLabel") as Label
	_cleared_label = get_node_or_null("MarginContainer/VBox/ClearedLabel") as Label
	if _cleared_label != null:
		_cleared_label.visible = false
	call_deferred("_bind_slimes")


func _bind_slimes() -> void:
	_slimes.clear()
	for node: Node in get_tree().get_nodes_in_group(slime_group):
		var slime := node as SlimeEnemy
		if slime == null:
			continue
		_slimes.append(slime)
		if not slime.health.died.is_connected(_on_slime_died):
			slime.health.died.connect(_on_slime_died)
	_total = _slimes.size()
	_refresh()


func _on_slime_died() -> void:
	_refresh()


func _alive_count() -> int:
	var alive := 0
	for slime: SlimeEnemy in _slimes:
		if slime != null and is_instance_valid(slime) and slime.health.is_alive():
			alive += 1
	return alive


func _refresh() -> void:
	if _count_label == null:
		return
	var alive := _alive_count()
	_count_label.text = "Slimes: %d/%d" % [alive, _total]
	if _cleared_label != null:
		_cleared_label.visible = _total > 0 and alive <= 0
