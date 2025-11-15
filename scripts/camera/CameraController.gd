extends Node3D
class_name CameraController

## Multi-perspective camera controller for endless runner
## Supports first-person, third-person, top-down, and side views

# ============================================================================
# Camera Modes
# ============================================================================

enum ViewMode {
	FIRST_PERSON,    ## First-person view (behind player eyes)
	THIRD_PERSON,    ## Third-person follow camera
	TOP_DOWN,        ## Overhead isometric view
	SIDE_VIEW,       ## 2.5D side-scrolling view
	FIXED_ANGLE,     ## Fixed camera angle (like classic arcade)
}

# ============================================================================
# Configuration
# ============================================================================

## Current camera mode
@export var view_mode: ViewMode = ViewMode.THIRD_PERSON

## Target to follow (usually the player)
@export var target: Node3D

## Camera smoothing speed (higher = more responsive)
@export var follow_smoothness: float = 10.0

## Enable smooth rotation transitions
@export var smooth_rotation: bool = true

## Enable camera shake
@export var enable_shake: bool = true

# View mode specific settings
@export_group("Third Person Settings")
@export var third_person_distance: float = 8.0
@export var third_person_height: float = 6.0
@export var third_person_angle: float = -35.0
@export var third_person_fov: float = 70.0

@export_group("First Person Settings")
@export var first_person_height_offset: float = 1.6
@export var first_person_forward_offset: float = 0.3
@export var first_person_fov: float = 90.0

@export_group("Top Down Settings")
@export var top_down_height: float = 20.0
@export var top_down_angle: float = -60.0
@export var top_down_fov: float = 60.0

@export_group("Side View Settings")
@export var side_view_distance: float = 15.0
@export var side_view_height: float = 3.0
@export var side_view_fov: float = 50.0

@export_group("Fixed Angle Settings")
@export var fixed_angle_position: Vector3 = Vector3(0, 12, 10)
@export var fixed_angle_rotation: Vector3 = Vector3(-45, 0, 0)
@export var fixed_angle_fov: float = 65.0

# ============================================================================
# Internal State
# ============================================================================

var camera: Camera3D
var shake_amount: float = 0.0
var shake_decay: float = 5.0
var original_position: Vector3
var target_position: Vector3
var target_rotation: Vector3

# ============================================================================
# Initialization
# ============================================================================

func _ready():
	# Create camera if it doesn't exist
	camera = get_node_or_null("Camera3D")
	if not camera:
		camera = Camera3D.new()
		camera.name = "Camera3D"
		add_child(camera)

	# Set initial camera mode
	apply_view_mode(view_mode)

	print("✓ CameraController initialized with mode: ", ViewMode.keys()[view_mode])

# ============================================================================
# Update Loop
# ============================================================================

func _process(delta):
	if not target or not camera:
		return

	# Update camera position based on view mode
	update_camera_position(delta)

	# Apply camera shake if active
	if shake_amount > 0:
		apply_camera_shake(delta)

func update_camera_position(delta: float):
	"""Update camera position and rotation based on current view mode"""
	match view_mode:
		ViewMode.FIRST_PERSON:
			update_first_person(delta)
		ViewMode.THIRD_PERSON:
			update_third_person(delta)
		ViewMode.TOP_DOWN:
			update_top_down(delta)
		ViewMode.SIDE_VIEW:
			update_side_view(delta)
		ViewMode.FIXED_ANGLE:
			update_fixed_angle(delta)

# ============================================================================
# View Mode Updates
# ============================================================================

func update_first_person(delta: float):
	"""First-person camera - attached to player's head"""
	# Position at player's eye level
	target_position = target.global_position
	target_position.y += first_person_height_offset
	target_position.z += first_person_forward_offset

	# Look forward
	target_rotation = Vector3(0, 0, 0)

	# Apply smoothly
	global_position = global_position.lerp(target_position, follow_smoothness * delta)

	if smooth_rotation:
		rotation_degrees = rotation_degrees.lerp(target_rotation, follow_smoothness * delta)
	else:
		rotation_degrees = target_rotation

func update_third_person(delta: float):
	"""Third-person camera - follows behind and above player"""
	# Position behind and above player
	target_position = target.global_position
	target_position.y += third_person_height
	target_position.z += third_person_distance

	# Look at player with downward angle
	target_rotation = Vector3(third_person_angle, 0, 0)

	# Apply smoothly
	global_position = global_position.lerp(target_position, follow_smoothness * delta)

	if smooth_rotation:
		rotation_degrees = rotation_degrees.lerp(target_rotation, follow_smoothness * delta)
	else:
		rotation_degrees = target_rotation

func update_top_down(delta: float):
	"""Top-down camera - overhead view"""
	# Position directly above player
	target_position = target.global_position
	target_position.y += top_down_height

	# Look down at an angle
	target_rotation = Vector3(top_down_angle, 0, 0)

	# Apply smoothly
	global_position = global_position.lerp(target_position, follow_smoothness * delta)

	if smooth_rotation:
		rotation_degrees = rotation_degrees.lerp(target_rotation, follow_smoothness * delta)
	else:
		rotation_degrees = target_rotation

func update_side_view(delta: float):
	"""Side view camera - 2.5D perspective"""
	# Position to the side of player
	target_position = target.global_position
	target_position.x += side_view_distance
	target_position.y += side_view_height

	# Look at player from the side
	var look_target = target.global_position
	look_target.y += 1.0  # Look at center of player

	# Calculate rotation to look at target
	var direction = (look_target - target_position).normalized()
	var look_rotation = Vector3.ZERO
	look_rotation.y = rad_to_deg(atan2(-direction.x, -direction.z))
	look_rotation.x = rad_to_deg(asin(direction.y))

	target_rotation = look_rotation

	# Apply smoothly
	global_position = global_position.lerp(target_position, follow_smoothness * delta)

	if smooth_rotation:
		rotation_degrees = rotation_degrees.lerp(target_rotation, follow_smoothness * delta)
	else:
		rotation_degrees = target_rotation

func update_fixed_angle(delta: float):
	"""Fixed angle camera - doesn't follow player position"""
	# Stay at fixed position
	target_position = fixed_angle_position
	target_rotation = fixed_angle_rotation

	# Apply directly (no smoothing needed for fixed camera)
	global_position = target_position
	rotation_degrees = target_rotation

# ============================================================================
# Camera Shake
# ============================================================================

func apply_camera_shake(delta: float):
	"""Apply random camera shake effect"""
	if not enable_shake:
		return

	# Random shake offset
	var shake_offset = Vector3(
		randf_range(-shake_amount, shake_amount),
		randf_range(-shake_amount, shake_amount),
		0
	)

	# Apply to camera
	camera.position = shake_offset

	# Decay shake over time
	shake_amount = lerp(shake_amount, 0.0, shake_decay * delta)

	# Reset camera position when shake is done
	if shake_amount < 0.01:
		shake_amount = 0.0
		camera.position = Vector3.ZERO

func trigger_shake(intensity: float = 0.3, duration: float = 0.2):
	"""Trigger a camera shake effect"""
	shake_amount = intensity

# ============================================================================
# View Mode Switching
# ============================================================================

func set_view_mode(new_mode: ViewMode):
	"""Switch to a different camera view mode"""
	view_mode = new_mode
	apply_view_mode(new_mode)
	print("Camera mode changed to: ", ViewMode.keys()[new_mode])

func apply_view_mode(mode: ViewMode):
	"""Apply settings for the current view mode"""
	if not camera:
		return

	match mode:
		ViewMode.FIRST_PERSON:
			camera.fov = first_person_fov
		ViewMode.THIRD_PERSON:
			camera.fov = third_person_fov
		ViewMode.TOP_DOWN:
			camera.fov = top_down_fov
		ViewMode.SIDE_VIEW:
			camera.fov = side_view_fov
		ViewMode.FIXED_ANGLE:
			camera.fov = fixed_angle_fov

func cycle_view_mode():
	"""Cycle to the next view mode"""
	var current_index = view_mode as int
	var next_index = (current_index + 1) % ViewMode.size()
	set_view_mode(next_index as ViewMode)

# ============================================================================
# Utility Methods
# ============================================================================

func look_at_target(target_node: Node3D):
	"""Make camera look at a specific target"""
	if camera:
		camera.look_at(target_node.global_position, Vector3.UP)

func set_target(new_target: Node3D):
	"""Set a new target for the camera to follow"""
	target = new_target
	print("Camera target set to: ", target.name if target else "none")

func get_camera() -> Camera3D:
	"""Get the camera node"""
	return camera

func is_position_visible(pos: Vector3) -> bool:
	"""Check if a 3D position is visible in the camera viewport"""
	if not camera:
		return false

	return camera.is_position_in_frustum(pos)

# ============================================================================
# Configuration Helpers
# ============================================================================

func configure_for_gameplay_style(style: String):
	"""Configure camera for specific gameplay styles"""
	match style.to_lower():
		"runner":
			set_view_mode(ViewMode.THIRD_PERSON)
			third_person_distance = 8.0
			third_person_height = 6.0
			third_person_angle = -35.0

		"racing":
			set_view_mode(ViewMode.THIRD_PERSON)
			third_person_distance = 12.0
			third_person_height = 5.0
			third_person_angle = -25.0
			follow_smoothness = 15.0

		"platformer":
			set_view_mode(ViewMode.SIDE_VIEW)
			side_view_distance = 15.0
			side_view_height = 3.0

		"shooter":
			set_view_mode(ViewMode.FIRST_PERSON)
			first_person_fov = 90.0

		"strategy":
			set_view_mode(ViewMode.TOP_DOWN)
			top_down_height = 25.0
			top_down_angle = -70.0

		_:
			set_view_mode(ViewMode.THIRD_PERSON)

# ============================================================================
# Debug
# ============================================================================

func _input(event):
	"""Debug input for testing different views"""
	if not OS.is_debug_build():
		return

	# Press V to cycle through view modes
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_V:
			cycle_view_mode()
