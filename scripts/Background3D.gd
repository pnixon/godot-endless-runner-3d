extends Node3D

# 3D Background system for endless runner
# Creates a scrolling environment effect

var ground_tiles = []
var tile_size = 20.0
var num_tiles = 10
var scroll_speed = 15.0

func _ready():
	create_ground_tiles()
	create_side_walls()
	create_sky_elements()

func create_ground_tiles():
	# Create repeating ground tiles
	for i in range(num_tiles):
		var tile = create_ground_tile()
		tile.position = Vector3(0, -1, -i * tile_size)
		add_child(tile)
		ground_tiles.append(tile)

func create_ground_tile() -> StaticBody3D:
	var tile = StaticBody3D.new()
	
	# Create mesh
	var mesh_instance = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(tile_size, 2.0, tile_size)
	mesh_instance.mesh = box_mesh
	
	# Create material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.3, 0.5, 0.3)  # Green ground
	material.roughness = 0.8
	mesh_instance.material_override = material
	
	# Create collision
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(tile_size, 2.0, tile_size)
	collision.shape = shape
	
	tile.add_child(mesh_instance)
	tile.add_child(collision)
	
	return tile

func create_side_walls():
	# Create walls on the sides to define the play area
	for side in [-1, 1]:  # Left and right
		for i in range(num_tiles):
			var wall = StaticBody3D.new()
			
			var mesh_instance = MeshInstance3D.new()
			var box_mesh = BoxMesh.new()
			box_mesh.size = Vector3(2.0, 10.0, tile_size)
			mesh_instance.mesh = box_mesh
			
			var material = StandardMaterial3D.new()
			material.albedo_color = Color(0.4, 0.4, 0.6)  # Blue-gray walls
			material.roughness = 0.7
			mesh_instance.material_override = material
			
			wall.position = Vector3(side * (tile_size/2 + 5), 4, -i * tile_size)
			wall.add_child(mesh_instance)
			add_child(wall)

func create_sky_elements():
	# Add some floating elements for visual interest
	for i in range(5):
		var cloud = create_cloud()
		cloud.position = Vector3(
			randf_range(-15, 15),
			randf_range(8, 15),
			randf_range(-100, 0)
		)
		add_child(cloud)

func create_cloud() -> MeshInstance3D:
	var cloud = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = randf_range(2, 4)
	sphere_mesh.height = sphere_mesh.radius * 1.5
	cloud.mesh = sphere_mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.9, 0.9, 1.0, 0.7)
	material.flags_transparent = true
	cloud.material_override = material
	
	return cloud

func _process(delta):
	# Scroll ground tiles
	for tile in ground_tiles:
		tile.position.z += scroll_speed * delta
		
		# Reset tile position when it goes too far
		if tile.position.z > tile_size:
			tile.position.z -= num_tiles * tile_size
