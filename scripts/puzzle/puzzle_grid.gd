class_name PuzzleGrid
extends Object

const TILE_SIZE := 2.0


static func world_to_cell(world_pos: Vector3) -> Vector2i:
	return Vector2i(
		int(round(world_pos.x / TILE_SIZE)),
		int(round(world_pos.z / TILE_SIZE))
	)


static func cell_to_world(cell: Vector2i, y: float = 0.0) -> Vector3:
	return Vector3(float(cell.x) * TILE_SIZE, y, float(cell.y) * TILE_SIZE)


static func snap_world(world_pos: Vector3) -> Vector3:
	var cell := world_to_cell(world_pos)
	return cell_to_world(cell, world_pos.y)


static func is_cell_blocked(
	cell: Vector2i,
	blocked_cells: Dictionary,
	occupied_cells: Dictionary,
	ignore_cell: Vector2i = Vector2i(-99999, -99999)
) -> bool:
	if cell == ignore_cell:
		return false
	if blocked_cells.has(cell):
		return true
	if occupied_cells.has(cell):
		return true
	return false


static func can_move_from(
	from_cell: Vector2i,
	direction: Vector2i,
	blocked_cells: Dictionary,
	occupied_cells: Dictionary
) -> bool:
	if direction == Vector2i.ZERO:
		return false
	var target := from_cell + direction
	return not is_cell_blocked(target, blocked_cells, occupied_cells, from_cell)


static func cardinal_from_world_delta(delta: Vector3) -> Vector2i:
	if delta.length_squared() < 0.0001:
		return Vector2i.ZERO
	if absf(delta.x) >= absf(delta.z):
		return Vector2i(1 if delta.x > 0.0 else -1, 0)
	return Vector2i(0, 1 if delta.z > 0.0 else -1)
