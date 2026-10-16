class_name SlimeEnemy
extends CharacterBody3D

@export_group("Movement")
@export var chase_speed: float = 4.5
@export var lunge_speed: float = 9.0
@export var gravity: float = 28.0

@export_group("Combat")
@export var detection_range: float = 14.0
@export var attack_range: float = 2.2
@export var knockback_strength: float = 6.5
@export var telegraph_time: float = 0.4
@export var lunge_time: float = 0.35

@onready var state_machine: SlimeStateMachine = $SlimeStateMachine
@onready var health: HealthComponent = $HealthComponent
@onready var hurtbox: HurtboxComponent = $Hurtbox
@onready var attack_hitbox: HitboxComponent = $AttackHitbox
@onready var visual: Node3D = $Visual
@onready var body_mesh: MeshInstance3D = $Visual/Body

var hurt_lock_time: float = 0.0
var telegraph_elapsed: float = 0.0
var lunge_elapsed: float = 0.0
var lunge_direction: Vector3 = Vector3.FORWARD

var _base_body_color: Color = Color(0.35, 0.78, 0.42)
var _hit_flash_time: float = 0.0


func _exit_tree() -> void:
	_hit_flash_time = 0.0
	set_telegraph_visual(false)
	set_attack_hitbox_active(false)


func _ready() -> void:
	collision_layer = CombatLayers.ENEMY_BODY
	collision_mask = CombatLayers.WORLD | CombatLayers.PLAYER_BODY
	attack_hitbox.owner_root = self
	if body_mesh != null:
		var mat := body_mesh.get_surface_override_material(0) as StandardMaterial3D
		if mat != null:
			_base_body_color = mat.albedo_color
	health.damaged.connect(_on_damaged)
	health.died.connect(_on_died)
	call_deferred("_find_player")


func _physics_process(delta: float) -> void:
	if hurt_lock_time > 0.0:
		hurt_lock_time -= delta
	if _hit_flash_time > 0.0:
		_hit_flash_time -= delta
		if _hit_flash_time <= 0.0:
			set_telegraph_visual(false)
	state_machine.physics_update(delta)


func _find_player() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		state_machine.player = players[0] as Node3D


func get_player() -> Node3D:
	if state_machine.player != null and is_instance_valid(state_machine.player):
		return state_machine.player
	_find_player()
	return state_machine.player


func distance_to_player() -> float:
	var target := get_player()
	if target == null:
		return INF
	return global_position.distance_to(target.global_position)


func direction_to_player_flat() -> Vector3:
	var target := get_player()
	if target == null:
		return Vector3.ZERO
	var delta := target.global_position - global_position
	delta.y = 0.0
	if delta.length_squared() < 0.0001:
		return Vector3.FORWARD
	return delta.normalized()


func apply_knockback(from_world: Vector3) -> void:
	var push := global_position - from_world
	push.y = 0.0
	if push.length_squared() < 0.0001:
		push = -global_transform.basis.z
	push = push.normalized()
	velocity.x = push.x * knockback_strength
	velocity.z = push.z * knockback_strength


func set_telegraph_visual(active: bool) -> void:
	if body_mesh == null:
		return
	var mat := body_mesh.get_surface_override_material(0) as StandardMaterial3D
	if mat == null:
		return
	if active:
		mat.albedo_color = Color(0.95, 0.35, 0.32)
	elif _hit_flash_time <= 0.0:
		mat.albedo_color = _base_body_color


func set_attack_hitbox_active(active: bool) -> void:
	if active:
		attack_hitbox.activate()
	else:
		attack_hitbox.deactivate()


func step_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0


func move_slide() -> void:
	move_and_slide()


func _on_damaged(_amount: int, _remaining: int) -> void:
	_flash_hit_color()
	if state_machine.get_current_state_name() != &"Dead":
		state_machine.change_state(&"Hurt")


func _on_died() -> void:
	state_machine.change_state(&"Dead")


func _flash_hit_color() -> void:
	_hit_flash_time = 0.12
	if body_mesh != null:
		var mat := body_mesh.get_surface_override_material(0) as StandardMaterial3D
		if mat != null:
			mat.albedo_color = Color(1.0, 0.4, 0.4)

