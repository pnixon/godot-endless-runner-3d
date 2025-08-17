extends Node

## Mobile Input Bridge
## Connects mobile gestures to existing game input actions

var mobile_input_manager: MobileInputManager
var haptic_controller: HapticController

func _ready():
	# Wait for autoloads to be ready
	await get_tree().process_frame
	
	mobile_input_manager = MobileInputManager
	haptic_controller = HapticController
	
	if mobile_input_manager:
		mobile_input_manager.gesture_detected.connect(_on_gesture_detected)
		print("Mobile input bridge connected")
	else:
		print("Warning: MobileInputManager not found")

func _on_gesture_detected(gesture_type: MobileInputManager.GestureType, position: Vector2):
	# Convert gestures to input actions
	match gesture_type:
		MobileInputManager.GestureType.SWIPE_LEFT:
			trigger_input_action("move_left")
			trigger_input_action("swipe_left")
			if haptic_controller:
				haptic_controller.on_lane_switch()
		
		MobileInputManager.GestureType.SWIPE_RIGHT:
			trigger_input_action("move_right")
			trigger_input_action("swipe_right")
			if haptic_controller:
				haptic_controller.on_lane_switch()
		
		MobileInputManager.GestureType.SWIPE_UP:
			trigger_input_action("jump")
			trigger_input_action("swipe_up")
			if haptic_controller:
				haptic_controller.on_jump()
		
		MobileInputManager.GestureType.SWIPE_DOWN:
			trigger_input_action("slide")
			trigger_input_action("swipe_down")
			if haptic_controller:
				haptic_controller.on_jump()  # Light feedback for slide
		
		MobileInputManager.GestureType.TAP:
			trigger_input_action("attack")
			trigger_input_action("tap")
			if haptic_controller:
				haptic_controller.play_haptic_pattern(HapticController.HapticPattern.LIGHT_TAP)
		
		MobileInputManager.GestureType.LONG_PRESS:
			trigger_input_action("long_press")
			if haptic_controller:
				haptic_controller.play_haptic_pattern(HapticController.HapticPattern.ABILITY_CHARGE)
		
		MobileInputManager.GestureType.TWO_FINGER_TAP:
			trigger_input_action("two_finger_tap")
			# Could be used for pause menu or special abilities
			if haptic_controller:
				haptic_controller.play_haptic_pattern(HapticController.HapticPattern.MEDIUM_BUMP)

func trigger_input_action(action_name: String):
	# Create and dispatch input event for the action
	var input_event = InputEventAction.new()
	input_event.action = action_name
	input_event.pressed = true
	Input.parse_input_event(input_event)
	
	# Also trigger release event after a short delay for tap-like actions
	if action_name in ["move_left", "move_right", "jump", "slide", "attack", "tap"]:
		await get_tree().create_timer(0.1).timeout
		input_event.pressed = false
		Input.parse_input_event(input_event)

func is_mobile_input_active() -> bool:
	return mobile_input_manager != null and mobile_input_manager.is_mobile_platform()

func get_mobile_input_manager() -> MobileInputManager:
	return mobile_input_manager

func get_haptic_controller() -> HapticController:
	return haptic_controller