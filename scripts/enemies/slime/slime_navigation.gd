class_name SlimeNavigation
extends RefCounted

## Shared chase steering: sync agent, follow path toward player, never run away.


static func get_chase_direction(slime: SlimeEnemy, agent: NavigationAgent3D) -> Vector3:
	var player := slime.get_player()
	if player == null:
		return Vector3.ZERO

	var to_player := _flat_normalized(player.global_position - slime.global_position)
	if to_player.length_squared() < 1e-8:
		return Vector3.ZERO

	agent.target_position = player.global_position

	if not _is_map_ready(agent):
		return to_player

	if agent.is_navigation_finished():
		return to_player

	var next_pos := agent.get_next_path_position()
	var to_next := next_pos - slime.global_position
	to_next.y = 0.0
	if to_next.length_squared() < 1e-6:
		return to_player

	var nav_dir := to_next.normalized()
	# Stale / wrong map data often points opposite the player — fall back to direct chase.
	if nav_dir.dot(to_player) < 0.15:
		return to_player
	return nav_dir


static func _is_map_ready(agent: NavigationAgent3D) -> bool:
	var map_rid := agent.get_navigation_map()
	if not map_rid.is_valid():
		return false
	return NavigationServer3D.map_get_iteration_id(map_rid) > 0


static func _flat_normalized(offset: Vector3) -> Vector3:
	offset.y = 0.0
	if offset.length_squared() < 1e-8:
		return Vector3.ZERO
	return offset.normalized()
