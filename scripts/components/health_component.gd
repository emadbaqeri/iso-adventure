class_name HealthComponent
extends Node

signal damaged(amount: int, remaining: int)
signal died

@export var max_health: int = 5
@export var invincibility_duration: float = 0.6

var current_health: int = 0
var invincible: bool = false

var _invincible_time_left: float = 0.0


func _ready() -> void:
	current_health = max_health


func _physics_process(delta: float) -> void:
	if _invincible_time_left <= 0.0:
		return
	_invincible_time_left -= delta
	if _invincible_time_left <= 0.0:
		_invincible_time_left = 0.0
		invincible = false


func is_alive() -> bool:
	return current_health > 0


func apply_damage(amount: int) -> bool:
	if amount <= 0 or not is_alive() or invincible:
		return false
	current_health = maxi(0, current_health - amount)
	damaged.emit(amount, current_health)
	if current_health <= 0:
		died.emit()
	else:
		_start_invincibility(invincibility_duration)
	return true


func heal_to_full() -> void:
	current_health = max_health
	invincible = false
	_invincible_time_left = 0.0


func force_invincibility(duration: float) -> void:
	_start_invincibility(duration)


func _start_invincibility(duration: float) -> void:
	if duration <= 0.0:
		return
	invincible = true
	_invincible_time_left = maxf(_invincible_time_left, duration)
