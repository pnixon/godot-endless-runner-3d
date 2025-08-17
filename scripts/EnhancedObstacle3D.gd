extends Area3D
class_name EnhancedObstacle3D

# Simple obstacle without hazard system
const SPEED = 22.0

# Visual components
var mesh_instance: MeshInstance3D
var collision_shape: CollisionShape3D

func _ready():
	# Set up basic obstacle
	collision_layer = 1
	collision_mask = 0
	
	# Create mesh instance
	mesh_instance = MeshInstance3D.new()
	add_child(mesh_instance)
	
	# Create collision shape
	collision_shape = CollisionShape3D.new()
	add_child(collision_shape)
	
	# Create a simple box obstacle
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(0.8, 1.0, 0.8)
	mesh_instance.mesh = box_mesh
	
	# Create collision shape
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(0.8, 1.0, 0.8)
	collision_shape.shape = box_shape
	
	# Create material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.GRAY
	mesh_instance.material_override = material

func _process(delta):
	# Move obstacle towards player
	position.z += SPEED * delta
	
	# Remove when off screen
	if position.z > 10.0:
		queue_free()

# Legacy method for compatibility - does nothing now
func setup_hazard(data):
	pass

# Legacy method for compatibility
func get_hazard_type() -> String:
	return "NONE"
