extends Node
class_name ViewAdapter

## View-specific logic adapter
## Handles spawning positions, movement interpretation, and gameplay adjustments
## based on the current camera perspective

# ============================================================================
# View Mode Integration
# ============================================================================

var camera_controller: CameraController
var view_mode: CameraController.ViewMode:
	get:
		return camera_controller.view_mode if camera_controller else CameraController.ViewMode.THIRD_PERSON

# ============================================================================
# Initialization
# ============================================================================

func _init(cam_controller: CameraController = null):
	camera_controller = cam_controller

func set_camera_controller(cam_controller: CameraController):
	camera_controller = cam_controller

# ============================================================================
# Spawn Position Adaptation
# ============================================================================

func get_spawn_distance() -> float:
	"""Get spawn distance based on view mode"""
	match view_mode:
		CameraController.ViewMode.FIRST_PERSON:
			return 30.0  # Closer spawning for FPS
		CameraController.ViewMode.THIRD_PERSON:
			return 40.0  # Standard distance
		CameraController.ViewMode.TOP_DOWN:
			return 35.0  # Medium distance for overhead view
		CameraController.ViewMode.SIDE_VIEW:
			return 45.0  # Further for side view to see ahead
		CameraController.ViewMode.FIXED_ANGLE:
			return 40.0  # Standard distance
		_:
			return 40.0

func get_lane_positions() -> Array[float]:
	"""Get lane X positions based on view mode"""
	match view_mode:
		CameraController.ViewMode.SIDE_VIEW:
			# Side view uses Y positions instead of X (vertical lanes)
			return [1.0, 3.0, 5.0]
		_:
			# Standard horizontal lanes
			return [-3.0, 0.0, 3.0]

func get_spawn_position(lane_index: int, row_index: int = 1) -> Vector3:
	"""Get world position for spawning based on view and lane"""
	var lanes = get_lane_positions()
	var x_pos = lanes[clamp(lane_index, 0, lanes.size() - 1)]
	var z_pos = -get_spawn_distance()

	match view_mode:
		CameraController.ViewMode.SIDE_VIEW:
			# For side view, spawn on a vertical plane
			return Vector3(-get_spawn_distance(), x_pos, 0)
		CameraController.ViewMode.TOP_DOWN:
			# Top-down uses standard X/Z grid
			return Vector3(x_pos, 0, z_pos)
		_:
			# Standard 3D positioning
			return Vector3(x_pos, 0, z_pos)

func get_row_positions() -> Array[float]:
	"""Get row Z positions based on view mode"""
	match view_mode:
		CameraController.ViewMode.TOP_DOWN:
			# More rows for top-down strategic gameplay
			return [-10.0, -6.0, -2.0, 2.0, 6.0, 10.0]
		CameraController.ViewMode.SIDE_VIEW:
			# No rows in side view (it's 2D on XY plane)
			return [0.0]
		_:
			# Standard rows
			return [-8.0, -5.0, -2.0, 1.0]

# ============================================================================
# Movement Adaptation
# ============================================================================

func interpret_movement_input(input_direction: Vector2) -> Dictionary:
	"""Interpret input based on view mode and return movement intent
	Returns: {lane_change: int, row_change: int, special_action: String}"""
	var result = {
		"lane_change": 0,  # -1 = left, 0 = none, 1 = right
		"row_change": 0,   # -1 = back, 0 = none, 1 = forward
		"special_action": ""
	}

	match view_mode:
		CameraController.ViewMode.FIRST_PERSON, CameraController.ViewMode.THIRD_PERSON:
			# Standard lane-based controls
			result.lane_change = int(sign(input_direction.x))
			result.row_change = int(sign(input_direction.y))

		CameraController.ViewMode.TOP_DOWN:
			# Top-down: more freedom of movement
			result.lane_change = int(sign(input_direction.x))
			result.row_change = int(sign(input_direction.y))

		CameraController.ViewMode.SIDE_VIEW:
			# Side view: only vertical movement matters (jumping handled separately)
			result.lane_change = int(sign(input_direction.y))  # Up/down becomes lanes
			result.row_change = 0  # No row movement in 2D

		CameraController.ViewMode.FIXED_ANGLE:
			# Fixed angle: adjust input based on camera angle
			result.lane_change = int(sign(input_direction.x))
			result.row_change = int(sign(input_direction.y))

	return result

func get_movement_direction_world(input_direction: Vector2, player_forward: Vector3 = Vector3.FORWARD) -> Vector3:
	"""Convert 2D input to 3D world direction based on view"""
	match view_mode:
		CameraController.ViewMode.FIRST_PERSON:
			# Relative to player facing direction
			return Vector3(input_direction.x, 0, -input_direction.y).normalized()

		CameraController.ViewMode.SIDE_VIEW:
			# Only Y movement in side view
			return Vector3(0, input_direction.y, 0).normalized()

		_:
			# Standard world-space movement
			return Vector3(input_direction.x, 0, -input_direction.y).normalized()

# ============================================================================
# Obstacle Visibility Adaptation
# ============================================================================

func get_visibility_distance() -> float:
	"""Get distance at which obstacles should be visible/active"""
	match view_mode:
		CameraController.ViewMode.FIRST_PERSON:
			return 35.0
		CameraController.ViewMode.THIRD_PERSON:
			return 50.0
		CameraController.ViewMode.TOP_DOWN:
			return 45.0
		CameraController.ViewMode.SIDE_VIEW:
			return 55.0
		_:
			return 45.0

func should_show_obstacle_warnings() -> bool:
	"""Whether to show visual warnings for upcoming obstacles"""
	match view_mode:
		CameraController.ViewMode.FIRST_PERSON:
			return true  # Need more warnings in FPS
		CameraController.ViewMode.THIRD_PERSON:
			return false  # Can see obstacles clearly
		CameraController.ViewMode.TOP_DOWN:
			return false  # Full view of playfield
		CameraController.ViewMode.SIDE_VIEW:
			return false  # Clear side view
		_:
			return false

# ============================================================================
# Gameplay Adjustments
# ============================================================================

func get_difficulty_multiplier() -> float:
	"""Adjust difficulty based on view mode (some views are harder)"""
	match view_mode:
		CameraController.ViewMode.FIRST_PERSON:
			return 0.85  # Slightly easier due to limited visibility
		CameraController.ViewMode.THIRD_PERSON:
			return 1.0  # Standard difficulty
		CameraController.ViewMode.TOP_DOWN:
			return 1.15  # Slightly harder with full view
		CameraController.ViewMode.SIDE_VIEW:
			return 1.0  # Standard for 2D gameplay
		_:
			return 1.0

func get_spawn_pattern_type() -> String:
	"""Get preferred spawn pattern type for this view"""
	match view_mode:
		CameraController.ViewMode.TOP_DOWN:
			return "grid"  # Grid patterns work well top-down
		CameraController.ViewMode.SIDE_VIEW:
			return "vertical"  # Vertical patterns for side view
		_:
			return "lane"  # Lane-based patterns

func supports_free_movement() -> bool:
	"""Whether this view supports free 3D movement vs lane-based"""
	match view_mode:
		CameraController.ViewMode.TOP_DOWN:
			return true  # Can move freely on grid
		_:
			return false  # Lane-based movement

func get_ui_layout() -> String:
	"""Get recommended UI layout for this view"""
	match view_mode:
		CameraController.ViewMode.FIRST_PERSON:
			return "fps"  # Minimal HUD, crosshair
		CameraController.ViewMode.TOP_DOWN:
			return "strategy"  # More information panels
		CameraController.ViewMode.SIDE_VIEW:
			return "platformer"  # Side-oriented HUD
		_:
			return "standard"  # Standard corner HUD

# ============================================================================
# Collision & Physics Adaptation
# ============================================================================

func get_collision_check_mode() -> String:
	"""How to check collisions based on view"""
	match view_mode:
		CameraController.ViewMode.SIDE_VIEW:
			return "2d"  # Check only X and Y
		_:
			return "3d"  # Full 3D collision checking

func adjust_collision_layers(base_layer: int) -> int:
	"""Adjust collision layers based on view requirements"""
	# Could add view-specific collision layers if needed
	return base_layer

# ============================================================================
# Visual Feedback Adaptation
# ============================================================================

func get_effect_scale() -> float:
	"""Scale for particle effects based on camera distance"""
	match view_mode:
		CameraController.ViewMode.FIRST_PERSON:
			return 0.7  # Smaller effects up close
		CameraController.ViewMode.TOP_DOWN:
			return 1.5  # Larger effects for overhead view
		_:
			return 1.0

func should_show_lane_markers() -> bool:
	"""Whether to show visual lane markers"""
	match view_mode:
		CameraController.ViewMode.TOP_DOWN:
			return true  # Helpful for grid navigation
		CameraController.ViewMode.SIDE_VIEW:
			return true  # Show vertical lanes
		_:
			return false  # Not needed in other views

# ============================================================================
# Input Sensitivity Adaptation
# ============================================================================

func get_input_deadzone() -> float:
	"""Deadzone for analog input based on view precision needs"""
	match view_mode:
		CameraController.ViewMode.FIRST_PERSON:
			return 0.15  # More precise
		CameraController.ViewMode.TOP_DOWN:
			return 0.2  # Less sensitive for strategic movement
		_:
			return 0.1  # Standard

func get_movement_speed_multiplier() -> float:
	"""Adjust movement speed perception based on view"""
	match view_mode:
		CameraController.ViewMode.SIDE_VIEW:
			return 0.8  # Feels faster in 2D, slow down a bit
		CameraController.ViewMode.TOP_DOWN:
			return 1.1  # Feels slower from above, speed up
		_:
			return 1.0

# ============================================================================
# Helper Methods
# ============================================================================

func world_to_screen_priority(world_pos: Vector3) -> float:
	"""Get rendering/update priority based on screen position
	Returns 0.0-1.0 where 1.0 is highest priority"""
	if not camera_controller or not camera_controller.camera:
		return 0.5

	# Objects closer to camera center are higher priority
	var cam = camera_controller.camera
	var screen_pos = cam.unproject_position(world_pos)
	var viewport_size = cam.get_viewport().get_visible_rect().size
	var center = viewport_size / 2.0

	var dist_from_center = screen_pos.distance_to(center)
	var max_dist = viewport_size.length() / 2.0

	return 1.0 - clamp(dist_from_center / max_dist, 0.0, 1.0)

func is_position_in_gameplay_area(pos: Vector3) -> bool:
	"""Check if a position is in the active gameplay area for this view"""
	var spawn_dist = get_spawn_distance()

	match view_mode:
		CameraController.ViewMode.SIDE_VIEW:
			return pos.x > -spawn_dist and pos.x < 20.0
		_:
			return pos.z > -spawn_dist and pos.z < 20.0

# ============================================================================
# Debug Information
# ============================================================================

func get_debug_info() -> Dictionary:
	"""Get debug information about current view adaptation"""
	return {
		"view_mode": CameraController.ViewMode.keys()[view_mode] if camera_controller else "NONE",
		"spawn_distance": get_spawn_distance(),
		"visibility_distance": get_visibility_distance(),
		"difficulty_mult": get_difficulty_multiplier(),
		"movement_type": "free" if supports_free_movement() else "lane",
		"spawn_pattern": get_spawn_pattern_type(),
		"ui_layout": get_ui_layout()
	}
