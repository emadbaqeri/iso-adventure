class_name RoomEnvDressing
extends Node3D

## Procedural kit dressing: floor tiles, perimeter visuals, foliage (visual-only where noted).

@export var floor_center: Vector3 = Vector3(4.0, 0.0, 0.0)
@export var floor_size: Vector3 = Vector3(34.0, 0.0, 26.0)
@export var puzzle_floor_size: Vector3 = Vector3(18.0, 0.0, 14.0)
@export var is_puzzle_room: bool = false
@export var foliage_seed: int = 4042
@export var hide_legacy_meshes: bool = true

const TILE_A := preload("res://scenes/env/stone_floor_tile_a.tscn")
const TILE_B := preload("res://scenes/env/stone_floor_tile_b.tscn")
const WALL_STRAIGHT := preload("res://scenes/env/stone_wall_straight.tscn")
const WALL_CORNER := preload("res://scenes/env/stone_wall_corner.tscn")
const WALL_BROKEN := preload("res://scenes/env/stone_wall_broken.tscn")
const PILLAR := preload("res://scenes/env/stone_pillar.tscn")
const RUNE := preload("res://scenes/env/rune_stone.tscn")
const CRATE := preload("res://scenes/env/crate.tscn")
const BRAZIER := preload("res://scenes/env/brazier.tscn")
const PINE_A := preload("res://scenes/env/pine_tree_a.tscn")
const PINE_B := preload("res://scenes/env/pine_tree_b.tscn")
const PINE_C := preload("res://scenes/env/pine_tree_c.tscn")
const DEAD_TREE := preload("res://scenes/env/dead_tree.tscn")
const BUSH_A := preload("res://scenes/env/bush_a.tscn")
const BUSH_B := preload("res://scenes/env/bush_b.tscn")
const GRASS_TUFT := preload("res://scenes/env/grass_tuft.tscn")
const HEATHER_TUFT := preload("res://scenes/env/heather_tuft.tscn")
const ROCK_A := preload("res://scenes/env/rock_a.tscn")
const ROCK_B := preload("res://scenes/env/rock_b.tscn")
const ROCK_C := preload("res://scenes/env/rock_c.tscn")
const SNOW_PATCH := preload("res://scenes/env/snow_patch.tscn")
const ENV_PALETTE_MAT := preload("res://materials/lowpoly_palette_env.tres")

const GRID := 2.0
const WALL_H := 2.4


func _ready() -> void:
	if hide_legacy_meshes:
		_hide_legacy_visuals()
	_build_floor_tiles()
	_build_perimeter_walls()
	_scatter_foliage()
	_place_props()


func _hide_legacy_visuals() -> void:
	var room := get_parent()
	if room == null:
		return
	for path: String in ["Floor/Mesh", "WallNorth/Mesh", "WallSouth/Mesh", "WallEast/Mesh"]:
		var mesh := room.get_node_or_null(path) as MeshInstance3D
		if mesh != null:
			mesh.visible = false
	_dress_legacy_crate(room)


func _dress_legacy_crate(room: Node) -> void:
	var crate_body := room.get_node_or_null("PropCrate") as StaticBody3D
	if crate_body == null:
		return
	var legacy_mesh := crate_body.get_node_or_null("Mesh") as MeshInstance3D
	if legacy_mesh != null:
		legacy_mesh.visible = false
	var packed := CRATE.instantiate() as Node3D
	var visual := packed.get_node_or_null("Visual")
	if visual != null:
		var copy := visual.duplicate() as Node3D
		crate_body.add_child(copy)
	packed.free()


func _build_floor_tiles() -> void:
	var tiles := Node3D.new()
	tiles.name = "FloorTiles"
	add_child(tiles)
	var size := puzzle_floor_size if is_puzzle_room else floor_size
	var half_x := size.x * 0.5
	var half_z := size.z * 0.5
	var cols := int(size.x / GRID)
	var rows := int(size.z / GRID)
	var start_x := floor_center.x - half_x + GRID * 0.5
	var start_z := floor_center.z - half_z + GRID * 0.5
	var alt := false
	for row: int in range(rows):
		for col: int in range(cols):
			var scene := TILE_A if (col + row + int(alt)) % 2 == 0 else TILE_B
			var tile := scene.instantiate() as Node3D
			tile.position = Vector3(start_x + col * GRID, 0.0, start_z + row * GRID)
			tiles.add_child(tile)
		alt = not alt


func _build_perimeter_walls() -> void:
	var walls := Node3D.new()
	walls.name = "PerimeterVisuals"
	add_child(walls)
	var size := puzzle_floor_size if is_puzzle_room else floor_size
	var half_x := size.x * 0.5
	var half_z := size.z * 0.5
	var cx := floor_center.x
	var cz := floor_center.z
	var north_z := cz - half_z - 0.6
	var south_z := cz + half_z + 0.6
	var west_x := cx - half_x - 0.6
	var east_x := cx + half_x + 0.6
	var count_x := int(size.x / GRID)
	var count_z := int(size.z / GRID)
	for i: int in range(count_x):
		var x := cx - half_x + GRID * 0.5 + i * GRID
		_add_wall(walls, WALL_STRAIGHT, Vector3(x, 0.0, north_z), 0.0)
		var south_scene := WALL_BROKEN if i % 5 == 2 else WALL_STRAIGHT
		_add_wall(walls, south_scene, Vector3(x, 0.0, south_z), 180.0)
	for i: int in range(count_z):
		var z := cz - half_z + GRID * 0.5 + i * GRID
		_add_wall(walls, WALL_STRAIGHT, Vector3(west_x, 0.0, z), 90.0)
		_add_wall(walls, WALL_STRAIGHT, Vector3(east_x, 0.0, z), -90.0)
	_add_wall(walls, WALL_CORNER, Vector3(west_x, 0.0, north_z), 0.0)
	_add_wall(walls, WALL_CORNER, Vector3(east_x, 0.0, north_z), -90.0)
	_add_wall(walls, WALL_CORNER, Vector3(west_x, 0.0, south_z), 90.0)
	_add_wall(walls, WALL_CORNER, Vector3(east_x, 0.0, south_z), 180.0)


func _add_wall(parent: Node3D, scene: PackedScene, pos: Vector3, yaw_deg: float) -> void:
	var wall := scene.instantiate() as Node3D
	wall.position = pos
	wall.rotation_degrees.y = yaw_deg
	if wall is StaticBody3D:
		(wall as StaticBody3D).collision_layer = 0
	parent.add_child(wall)


func _scatter_foliage() -> void:
	var foliage := Node3D.new()
	foliage.name = "Foliage"
	add_child(foliage)
	var rng := RandomNumberGenerator.new()
	rng.seed = foliage_seed
	var size := puzzle_floor_size if is_puzzle_room else floor_size
	var half_x := size.x * 0.5 + 2.5
	var half_z := size.z * 0.5 + 2.5
	var cx := floor_center.x
	var cz := floor_center.z
	var tree_scenes: Array[PackedScene] = [PINE_A, PINE_B, PINE_C]
	for _i: int in range(14 if not is_puzzle_room else 6):
		var pos := _random_outside(rng, cx, cz, half_x, half_z)
		if _blocks_player_lane(pos):
			continue
		var tree := tree_scenes[rng.randi() % tree_scenes.size()].instantiate() as Node3D
		tree.position = pos
		tree.rotation_degrees.y = rng.randf_range(0.0, 360.0)
		foliage.add_child(tree)
	for _i: int in range(6 if not is_puzzle_room else 3):
		var pos := _random_outside(rng, cx, cz, half_x, half_z)
		var dead := DEAD_TREE.instantiate() as Node3D
		dead.position = pos
		dead.rotation_degrees.y = rng.randf_range(0.0, 360.0)
		foliage.add_child(dead)
	for _i: int in range(10 if not is_puzzle_room else 4):
		var pos := _random_edge(rng, cx, cz, half_x - 1.0, half_z - 1.0)
		if _blocks_player_lane(pos):
			continue
		var bush_scene := BUSH_A if rng.randf() > 0.45 else BUSH_B
		var bush := bush_scene.instantiate() as Node3D
		bush.position = pos
		foliage.add_child(bush)
	for _i: int in range(8 if not is_puzzle_room else 3):
		var pos := _random_edge(rng, cx, cz, half_x - 0.5, half_z - 0.5)
		var rock_scenes: Array[PackedScene] = [ROCK_A, ROCK_B, ROCK_C]
		var rock := rock_scenes[rng.randi() % rock_scenes.size()].instantiate() as Node3D
		rock.position = pos
		rock.rotation_degrees.y = rng.randf_range(0.0, 360.0)
		foliage.add_child(rock)
	for _i: int in range(5):
		var pos := _random_edge(rng, cx, cz, half_x - 2.0, half_z - 2.0)
		var snow := SNOW_PATCH.instantiate() as Node3D
		snow.position = pos
		snow.rotation_degrees.y = rng.randf_range(0.0, 360.0)
		foliage.add_child(snow)
	_build_grass_multimesh(foliage, rng, cx, cz, half_x, half_z)


func _build_grass_multimesh(parent: Node3D, rng: RandomNumberGenerator, cx: float, cz: float, half_x: float, half_z: float) -> void:
	var grass_src := _mesh_and_material_from_scene(GRASS_TUFT)
	var heather_src := _mesh_and_material_from_scene(HEATHER_TUFT)
	if grass_src.mesh != null:
		parent.add_child(
			_make_tuft_multimesh(grass_src, rng, cx, cz, half_x, half_z, 120 if not is_puzzle_room else 40, &"GrassTufts")
		)
	if heather_src.mesh != null:
		parent.add_child(
			_make_tuft_multimesh(heather_src, rng, cx, cz, half_x, half_z, 60 if not is_puzzle_room else 24, &"HeatherTufts")
		)


func _mesh_and_material_from_scene(scene: PackedScene) -> Dictionary:
	var temp := scene.instantiate()
	var mesh: Mesh = null
	var mat: Material = null
	var visual := temp.get_node_or_null("Visual")
	if visual != null:
		for child: Node in visual.get_children():
			if child is MeshInstance3D:
				var inst := child as MeshInstance3D
				mesh = inst.mesh
				break
	temp.free()
	if mesh != null and mat == null:
		mat = ENV_PALETTE_MAT.duplicate()
	return {"mesh": mesh, "material": mat}


func _make_tuft_multimesh(
	source: Dictionary,
	rng: RandomNumberGenerator,
	cx: float,
	cz: float,
	half_x: float,
	half_z: float,
	count: int,
	label: StringName,
) -> MultiMeshInstance3D:
	var mmi := MultiMeshInstance3D.new()
	mmi.name = String(label)
	var mesh: Mesh = source.get("mesh")
	if mesh == null:
		return mmi
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = count
	for i: int in range(count):
		var pos := _random_edge(rng, cx, cz, half_x - 1.5, half_z - 1.5)
		if _blocks_player_lane(pos):
			pos = _random_outside(rng, cx, cz, half_x + 1.0, half_z + 1.0)
		var basis := Basis.from_euler(Vector3(0.0, rng.randf_range(0.0, TAU), 0.0))
		var scale := rng.randf_range(0.85, 1.15)
		basis = basis.scaled(Vector3(scale, scale, scale))
		mm.set_instance_transform(i, Transform3D(basis, pos))
	mmi.multimesh = mm
	var mat: Material = source.get("material")
	if mat != null:
		mmi.material_override = mat
	return mmi


func _place_props() -> void:
	var props := Node3D.new()
	props.name = "Props"
	add_child(props)
	if is_puzzle_room:
		_add_prop(props, PILLAR, Vector3(-6.0, 0.0, 4.0), 0.0)
		_add_prop(props, PILLAR, Vector3(6.0, 0.0, -4.0), 0.0)
		_add_prop(props, RUNE, Vector3(7.0, 0.0, 5.0), -25.0)
		_add_prop(props, BRAZIER, Vector3(-7.0, 0.0, -5.0), 0.0)
	else:
		_add_prop(props, BRAZIER, Vector3(-8.0, 0.0, -6.0), 40.0)
		_add_prop(props, RUNE, Vector3(14.0, 0.0, 8.0), 10.0)
		_add_prop(props, PILLAR, Vector3(-10.0, 0.0, 6.0), 0.0)
		_add_prop(props, PILLAR, Vector3(16.0, 0.0, -8.0), 0.0)


func _add_prop(parent: Node3D, scene: PackedScene, pos: Vector3, yaw_deg: float) -> void:
	var node := scene.instantiate() as Node3D
	node.position = pos
	node.rotation_degrees.y = yaw_deg
	if node is StaticBody3D:
		(node as StaticBody3D).collision_layer = 0
	parent.add_child(node)


func _random_outside(rng: RandomNumberGenerator, cx: float, cz: float, half_x: float, half_z: float) -> Vector3:
	var side := rng.randi() % 4
	match side:
		0:
			return Vector3(rng.randf_range(cx - half_x, cx + half_x), 0.0, cz - half_z - rng.randf_range(1.0, 4.0))
		1:
			return Vector3(rng.randf_range(cx - half_x, cx + half_x), 0.0, cz + half_z + rng.randf_range(1.0, 4.0))
		2:
			return Vector3(cx - half_x - rng.randf_range(1.0, 4.0), 0.0, rng.randf_range(cz - half_z, cz + half_z))
		_:
			return Vector3(cx + half_x + rng.randf_range(1.0, 4.0), 0.0, rng.randf_range(cz - half_z, cz + half_z))


func _random_edge(rng: RandomNumberGenerator, cx: float, cz: float, half_x: float, half_z: float) -> Vector3:
	var along_x := rng.randf() > 0.5
	if along_x:
		var z_sign := -1.0 if rng.randf() > 0.5 else 1.0
		return Vector3(
			rng.randf_range(cx - half_x, cx + half_x),
			0.0,
			cz + z_sign * (half_z + rng.randf_range(0.2, 1.8)),
		)
	var x_sign := -1.0 if rng.randf() > 0.5 else 1.0
	return Vector3(
		cx + x_sign * (half_x + rng.randf_range(0.2, 1.8)),
		0.0,
		rng.randf_range(cz - half_z, cz + half_z),
	)


func _blocks_player_lane(pos: Vector3) -> bool:
	# Keep spawn → gate → puzzle corridor clear (combat room).
	if is_puzzle_room:
		return absf(pos.x) < 2.5 and absf(pos.z) < 5.0
	return pos.z > -2.5 and pos.z < 2.5 and pos.x > -2.0 and pos.x < 14.0
