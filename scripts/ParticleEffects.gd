extends Node
class_name ParticleEffects

# Particle effect creation for the endless runner
# Creates visual feedback for various game events

static func create_coin_collect_effect(position: Vector3) -> GPUParticles3D:
	"""Create particle effect for collecting a coin"""
	var particles = GPUParticles3D.new()
	particles.global_position = position
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 20
	particles.lifetime = 0.6
	particles.explosiveness = 0.8

	# Create particle material
	var material = ParticleProcessMaterial.new()
	material.direction = Vector3(0, 1, 0)
	material.spread = 180.0
	material.initial_velocity_min = 3.0
	material.initial_velocity_max = 6.0
	material.gravity = Vector3(0, -9.8, 0)
	material.color = Color(1.0, 0.84, 0.0)  # Gold color
	particles.process_material = material

	# Create mesh for particles
	var mesh = SphereMesh.new()
	mesh.radial_segments = 4
	mesh.rings = 2
	mesh.radius = 0.1
	mesh.height = 0.2
	particles.draw_pass_1 = mesh

	# Auto-cleanup
	particles.finished.connect(particles.queue_free)

	return particles

static func create_powerup_collect_effect(position: Vector3, color: Color) -> GPUParticles3D:
	"""Create particle effect for collecting a power-up"""
	var particles = GPUParticles3D.new()
	particles.global_position = position
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 30
	particles.lifetime = 0.8
	particles.explosiveness = 0.9

	var material = ParticleProcessMaterial.new()
	material.direction = Vector3(0, 1, 0)
	material.spread = 180.0
	material.initial_velocity_min = 4.0
	material.initial_velocity_max = 8.0
	material.gravity = Vector3(0, -5.0, 0)
	material.color = color
	particles.process_material = material

	var mesh = BoxMesh.new()
	mesh.size = Vector3(0.15, 0.15, 0.15)
	particles.draw_pass_1 = mesh

	particles.finished.connect(particles.queue_free)

	return particles

static func create_damage_effect(position: Vector3) -> GPUParticles3D:
	"""Create particle effect for taking damage"""
	var particles = GPUParticles3D.new()
	particles.global_position = position
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 15
	particles.lifetime = 0.5
	particles.explosiveness = 1.0

	var material = ParticleProcessMaterial.new()
	material.direction = Vector3(0, 0, 1)  # Backward
	material.spread = 90.0
	material.initial_velocity_min = 2.0
	material.initial_velocity_max = 5.0
	material.gravity = Vector3(0, -8.0, 0)
	material.color = Color(0.9, 0.2, 0.2)  # Red
	particles.process_material = material

	var mesh = SphereMesh.new()
	mesh.radius = 0.15
	mesh.height = 0.3
	particles.draw_pass_1 = mesh

	particles.finished.connect(particles.queue_free)

	return particles

static func create_heal_effect(position: Vector3) -> GPUParticles3D:
	"""Create particle effect for healing"""
	var particles = GPUParticles3D.new()
	particles.global_position = position
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 25
	particles.lifetime = 1.0
	particles.explosiveness = 0.6

	var material = ParticleProcessMaterial.new()
	material.direction = Vector3(0, 1, 0)
	material.spread = 45.0
	material.initial_velocity_min = 1.0
	material.initial_velocity_max = 3.0
	material.gravity = Vector3(0, 1.0, 0)  # Upward
	material.color = Color(0.2, 0.9, 0.2)  # Green
	particles.process_material = material

	var mesh = SphereMesh.new()
	mesh.radius = 0.1
	mesh.height = 0.2
	particles.draw_pass_1 = mesh

	particles.finished.connect(particles.queue_free)

	return particles

static func create_jump_dust_effect(position: Vector3) -> GPUParticles3D:
	"""Create dust cloud effect for jumping"""
	var particles = GPUParticles3D.new()
	particles.global_position = position
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 10
	particles.lifetime = 0.4
	particles.explosiveness = 0.7

	var material = ParticleProcessMaterial.new()
	material.direction = Vector3(0, 0.5, 0)
	material.spread = 120.0
	material.initial_velocity_min = 1.0
	material.initial_velocity_max = 2.0
	material.gravity = Vector3(0, -2.0, 0)
	material.color = Color(0.6, 0.6, 0.5, 0.5)  # Dusty color
	particles.process_material = material

	var mesh = SphereMesh.new()
	mesh.radius = 0.2
	mesh.height = 0.4
	particles.draw_pass_1 = mesh

	particles.finished.connect(particles.queue_free)

	return particles

static func create_slide_trail_effect(position: Vector3) -> GPUParticles3D:
	"""Create trail effect for sliding"""
	var particles = GPUParticles3D.new()
	particles.global_position = position
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 8
	particles.lifetime = 0.3
	particles.explosiveness = 0.5

	var material = ParticleProcessMaterial.new()
	material.direction = Vector3(0, 0.2, 1)  # Backward
	material.spread = 30.0
	material.initial_velocity_min = 0.5
	material.initial_velocity_max = 1.5
	material.gravity = Vector3(0, -3.0, 0)
	material.color = Color(0.7, 0.7, 0.6, 0.4)
	particles.process_material = material

	var mesh = BoxMesh.new()
	mesh.size = Vector3(0.15, 0.05, 0.15)
	particles.draw_pass_1 = mesh

	particles.finished.connect(particles.queue_free)

	return particles

static func create_speed_trail_particles() -> GPUParticles3D:
	"""Create continuous speed trail for speed boost"""
	var particles = GPUParticles3D.new()
	particles.emitting = true
	particles.amount = 20
	particles.lifetime = 0.5
	particles.explosiveness = 0.0

	var material = ParticleProcessMaterial.new()
	material.direction = Vector3(0, 0, 1)  # Backward
	material.spread = 20.0
	material.initial_velocity_min = 5.0
	material.initial_velocity_max = 8.0
	material.gravity = Vector3.ZERO
	material.color = Color(0.2, 0.6, 1.0, 0.6)  # Blue
	particles.process_material = material

	var mesh = BoxMesh.new()
	mesh.size = Vector3(0.1, 0.1, 0.3)
	particles.draw_pass_1 = mesh

	return particles

static func create_shield_aura() -> MeshInstance3D:
	"""Create a shield visual effect around the player"""
	var shield = MeshInstance3D.new()

	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 1.2
	sphere_mesh.height = 2.4
	sphere_mesh.radial_segments = 16
	sphere_mesh.rings = 8
	shield.mesh = sphere_mesh

	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.0, 0.8, 0.8, 0.3)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.emission_enabled = true
	material.emission = Color(0.0, 0.6, 0.6)
	material.emission_energy_multiplier = 0.5
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	shield.material_override = material

	# Add pulsing animation
	var tween = shield.create_tween()
	tween.set_loops()
	tween.tween_property(shield, "scale", Vector3.ONE * 1.1, 0.5)
	tween.tween_property(shield, "scale", Vector3.ONE * 0.95, 0.5)

	return shield

static func create_magnet_field() -> MeshInstance3D:
	"""Create a magnetic field visual effect"""
	var field = MeshInstance3D.new()

	var torus_mesh = TorusMesh.new()
	torus_mesh.inner_radius = 1.0
	torus_mesh.outer_radius = 1.5
	field.mesh = torus_mesh

	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.8, 0.2, 0.8, 0.4)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.emission_enabled = true
	material.emission = Color(0.6, 0.1, 0.6)
	material.emission_energy_multiplier = 0.6
	field.material_override = material

	# Add rotation animation
	var tween = field.create_tween()
	tween.set_loops()
	tween.tween_property(field, "rotation:y", TAU, 2.0).from(0.0)

	return field

static func create_obstacle_destroy_effect(position: Vector3, color: Color) -> GPUParticles3D:
	"""Create explosion effect for destroyed obstacles"""
	var particles = GPUParticles3D.new()
	particles.global_position = position
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 25
	particles.lifetime = 0.7
	particles.explosiveness = 0.9

	var material = ParticleProcessMaterial.new()
	material.direction = Vector3(0, 1, 0)
	material.spread = 180.0
	material.initial_velocity_min = 3.0
	material.initial_velocity_max = 7.0
	material.gravity = Vector3(0, -10.0, 0)
	material.color = color
	particles.process_material = material

	var mesh = BoxMesh.new()
	mesh.size = Vector3(0.2, 0.2, 0.2)
	particles.draw_pass_1 = mesh

	particles.finished.connect(particles.queue_free)

	return particles
