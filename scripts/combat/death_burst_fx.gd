class_name DeathBurstFx
extends RefCounted

const LIFETIME := 0.4


static func spawn(world_position: Vector3, parent: Node, tint: Color = Color(0.35, 0.78, 0.42)) -> void:
	if parent == null:
		return
	var particles := CPUParticles3D.new()
	var cube := BoxMesh.new()
	cube.size = Vector3(0.14, 0.14, 0.14)
	particles.mesh = cube
	particles.one_shot = true
	particles.emitting = true
	particles.amount = 14
	particles.lifetime = LIFETIME
	particles.explosiveness = 1.0
	particles.randomness = 0.35
	particles.direction = Vector3(0.0, 1.0, 0.0)
	particles.spread = 165.0
	particles.initial_velocity_min = 2.5
	particles.initial_velocity_max = 6.0
	particles.gravity = Vector3(0.0, -12.0, 0.0)
	particles.scale_amount_min = 0.85
	particles.scale_amount_max = 1.15
	var mat := StandardMaterial3D.new()
	mat.albedo_color = tint
	mat.emission_enabled = true
	mat.emission = tint * 0.35
	particles.material_override = mat
	parent.add_child(particles)
	particles.global_position = world_position
	particles.finished.connect(particles.queue_free)
