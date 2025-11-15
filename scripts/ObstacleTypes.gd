extends Node
class_name ObstacleTypes

# Obstacle type definitions for the endless runner
# This script creates different types of obstacles with unique behaviors

enum HazardType {
	GROUND_SPIKES,      # Avoided by jumping
	OVERHEAD_BARRIER,   # Avoided by sliding
	WALL_LEFT,          # Must move right to avoid
	WALL_RIGHT,         # Must move left to avoid
	WALL_CENTER,        # Must move to sides to avoid
}

# Obstacle creation functions

static func create_ground_spikes() -> Area3D:
	"""Create ground spikes that require jumping to avoid"""
	var obstacle = Area3D.new()
	obstacle.name = "GroundSpikes"
	obstacle.collision_layer = 1
	obstacle.collision_mask = 2
	obstacle.add_to_group("obstacles")
	obstacle.set_script(preload("res://scripts/MovingObject.gd"))

	# Create visual mesh - spiky appearance
	var mesh_instance = MeshInstance3D.new()
	var mesh = create_spikes_mesh()
	mesh_instance.mesh = mesh
	mesh_instance.position.y = 0.3

	# Create material - red and dangerous looking
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.8, 0.2, 0.2)  # Red
	material.metallic = 0.3
	material.roughness = 0.7
	material.emission_enabled = true
	material.emission = Color(0.5, 0.1, 0.1)
	mesh_instance.material_override = material

	# Add collision shape
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(1.0, 0.6, 1.0)
	collision.shape = shape
	collision.position.y = 0.3

	obstacle.add_child(mesh_instance)
	obstacle.add_child(collision)

	# Add metadata
	obstacle.set_meta("hazard_type", HazardType.GROUND_SPIKES)
	obstacle.set_meta("damage", 20.0)

	return obstacle

static func create_overhead_barrier() -> Area3D:
	"""Create overhead barrier that requires sliding to avoid"""
	var obstacle = Area3D.new()
	obstacle.name = "OverheadBarrier"
	obstacle.collision_layer = 1
	obstacle.collision_mask = 2
	obstacle.add_to_group("obstacles")
	obstacle.set_script(preload("res://scripts/MovingObject.gd"))

	# Create visual mesh - horizontal bar
	var mesh_instance = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(1.2, 0.4, 0.8)
	mesh_instance.mesh = box_mesh
	mesh_instance.position.y = 1.5  # Head height

	# Create material - yellow warning color
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.9, 0.7, 0.1)  # Yellow
	material.metallic = 0.6
	material.roughness = 0.4
	material.emission_enabled = true
	material.emission = Color(0.4, 0.3, 0.0)
	mesh_instance.material_override = material

	# Add collision shape
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(1.2, 0.4, 0.8)
	collision.shape = shape
	collision.position.y = 1.5

	obstacle.add_child(mesh_instance)
	obstacle.add_child(collision)

	# Add metadata
	obstacle.set_meta("hazard_type", HazardType.OVERHEAD_BARRIER)
	obstacle.set_meta("damage", 15.0)

	return obstacle

static func create_wall(wall_type: HazardType) -> Area3D:
	"""Create a wall obstacle that blocks lanes"""
	var obstacle = Area3D.new()
	obstacle.collision_layer = 1
	obstacle.collision_mask = 2
	obstacle.add_to_group("obstacles")
	obstacle.set_script(preload("res://scripts/MovingObject.gd"))

	match wall_type:
		HazardType.WALL_LEFT:
			obstacle.name = "WallLeft"
		HazardType.WALL_RIGHT:
			obstacle.name = "WallRight"
		HazardType.WALL_CENTER:
			obstacle.name = "WallCenter"

	# Create visual mesh - tall wall
	var mesh_instance = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(1.0, 2.5, 0.8)
	mesh_instance.mesh = box_mesh
	mesh_instance.position.y = 1.25

	# Create material - dark metal
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.3, 0.3, 0.35)  # Dark gray
	material.metallic = 0.8
	material.roughness = 0.3
	mesh_instance.material_override = material

	# Add collision shape
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(1.0, 2.5, 0.8)
	collision.shape = shape
	collision.position.y = 1.25

	obstacle.add_child(mesh_instance)
	obstacle.add_child(collision)

	# Add metadata
	obstacle.set_meta("hazard_type", wall_type)
	obstacle.set_meta("damage", 25.0)

	return obstacle

static func create_spikes_mesh() -> ArrayMesh:
	"""Create a mesh that looks like spikes"""
	var array_mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)

	# Create spike-like geometry using multiple pyramids
	var vertices = PackedVector3Array()
	var indices = PackedInt32Array()

	# Create 5 small pyramids to look like spikes
	for i in range(5):
		var base_x = -0.4 + i * 0.2
		var base_idx = vertices.size()

		# Base corners
		vertices.append(Vector3(base_x - 0.08, 0, -0.08))
		vertices.append(Vector3(base_x + 0.08, 0, -0.08))
		vertices.append(Vector3(base_x + 0.08, 0, 0.08))
		vertices.append(Vector3(base_x - 0.08, 0, 0.08))
		# Tip
		vertices.append(Vector3(base_x, 0.6, 0))

		# Create triangles for pyramid
		# Bottom face
		indices.append_array([base_idx, base_idx + 1, base_idx + 2])
		indices.append_array([base_idx, base_idx + 2, base_idx + 3])
		# Side faces
		indices.append_array([base_idx, base_idx + 4, base_idx + 1])
		indices.append_array([base_idx + 1, base_idx + 4, base_idx + 2])
		indices.append_array([base_idx + 2, base_idx + 4, base_idx + 3])
		indices.append_array([base_idx + 3, base_idx + 4, base_idx])

	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices

	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return array_mesh

# Helper function to get hazard type from obstacle
static func get_hazard_type(obstacle: Area3D) -> HazardType:
	if obstacle.has_meta("hazard_type"):
		return obstacle.get_meta("hazard_type")
	return HazardType.GROUND_SPIKES  # Default

static func get_damage(obstacle: Area3D) -> float:
	if obstacle.has_meta("damage"):
		return obstacle.get_meta("damage")
	return 10.0  # Default damage
