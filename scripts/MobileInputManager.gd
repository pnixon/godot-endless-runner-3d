extends Node

## Mobile Input Manager for Android RPG
## Handles touch gestures, haptic feedback, and mobile-optimized controls

signal gesture_detected(gesture_type: GestureType, position: Vector2)
signal haptic_requested(intensity: float, duration: float)

enum GestureType { 
	SWIPE_LEFT, 
	SWIPE_RIGHT, 
	SWIPE_UP, 
	SWIPE_DOWN, 
	TAP, 
	LONG_PRESS, 
	TWO_FINGER_TAP 
}

# Touch gesture settings
@export var gesture_sensitivity: float = 50.0
@export var long_press_duration: float = 0.5
@export var swipe_threshold: float = 100.0
@export var haptic_enabled: bool = true
@export var mouse_emulation_enabled: bool = true

# Internal state
var touch_start_position: Vector2
var touch_start_time: float
var is_touching: bool = false
var long_press_timer: float = 0.0
var active_touches: Dictionary = {}

# Mouse emulation state
var mouse_start_position: Vector2
var mouse_start_time: float
var is_mouse_pressed: bool = false
var mouse_long_press_timer: float = 0.0
var right_mouse_pressed: bool = false

func _ready():
	setup_touch_controls()
	
func setup_touch_controls():
	# Enable multitouch for gesture recognition
	Input.set_use_accumulated_input(false)
	
	# Connect to input events
	set_process_input(true)
	
	print("Mobile input system initialized")
	
	# Enable mouse emulation for desktop testing
	if not is_mobile_platform() and mouse_emulation_enabled:
		print("Mouse gesture emulation enabled:")
		print("  - Left click + drag: Swipe gestures")
		print("  - Left click (short): Tap")
		print("  - Left click (hold 0.5s): Long press")
		print("  - Right click: Two-finger tap")

func _input(event):
	if event is InputEventScreenTouch:
		handle_touch_event(event)
	elif event is InputEventScreenDrag:
		handle_drag_event(event)
	elif mouse_emulation_enabled and not is_mobile_platform():
		# Mouse emulation for desktop testing
		if event is InputEventMouseButton:
			handle_mouse_button_event(event)
		elif event is InputEventMouseMotion:
			handle_mouse_motion_event(event)

func handle_touch_event(event: InputEventScreenTouch):
	var touch_id = event.index
	
	if event.pressed:
		# Touch started
		active_touches[touch_id] = {
			"start_position": event.position,
			"start_time": Time.get_unix_time_from_system(),
			"current_position": event.position
		}
		
		if touch_id == 0:  # Primary touch
			touch_start_position = event.position
			touch_start_time = Time.get_unix_time_from_system()
			is_touching = true
			long_press_timer = 0.0
		
		# Check for two-finger tap
		if active_touches.size() == 2:
			emit_signal("gesture_detected", GestureType.TWO_FINGER_TAP, event.position)
			trigger_haptic_feedback(0.3, 0.1)
	else:
		# Touch ended
		if touch_id in active_touches:
			var touch_data = active_touches[touch_id]
			var touch_duration = Time.get_unix_time_from_system() - touch_data["start_time"]
			var touch_distance = touch_data["start_position"].distance_to(event.position)
			
			# Determine gesture type
			if touch_distance < gesture_sensitivity:
				if touch_duration >= long_press_duration:
					emit_signal("gesture_detected", GestureType.LONG_PRESS, event.position)
					trigger_haptic_feedback(0.5, 0.2)
				else:
					emit_signal("gesture_detected", GestureType.TAP, event.position)
					trigger_haptic_feedback(0.2, 0.05)
			else:
				# Swipe gesture
				var swipe_direction = event.position - touch_data["start_position"]
				detect_swipe_direction(swipe_direction, event.position)
			
			active_touches.erase(touch_id)
		
		if touch_id == 0:
			is_touching = false

func handle_drag_event(event: InputEventScreenDrag):
	var touch_id = event.index
	if touch_id in active_touches:
		active_touches[touch_id]["current_position"] = event.position

func detect_swipe_direction(swipe_vector: Vector2, position: Vector2):
	if swipe_vector.length() < swipe_threshold:
		return
	
	var normalized_swipe = swipe_vector.normalized()
	var gesture_type: GestureType
	
	# Determine primary swipe direction
	if abs(normalized_swipe.x) > abs(normalized_swipe.y):
		# Horizontal swipe
		if normalized_swipe.x > 0:
			gesture_type = GestureType.SWIPE_RIGHT
		else:
			gesture_type = GestureType.SWIPE_LEFT
	else:
		# Vertical swipe
		if normalized_swipe.y > 0:
			gesture_type = GestureType.SWIPE_DOWN
		else:
			gesture_type = GestureType.SWIPE_UP
	
	emit_signal("gesture_detected", gesture_type, position)
	trigger_haptic_feedback(0.3, 0.1)

func _process(delta):
	# Handle long press detection for touch
	if is_touching:
		long_press_timer += delta
		if long_press_timer >= long_press_duration and active_touches.size() == 1:
			# Long press detected, but don't emit yet - wait for release
			pass
	
	# Handle long press detection for mouse emulation
	if is_mouse_pressed and mouse_emulation_enabled:
		mouse_long_press_timer += delta

func trigger_haptic_feedback(intensity: float, duration: float):
	if haptic_enabled and OS.has_feature("mobile"):
		emit_signal("haptic_requested", intensity, duration)
		# Use Godot's built-in vibration for Android
		if OS.get_name() == "Android":
			Input.vibrate_handheld(int(duration * 1000))  # Convert to milliseconds

func enable_haptic_feedback(enabled: bool):
	haptic_enabled = enabled

func get_gesture_sensitivity() -> float:
	return gesture_sensitivity

func set_gesture_sensitivity(sensitivity: float):
	gesture_sensitivity = clamp(sensitivity, 10.0, 200.0)

func is_mobile_platform() -> bool:
	return OS.has_feature("mobile") or OS.get_name() in ["Android", "iOS"]

func get_screen_size() -> Vector2:
	return get_viewport().get_visible_rect().size

# Mouse emulation functions for desktop testing
func handle_mouse_button_event(event: InputEventMouseButton):
	if event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# Left mouse button pressed - start gesture
			mouse_start_position = event.position
			mouse_start_time = Time.get_unix_time_from_system()
			is_mouse_pressed = true
			mouse_long_press_timer = 0.0
			print("Mouse gesture started at: ", event.position)
		else:
			# Left mouse button released - end gesture
			if is_mouse_pressed:
				var mouse_duration = Time.get_unix_time_from_system() - mouse_start_time
				var mouse_distance = mouse_start_position.distance_to(event.position)
				
				# Determine gesture type
				if mouse_distance < gesture_sensitivity:
					if mouse_duration >= long_press_duration:
						emit_signal("gesture_detected", GestureType.LONG_PRESS, event.position)
						trigger_haptic_feedback(0.5, 0.2)
						print("Mouse long press detected")
					else:
						emit_signal("gesture_detected", GestureType.TAP, event.position)
						trigger_haptic_feedback(0.2, 0.05)
						print("Mouse tap detected")
				else:
					# Mouse swipe gesture
					var swipe_direction = event.position - mouse_start_position
					detect_swipe_direction(swipe_direction, event.position)
					print("Mouse swipe detected: ", swipe_direction)
				
				is_mouse_pressed = false
	
	elif event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed:
			# Right mouse button - simulate two-finger tap
			right_mouse_pressed = true
			emit_signal("gesture_detected", GestureType.TWO_FINGER_TAP, event.position)
			trigger_haptic_feedback(0.3, 0.1)
			print("Mouse right-click (two-finger tap) detected")
		else:
			right_mouse_pressed = false

func handle_mouse_motion_event(event: InputEventMouseMotion):
	# Update current position for drag detection
	if is_mouse_pressed:
		# Could be used for real-time drag feedback if needed
		pass

func set_mouse_emulation_enabled(enabled: bool):
	mouse_emulation_enabled = enabled
	if enabled and not is_mobile_platform():
		print("Mouse gesture emulation enabled for desktop testing")
	else:
		print("Mouse gesture emulation disabled")

func get_mouse_emulation_enabled() -> bool:
	return mouse_emulation_enabled
