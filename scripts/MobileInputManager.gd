extends Node

## Mobile Input Manager for Android RPG
## Handles touch gestures, haptic feedback, and mobile-optimized controls

signal gesture_detected(gesture_type: GestureType, position: Vector2)
signal haptic_requested(intensity: float, duration: float)

# Combat-specific signals
signal combat_gesture_detected(gesture_type: GestureType, position: Vector2)
signal dodge_gesture(direction: String)
signal block_gesture_started()
signal block_gesture_ended()
signal dash_gesture()

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

# Combat gesture settings
@export var combat_mode_enabled: bool = false
@export var dodge_swipe_threshold: float = 80.0
@export var dash_swipe_threshold: float = 120.0
@export var block_hold_threshold: float = 0.3

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

# Combat state tracking
var is_in_combat: bool = false
var block_gesture_active: bool = false
var block_start_time: float = 0.0

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
			
			# Handle combat touch start
			handle_combat_touch_start(event.position)
		
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
			
			# Handle combat touch end
			if touch_id == 0:
				handle_combat_touch_end(event.position, touch_duration)
			
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
	var swipe_distance = swipe_vector.length()
	if swipe_distance < swipe_threshold:
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
	
	# Emit standard gesture
	emit_signal("gesture_detected", gesture_type, position)
	
	# Handle combat-specific gestures if in combat mode
	if combat_mode_enabled:
		handle_combat_gesture(gesture_type, swipe_distance, position)
	
	trigger_haptic_feedback(0.3, 0.1)

func _process(delta):
	# Handle long press detection for touch
	if is_touching:
		long_press_timer += delta
		if long_press_timer >= long_press_duration and active_touches.size() == 1:
			# Long press detected, but don't emit yet - wait for release
			pass
		
		# Handle combat block gesture timing
		if combat_mode_enabled and not block_gesture_active:
			var current_time = Time.get_unix_time_from_system()
			var hold_duration = current_time - block_start_time
			if hold_duration >= block_hold_threshold:
				start_block_gesture()
	
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

# Combat-specific gesture handling

func handle_combat_gesture(gesture_type: GestureType, swipe_distance: float, position: Vector2):
	"""Handle combat-specific gesture interpretation"""
	match gesture_type:
		GestureType.SWIPE_LEFT:
			emit_signal("dodge_gesture", "left")
			emit_signal("combat_gesture_detected", gesture_type, position)
			trigger_combat_haptic_feedback("dodge")
			print("Combat: Left dodge gesture detected")
		
		GestureType.SWIPE_RIGHT:
			emit_signal("dodge_gesture", "right")
			emit_signal("combat_gesture_detected", gesture_type, position)
			trigger_combat_haptic_feedback("dodge")
			print("Combat: Right dodge gesture detected")
		
		GestureType.SWIPE_DOWN:
			emit_signal("dodge_gesture", "backward")
			emit_signal("combat_gesture_detected", gesture_type, position)
			trigger_combat_haptic_feedback("dodge")
			print("Combat: Backward dodge gesture detected")
		
		GestureType.SWIPE_UP:
			# Swipe up now triggers dash forward instead of jump
			if swipe_distance >= dash_swipe_threshold:
				emit_signal("dash_gesture")
				emit_signal("combat_gesture_detected", gesture_type, position)
				trigger_combat_haptic_feedback("dash")
				print("Combat: Forward dash gesture detected")

func handle_combat_touch_start(position: Vector2):
	"""Handle touch start for combat actions"""
	if not combat_mode_enabled:
		return
	
	# Start potential block gesture
	block_start_time = Time.get_unix_time_from_system()

func handle_combat_touch_end(position: Vector2, duration: float):
	"""Handle touch end for combat actions"""
	if not combat_mode_enabled:
		return
	
	# Check if this was a block gesture (hold)
	if duration >= block_hold_threshold and not block_gesture_active:
		# This was a tap, not a hold - end block if active
		if block_gesture_active:
			end_block_gesture()

func start_block_gesture():
	"""Start block gesture"""
	if block_gesture_active:
		return
	
	block_gesture_active = true
	emit_signal("block_gesture_started")
	trigger_combat_haptic_feedback("block_start")
	print("Combat: Block gesture started")

func end_block_gesture():
	"""End block gesture"""
	if not block_gesture_active:
		return
	
	block_gesture_active = false
	emit_signal("block_gesture_ended")
	trigger_combat_haptic_feedback("block_end")
	print("Combat: Block gesture ended")

func trigger_combat_haptic_feedback(action_type: String):
	"""Trigger haptic feedback for combat actions"""
	if not haptic_enabled:
		return
	
	var intensity: float
	var duration: float
	
	match action_type:
		"dodge":
			intensity = 0.3
			duration = 0.1
		"dash":
			intensity = 0.4
			duration = 0.15
		"block_start":
			intensity = 0.5
			duration = 0.2
		"block_end":
			intensity = 0.3
			duration = 0.1
		"perfect_dodge":
			intensity = 0.7
			duration = 0.25
		"successful_block":
			intensity = 0.8
			duration = 0.3
		_:
			intensity = 0.2
			duration = 0.05
	
	trigger_haptic_feedback(intensity, duration)

func set_combat_mode(enabled: bool):
	"""Enable or disable combat mode"""
	combat_mode_enabled = enabled
	if enabled:
		print("Combat mode enabled - gestures will trigger combat actions")
	else:
		print("Combat mode disabled - gestures will trigger normal movement")
		# End any active block gesture
		if block_gesture_active:
			end_block_gesture()

func is_combat_mode_enabled() -> bool:
	"""Check if combat mode is enabled"""
	return combat_mode_enabled

func create_touch_zone_indicators():
	"""Create visual indicators for touch zones (to be called by UI system)"""
	# This will be implemented by the UI system to show touch zones
	print("Touch zone indicators requested")

func update_gesture_feedback(gesture_type: GestureType, position: Vector2):
	"""Update visual feedback for gesture recognition"""
	# This will be implemented by the UI system to show gesture feedback
	print("Gesture feedback update: ", gesture_type, " at ", position)