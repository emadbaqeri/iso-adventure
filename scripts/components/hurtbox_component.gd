class_name HurtboxComponent
extends Area3D

signal hit_received(damage: int, source: Node)

@export var health_path: NodePath

var health: HealthComponent


func _ready() -> void:
	collision_layer = CombatLayers.HURTBOX
	collision_mask = 0
	monitoring = false
	monitorable = true
	if health_path != NodePath():
		health = get_node_or_null(health_path) as HealthComponent
	if health == null:
		health = _find_health_in_parents()


func receive_hit(damage: int, source: Node) -> bool:
	if health == null:
		return false
	var applied := health.apply_damage(damage)
	if applied:
		hit_received.emit(damage, source)
	return applied


func _find_health_in_parents() -> HealthComponent:
	var node: Node = get_parent()
	while node != null:
		var found := node.get_node_or_null("HealthComponent") as HealthComponent
		if found != null:
			return found
		node = node.get_parent()
	return null
