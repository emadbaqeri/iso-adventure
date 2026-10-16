class_name PlayerHealthHud
extends CanvasLayer

@export var player_path: NodePath

var _health: HealthComponent
var _label: Label


func _ready() -> void:
	_label = get_node_or_null("MarginContainer/Label") as Label
	_resolve_player()
	if _health != null:
		_health.damaged.connect(_on_damaged)
		_health.died.connect(_on_died)
		_refresh()


func _resolve_player() -> void:
	if player_path == NodePath():
		return
	var player := get_node_or_null(player_path)
	if player == null:
		return
	_health = player.get_node_or_null("HealthComponent") as HealthComponent


func _on_damaged(_amount: int, _remaining: int) -> void:
	_refresh()


func _on_died() -> void:
	_refresh()


func _refresh() -> void:
	if _label == null or _health == null:
		return
	var hearts := ""
	for i: int in range(_health.max_health):
		hearts += "♥ " if i < _health.current_health else "♡ "
	_label.text = "HP %s" % hearts.strip_edges()
