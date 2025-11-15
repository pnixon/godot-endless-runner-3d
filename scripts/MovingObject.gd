extends Area3D
class_name MovingObject

# Base class for moving obstacles and collectibles
# Handles forward movement and cleanup

const MOVE_SPEED = 22.0  # Speed at which objects move toward player
const CLEANUP_DISTANCE = 15.0  # Distance past player before cleanup

func _ready():
	# Ensure object is in the right groups
	if not is_in_group("moving_objects"):
		add_to_group("moving_objects")

func _process(delta):
	# Move toward player (positive Z direction)
	position.z += MOVE_SPEED * delta

	# Clean up when past player
	if position.z > CLEANUP_DISTANCE:
		queue_free()
