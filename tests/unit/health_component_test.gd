extends GdUnitTestSuite


func test_starts_at_max_health() -> void:
	var health: HealthComponent = HealthComponent.new()
	auto_free(health)
	add_child(health)
	await await_idle_frame()
	assert_int(health.current_health).is_equal(5)
	assert_bool(health.is_alive()).is_true()


func test_apply_damage_emits_signals_and_reduces_health() -> void:
	var health: HealthComponent = HealthComponent.new()
	health.max_health = 5
	health.invincibility_duration = 0.0
	auto_free(health)
	add_child(health)
	await await_idle_frame()
	monitor_signals(health, false)
	assert_bool(health.apply_damage(2)).is_true()
	assert_int(health.current_health).is_equal(3)
	await assert_signal(health).is_emitted("damaged", 2, 3)


func test_invincibility_blocks_damage() -> void:
	var health: HealthComponent = HealthComponent.new()
	health.max_health = 5
	health.invincibility_duration = 0.5
	auto_free(health)
	add_child(health)
	await await_idle_frame()
	assert_bool(health.apply_damage(1)).is_true()
	assert_bool(health.invincible).is_true()
	assert_bool(health.apply_damage(1)).is_false()
	assert_int(health.current_health).is_equal(4)


func test_death_emits_died() -> void:
	var health: HealthComponent = HealthComponent.new()
	health.max_health = 2
	health.invincibility_duration = 0.0
	auto_free(health)
	add_child(health)
	await await_idle_frame()
	monitor_signals(health, false)
	health.apply_damage(2)
	await assert_signal(health).is_emitted("died")
	assert_bool(health.is_alive()).is_false()


func test_invincibility_expires() -> void:
	var health: HealthComponent = HealthComponent.new()
	health.max_health = 5
	health.invincibility_duration = 0.1
	auto_free(health)
	add_child(health)
	await await_idle_frame()
	health.apply_damage(1)
	assert_bool(health.invincible).is_true()
	await await_millis(200)
	assert_bool(health.invincible).is_false()
	assert_bool(health.apply_damage(1)).is_true()
	assert_int(health.current_health).is_equal(3)
