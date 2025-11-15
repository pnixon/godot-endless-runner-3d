extends Node3D
class_name GroundSystem

# Infinite scrolling ground for the endless runner
# Creates seamless looping ground tiles with visual variety

var ground_segments = []
const SEGMENT_LENGTH = 30.0
const NUM_SEGMENTS = 5
const SCROLL_SPEED = 15.0
const LANE_WIDTH = 3.0

# Visual variety
var segment_colors = [
	Color(0.25, 0.35, 0.25),  # Dark green
	Color(0.3, 0.4, 0.3),     # Medium green
	Color(0.28, 0.38, 0.28),  # Slightly different green
]

func _ready():
	create_ground_segments()
	create_lane_markers()
	create_boundaries()

func create_ground_segments():
	"""Create the repeating ground segments"""
	for i in range(NUM_SEGMENTS):
		var segment = create_segment(i)
		segment.position = Vector3(0, 0, -i * SEGMENT_LENGTH)
		add_child(segment)
		ground_segments.append(segment)
		print("Created ground segment ", i, " at Z: ", segment.position.z)

func create_segment(index: int) -> Node3D:
	"""Create a single ground segment with mesh and collision"""
	var segment = StaticBody3D.new()
	segment.name = "GroundSegment" + str(index)

	# Create mesh instance
	var mesh_instance = MeshInstance3D.new()
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(12.0, SEGMENT_LENGTH)  # Wide enough for 3 lanes
	mesh_instance.mesh = plane_mesh
	mesh_instance.rotation_degrees.x = -90  # Make it horizontal

	# Create material with some visual interest
	var material = StandardMaterial3D.new()
	var color_index = index % segment_colors.size()
	material.albedo_color = segment_colors[color_index]
	material.roughness = 0.9
	material.metallic = 0.0

	# Add subtle grid pattern
	material.uv1_scale = Vector3(3, 6, 1)  # Stretch texture for tiling

	mesh_instance.material_override = material

	# Add collision shape
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(12.0, 1.0, SEGMENT_LENGTH)
	collision.shape = shape
	collision.position.y = -0.5  # Lower it a bit

	segment.add_child(mesh_instance)
	segment.add_child(collision)

	return segment

func create_lane_markers():
	"""Create visual markers to show the lanes"""
	var lane_positions = [-LANE_WIDTH, 0.0, LANE_WIDTH]

	for segment_idx in range(NUM_SEGMENTS):
		for lane_idx in range(2):  # Only 2 divider lines needed for 3 lanes
			var marker = create_lane_line()
			var x_pos = -LANE_WIDTH + (lane_idx + 1) * LANE_WIDTH  # At -1.5 and 1.5
			marker.position = Vector3(x_pos, 0.1, -segment_idx * SEGMENT_LENGTH)
			add_child(marker)

func create_lane_line() -> MeshInstance3D:
	"""Create a dashed line to mark lanes"""
	var line = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(0.1, 0.05, SEGMENT_LENGTH)
	line.mesh = box_mesh

	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.8, 0.8, 0.8, 0.5)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	line.material_override = material

	return line

func create_boundaries():
	"""Create walls on the sides to keep player in bounds"""
	for side in [-1, 1]:
		for i in range(NUM_SEGMENTS):
			var wall = create_boundary_wall()
			wall.position = Vector3(side * 6.5, 2, -i * SEGMENT_LENGTH)
			add_child(wall)

func create_boundary_wall() -> StaticBody3D:
	"""Create a boundary wall segment"""
	var wall = StaticBody3D.new()

	var mesh_instance = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(1.0, 4.0, SEGMENT_LENGTH)
	mesh_instance.mesh = box_mesh

	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.3, 0.3, 0.4)
	material.roughness = 0.8
	mesh_instance.material_override = material

	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(1.0, 4.0, SEGMENT_LENGTH)
	collision.shape = shape

	wall.add_child(mesh_instance)
	wall.add_child(collision)

	return wall

func _process(delta):
	"""Scroll the ground segments"""
	for segment in ground_segments:
		segment.position.z += SCROLL_SPEED * delta

		# Reset segment when it goes past the player
		if segment.position.z > SEGMENT_LENGTH:
			segment.position.z -= NUM_SEGMENTS * SEGMENT_LENGTH
