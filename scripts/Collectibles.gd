extends Node
class_name Collectibles

# Collectible items for the endless runner
# Creates coins, health pickups, and power-ups

enum CollectibleType {
	COIN,
	HEALTH_POTION,
	SPEED_BOOST,
	SHIELD,
	MAGNET,
}

# Create functions for each collectible type

static func create_coin() -> Area3D:
	"""Create a collectible coin"""
	var coin = Area3D.new()
	coin.name = "Coin"
	coin.collision_layer = 4  # Collectibles layer
	coin.collision_mask = 2   # Player layer
	coin.add_to_group("collectibles")
	coin.set_script(preload("res://scripts/MovingObject.gd"))

	# Create visual mesh - spinning coin
	var mesh_instance = MeshInstance3D.new()
	var cylinder_mesh = CylinderMesh.new()
	cylinder_mesh.top_radius = 0.3
	cylinder_mesh.bottom_radius = 0.3
	cylinder_mesh.height = 0.1
	mesh_instance.mesh = cylinder_mesh
	mesh_instance.position.y = 1.0
	mesh_instance.rotation_degrees.x = 90  # Make it face forward

	# Create material - shiny gold
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.84, 0.0)  # Gold
	material.metallic = 0.9
	material.roughness = 0.1
	material.emission_enabled = true
	material.emission = Color(0.8, 0.7, 0.0) * 0.5
	mesh_instance.material_override = material

	# Add collision shape
	var collision = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = 0.4
	collision.shape = shape
	collision.position.y = 1.0

	coin.add_child(mesh_instance)
	coin.add_child(collision)

	# Add metadata
	coin.set_meta("collectible_type", CollectibleType.COIN)
	coin.set_meta("value", 10)
	coin.set_meta("score_bonus", 50)

	# Add rotation animation
	add_rotation_animation(mesh_instance)

	return coin

static func create_health_potion() -> Area3D:
	"""Create a health restoration item"""
	var potion = Area3D.new()
	potion.name = "HealthPotion"
	potion.collision_layer = 4
	potion.collision_mask = 2
	potion.add_to_group("collectibles")
	potion.set_script(preload("res://scripts/MovingObject.gd"))

	# Create visual mesh - potion bottle shape
	var mesh_instance = MeshInstance3D.new()
	var capsule_mesh = CapsuleMesh.new()
	capsule_mesh.radius = 0.2
	capsule_mesh.height = 0.5
	mesh_instance.mesh = capsule_mesh
	mesh_instance.position.y = 1.0

	# Create material - healing red
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.2, 0.2)  # Red
	material.metallic = 0.2
	material.roughness = 0.3
	material.emission_enabled = true
	material.emission = Color(0.8, 0.1, 0.1) * 0.6
	mesh_instance.material_override = material

	# Add collision shape
	var collision = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = 0.4
	collision.shape = shape
	collision.position.y = 1.0

	potion.add_child(mesh_instance)
	potion.add_child(collision)

	# Add metadata
	potion.set_meta("collectible_type", CollectibleType.HEALTH_POTION)
	potion.set_meta("heal_amount", 30.0)
	potion.set_meta("score_bonus", 100)

	# Add bobbing animation
	add_bobbing_animation(mesh_instance)

	return potion

static func create_speed_boost() -> Area3D:
	"""Create a temporary speed boost power-up"""
	var boost = Area3D.new()
	boost.name = "SpeedBoost"
	boost.collision_layer = 4
	boost.collision_mask = 2
	boost.add_to_group("collectibles")
	boost.set_script(preload("res://scripts/MovingObject.gd"))

	# Create visual mesh - arrow shape pointing forward
	var mesh_instance = MeshInstance3D.new()
	var cone_mesh = ConeMesh.new()
	cone_mesh.radius = 0.3
	cone_mesh.height = 0.6
	mesh_instance.mesh = cone_mesh
	mesh_instance.position.y = 1.0
	mesh_instance.rotation_degrees.z = -90  # Point forward

	# Create material - speed blue
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.2, 0.6, 1.0)  # Light blue
	material.metallic = 0.4
	material.roughness = 0.2
	material.emission_enabled = true
	material.emission = Color(0.1, 0.4, 0.8) * 0.7
	mesh_instance.material_override = material

	# Add collision shape
	var collision = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = 0.4
	collision.shape = shape
	collision.position.y = 1.0

	boost.add_child(mesh_instance)
	boost.add_child(collision)

	# Add metadata
	boost.set_meta("collectible_type", CollectibleType.SPEED_BOOST)
	boost.set_meta("duration", 5.0)
	boost.set_meta("score_bonus", 150)

	# Add pulsing animation
	add_pulsing_animation(mesh_instance)

	return boost

static func create_shield() -> Area3D:
	"""Create a temporary shield power-up"""
	var shield = Area3D.new()
	shield.name = "Shield"
	shield.collision_layer = 4
	shield.collision_mask = 2
	shield.add_to_group("collectibles")
	shield.set_script(preload("res://scripts/MovingObject.gd"))

	# Create visual mesh - octahedron for shield
	var mesh_instance = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.35
	sphere_mesh.height = 0.7
	sphere_mesh.radial_segments = 8
	sphere_mesh.rings = 4
	mesh_instance.mesh = sphere_mesh
	mesh_instance.position.y = 1.0

	# Create material - protective cyan
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.0, 0.8, 0.8)  # Cyan
	material.metallic = 0.7
	material.roughness = 0.1
	material.emission_enabled = true
	material.emission = Color(0.0, 0.6, 0.6) * 0.8
	mesh_instance.material_override = material

	# Add collision shape
	var collision = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = 0.4
	collision.shape = shape
	collision.position.y = 1.0

	shield.add_child(mesh_instance)
	shield.add_child(collision)

	# Add metadata
	shield.set_meta("collectible_type", CollectibleType.SHIELD)
	shield.set_meta("duration", 10.0)
	shield.set_meta("score_bonus", 200)

	# Add rotation animation
	add_rotation_animation(mesh_instance)

	return shield

static func create_magnet() -> Area3D:
	"""Create a coin magnet power-up"""
	var magnet = Area3D.new()
	magnet.name = "Magnet"
	magnet.collision_layer = 4
	magnet.collision_mask = 2
	magnet.add_to_group("collectibles")
	magnet.set_script(preload("res://scripts/MovingObject.gd"))

	# Create visual mesh - horseshoe magnet shape
	var mesh_instance = MeshInstance3D.new()
	var torus_mesh = TorusMesh.new()
	torus_mesh.inner_radius = 0.15
	torus_mesh.outer_radius = 0.35
	mesh_instance.mesh = torus_mesh
	mesh_instance.position.y = 1.0

	# Create material - magnet purple
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.8, 0.2, 0.8)  # Purple/Magenta
	material.metallic = 0.6
	material.roughness = 0.2
	material.emission_enabled = true
	material.emission = Color(0.6, 0.1, 0.6) * 0.6
	mesh_instance.material_override = material

	# Add collision shape
	var collision = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = 0.4
	collision.shape = shape
	collision.position.y = 1.0

	magnet.add_child(mesh_instance)
	magnet.add_child(collision)

	# Add metadata
	magnet.set_meta("collectible_type", CollectibleType.MAGNET)
	magnet.set_meta("duration", 8.0)
	magnet.set_meta("score_bonus", 150)

	# Add rotation animation
	add_rotation_animation(mesh_instance)

	return magnet

# Animation helpers

static func add_rotation_animation(mesh: MeshInstance3D):
	"""Add continuous rotation animation"""
	var tween = mesh.create_tween()
	tween.set_loops()
	tween.tween_property(mesh, "rotation:y", TAU, 2.0).from(0.0)

static func add_bobbing_animation(mesh: MeshInstance3D):
	"""Add up and down bobbing motion"""
	var original_y = mesh.position.y
	var tween = mesh.create_tween()
	tween.set_loops()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(mesh, "position:y", original_y + 0.2, 1.0)
	tween.tween_property(mesh, "position:y", original_y - 0.2, 1.0)

static func add_pulsing_animation(mesh: MeshInstance3D):
	"""Add scale pulsing animation"""
	var tween = mesh.create_tween()
	tween.set_loops()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(mesh, "scale", Vector3.ONE * 1.2, 0.5)
	tween.tween_property(mesh, "scale", Vector3.ONE * 0.8, 0.5)

# Helper functions

static func get_collectible_type(collectible: Area3D) -> CollectibleType:
	if collectible.has_meta("collectible_type"):
		return collectible.get_meta("collectible_type")
	return CollectibleType.COIN  # Default

static func get_value(collectible: Area3D) -> int:
	if collectible.has_meta("value"):
		return collectible.get_meta("value")
	return 0

static func get_score_bonus(collectible: Area3D) -> int:
	if collectible.has_meta("score_bonus"):
		return collectible.get_meta("score_bonus")
	return 0

static func get_heal_amount(collectible: Area3D) -> float:
	if collectible.has_meta("heal_amount"):
		return collectible.get_meta("heal_amount")
	return 0.0

static func get_duration(collectible: Area3D) -> float:
	if collectible.has_meta("duration"):
		return collectible.get_meta("duration")
	return 0.0
