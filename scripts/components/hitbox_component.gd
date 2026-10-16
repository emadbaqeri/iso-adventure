class_name HitboxComponent
extends Area3D

@export var damage: int = 1

## Ignores hurtboxes owned by this node or its ancestors.
var owner_root: Node

var _struck: Dictionary = {}


func _ready() -> void:
	collision_layer = CombatLayers.HITBOX
	collision_mask = CombatLayers.HURTBOX
	monitoring = false
	area_entered.connect(_on_area_entered)
	if owner_root == null:
		owner_root = _find_owner_root()


func activate() -> void:
	_struck.clear()
	monitoring = true


func deactivate() -> void:
	monitoring = false


func _on_area_entered(area: Area3D) -> void:
	var hurtbox := area as HurtboxComponent
	if hurtbox == null:
		return
	if _is_same_combatant(hurtbox):
		return
	var hurtbox_id: int = hurtbox.get_instance_id()
	if _struck.has(hurtbox_id):
		return
	_struck[hurtbox_id] = true
	hurtbox.receive_hit(damage, owner_root)


func _is_same_combatant(hurtbox: HurtboxComponent) -> bool:
	if owner_root == null:
		return false
	return owner_root.is_ancestor_of(hurtbox)


func _find_owner_root() -> Node:
	var node: Node = get_parent()
	while node != null:
		if node is CharacterBody3D:
			return node
		node = node.get_parent()
	return get_parent()
