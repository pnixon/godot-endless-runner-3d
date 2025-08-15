extends Area3D

# Movement speed (towards player)
const SPEED = 15.0

# Visual components
var mesh_instance: MeshInstance3D
var collision_shape: CollisionShape3D

# Hazard data
var hazard_data: HazardData
var is_telegraphing = true
var telegraph_timer = 0.0
var setup_deferred = false

# 3D specific properties
var original_material: StandardMaterial3D
var telegraph_material: StandardMaterial3D

func _init():
	# Set collision layers for proper detection
	collision_layer = 1  # Hazards on layer 1
	collision_mask = 2   # Detect player on layer 2
	
	# Create collision shape node
	collision_shape = CollisionShape3D.new()
	collision_shape.name = "CollisionShape3D"
	add_child(collision_shape)
	
	# Create mesh instance
	mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "MeshInstance3D"
	add_child(mesh_instance)

func _ready():
	add_to_group("obstacles")
	
	# Connect signals
	body_entered.connect(_on_body_entered)
	
	# If setup was called before _ready, process it now
	if setup_deferred:
		_process_setup()

func setup_hazard(data: HazardData):
	# Store the data
	hazard_data = data
	
	if is_inside_tree():
		_process_setup()
	else:
		setup_deferred = true

func _process_setup():
	if not hazard_data:
		return
	
	# Create appropriate 3D mesh based on hazard type
	var hazard_mesh: Mesh
	var hazard_color = Color.WHITE
	
	match hazard_data.type:
		HazardData.HazardType.GROUND_SPIKES:
			hazard_mesh = create_spikes_mesh()
			hazard_color = Color.RED
		HazardData.HazardType.OVERHEAD_BARRIER:
			hazard_mesh = create_barrier_mesh()
			hazard_color = Color.ORANGE
		HazardData.HazardType.PICKUP_COIN:
			hazard_mesh = create_coin_mesh()
			hazard_color = Color.YELLOW
		HazardData.HazardType.PICKUP_XP:
			hazard_mesh = create_xp_mesh()
			hazard_color = Color.CYAN
		HazardData.HazardType.ENEMY_MARKER:
			hazard_mesh = create_enemy_mesh()
			hazard_color = Color.PURPLE
		HazardData.HazardType.HEALTH_POTION:
			hazard_mesh = create_potion_mesh()
			hazard_color = Color.MAGENTA
		_:
			hazard_mesh = BoxMesh.new()
			hazard_color = hazard_data.color

	# Set up mesh
	mesh_instance.mesh = hazard_mesh
	
	# Create materials
	original_material = StandardMaterial3D.new()
	original_material.albedo_color = hazard_color
	original_material.emission_enabled = true
	original_material.emission = hazard_color * 0.3
	
	telegraph_material = StandardMaterial3D.new()
	telegraph_material.albedo_color = hazard_color
	telegraph_material.emission_enabled = true
	telegraph_material.emission = hazard_color * 0.8
	telegraph_material.flags_transparent = true
	
	mesh_instance.material_override = telegraph_material
	
	# Set up collision shape
	var shape = BoxShape3D.new()
	shape.size = Vector3(hazard_data.size.x, hazard_data.size.y, 1.0)  # Convert 2D size to 3D
	collision_shape.shape = shape
	
	# Set telegraph timer
	telegraph_timer = hazard_data.telegraph_time

func create_spikes_mesh() -> Mesh:
	# Create a spiky mesh for ground spikes
	var array_mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	
	# Simple pyramid shape for spikes
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var uvs = PackedVector2Array()
	var indices = PackedInt32Array()
	
	# Base vertices
	vertices.push_back(Vector3(-0.5, 0, -0.5))
	vertices.push_back(Vector3(0.5, 0, -0.5))
	vertices.push_back(Vector3(0.5, 0, 0.5))
	vertices.push_back(Vector3(-0.5, 0, 0.5))
	# Spike tip
	vertices.push_back(Vector3(0, 1, 0))
	
	# Simple normals (pointing up)
	for i in range(5):
		normals.push_back(Vector3(0, 1, 0))
	
	# UVs
	uvs.push_back(Vector2(0, 0))
	uvs.push_back(Vector2(1, 0))
	uvs.push_back(Vector2(1, 1))
	uvs.push_back(Vector2(0, 1))
	uvs.push_back(Vector2(0.5, 0.5))
	
	# Triangles
	indices.append_array([0, 1, 4, 1, 2, 4, 2, 3, 4, 3, 0, 4])
	
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return array_mesh

func create_barrier_mesh() -> Mesh:
	# Create a barrier mesh (tall box)
	var box = BoxMesh.new()
	box.size = Vector3(2.0, 0.5, 1.0)
	return box

func create_coin_mesh() -> Mesh:
	# Create a coin mesh (cylinder)
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.3
	cylinder.bottom_radius = 0.3
	cylinder.height = 0.1
	return cylinder

func create_xp_mesh() -> Mesh:
	# Create an XP orb (sphere)
	var sphere = SphereMesh.new()
	sphere.radius = 0.3
	sphere.height = 0.6
	return sphere

func create_enemy_mesh() -> Mesh:
	# Create an enemy marker (larger box)
	var box = BoxMesh.new()
	box.size = Vector3(1.2, 1.2, 1.2)
	return box

func create_potion_mesh() -> Mesh:
	# Create a potion mesh (capsule)
	var capsule = CapsuleMesh.new()
	capsule.radius = 0.2
	capsule.height = 0.6
	return capsule

func _physics_process(delta):
	# Move towards player (negative Z direction)
	position.z += SPEED * delta
	
	# Handle telegraphing phase
	if is_telegraphing:
		telegraph_timer -= delta
		
		if mesh_instance and is_instance_valid(mesh_instance):
			# Different telegraph effects for different hazard types
			if hazard_data.type == HazardData.HazardType.ENEMY_MARKER:
				# Slower, more dramatic pulsing for enemy markers
				var pulse = sin(telegraph_timer * 6.0) * 0.4 + 0.6
				telegraph_material.albedo_color.a = pulse
				# Add color shifting
				var color_shift = sin(telegraph_timer * 8.0) * 0.3 + 0.7
				telegraph_material.albedo_color = Color(1.0, color_shift, 1.0, pulse)
			elif hazard_data.type == HazardData.HazardType.HEALTH_POTION:
				# Gentle, healing pulsing for health potions
				var pulse = sin(telegraph_timer * 4.0) * 0.2 + 0.8
				telegraph_material.albedo_color.a = pulse
				# Add green healing glow
				var glow = sin(telegraph_timer * 5.0) * 0.3 + 0.7
				telegraph_material.albedo_color = Color(glow, 1.0, glow, pulse)
			else:
				# Normal telegraph for other hazards
				var pulse = sin(telegraph_timer * 10.0) * 0.3 + 0.7
				telegraph_material.albedo_color.a = pulse

		if telegraph_timer <= 0:
			# Telegraph finished - show full hazard
			is_telegraphing = false
			if mesh_instance and is_instance_valid(mesh_instance):
				mesh_instance.material_override = original_material
	
	# Remove if too far behind player
	if position.z > 10.0:
		return_to_pool()

func return_to_pool():
	# Try to return to pool via game manager
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	if game_manager and game_manager.has_method("return_obstacle_to_pool"):
		game_manager.return_obstacle_to_pool(self)
	else:
		# Fallback: just remove from scene
		queue_free()

func reset_state():
	# Reset all state variables for reuse from object pool
	hazard_data = null
	is_telegraphing = true
	telegraph_timer = 0.0
	setup_deferred = false
	
	# Reset materials
	if mesh_instance and is_instance_valid(mesh_instance):
		mesh_instance.material_override = null
	
	# Reset mesh and collision
	if mesh_instance:
		mesh_instance.mesh = null
	if collision_shape:
		collision_shape.shape = null

func cleanup():
	# Clean up all associated meshes and shapes
	if mesh_instance and is_instance_valid(mesh_instance):
		mesh_instance.mesh = null
		mesh_instance.material_override = null
	
	if collision_shape and is_instance_valid(collision_shape):
		collision_shape.shape = null

func _exit_tree():
	# Ensure cleanup when node is removed from tree
	cleanup()

func _on_body_entered(body):
	print("=== ENHANCED OBSTACLE 3D COLLISION ===")
	print("Body entered: ", body.name)
	print("Body type: ", body.get_class())
	print("Hazard type: ", get_hazard_type())
	
	if body.name == "Player":
		match hazard_data.type:
			HazardData.HazardType.GROUND_SPIKES:
				if not body.is_jumping:
					get_tree().call_group("game_manager", "player_hit", "ground_spikes")
				else:
					get_tree().call_group("game_manager", "perfect_dodge")
			
			HazardData.HazardType.OVERHEAD_BARRIER:
				if not body.is_sliding:
					get_tree().call_group("game_manager", "player_hit", "overhead_barrier")
				else:
					get_tree().call_group("game_manager", "perfect_dodge")
			
			HazardData.HazardType.PICKUP_COIN:
				get_tree().call_group("game_manager", "collect_pickup", "coin", 10)
				return_to_pool()
			
			HazardData.HazardType.PICKUP_XP:
				get_tree().call_group("game_manager", "collect_pickup", "xp", 5)
				return_to_pool()
			
			HazardData.HazardType.HEALTH_POTION:
				get_tree().call_group("game_manager", "collect_pickup", "health_potion", 30)
				return_to_pool()
			
			HazardData.HazardType.ENEMY_MARKER:
				# Trigger combat encounter (fix parameter order: formation_id first, then lane)
				print("Player hit enemy marker! Formation: ", hazard_data.enemy_formation_id)
				get_tree().call_group("game_manager", "start_combat", hazard_data.enemy_formation_id, hazard_data.lane)
				return_to_pool()

func get_hazard_type() -> String:
	# Convert HazardData.HazardType enum to string for player collision detection
	if not hazard_data:
		return "UNKNOWN"
	
	match hazard_data.type:
		HazardData.HazardType.GROUND_SPIKES:
			return "GROUND_SPIKES"
		HazardData.HazardType.OVERHEAD_BARRIER:
			return "OVERHEAD_BARRIER"
		HazardData.HazardType.PICKUP_COIN:
			return "PICKUP_COIN"
		HazardData.HazardType.PICKUP_XP:
			return "PICKUP_XP"
		HazardData.HazardType.ENEMY_MARKER:
			return "ENEMY_MARKER"
		HazardData.HazardType.HEALTH_POTION:
			return "HEALTH_POTION"
		_:
			return "UNKNOWN"
