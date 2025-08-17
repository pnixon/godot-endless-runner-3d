extends Node

## Mobile Input Test Script
## Simple test to verify mobile input functionality

var status_label: Label

func _ready():
	print("Mobile Input Test initialized")
	
	# Find status label if it exists
	await get_tree().process_frame
	status_label = get_node_or_null("../UI/StatusLabel")
	
	# Connect to mobile input manager if available
	if MobileInputManager:
		MobileInputManager.gesture_detected.connect(_on_gesture_detected)
		print("Connected to MobileInputManager")
		
		# Check if mouse emulation is available
		if MobileInputManager.get_mouse_emulation_enabled() and not MobileInputManager.is_mobile_platform():
			update_status("Mouse emulation ready! Try gestures with mouse.")
		else:
			update_status("Mobile input system ready!")
	else:
		update_status("MobileInputManager not found")
	
	# Test device capabilities
	print("Platform: ", OS.get_name())
	print("Has mobile feature: ", OS.has_feature("mobile"))
	print("Screen size: ", DisplayServer.screen_get_size())
	print("Screen DPI: ", DisplayServer.screen_get_dpi())
	
	# Print mouse emulation instructions for desktop
	if not OS.has_feature("mobile"):
		print("\n=== MOUSE EMULATION CONTROLS ===")
		print("Left click + drag: Swipe gestures")
		print("Left click (quick): Tap")
		print("Left click (hold 0.5s): Long press")
		print("Right click: Two-finger tap")
		print("=================================")

func update_status(text: String):
	if status_label:
		status_label.text = text

func _on_gesture_detected(gesture_type: MobileInputManager.GestureType, position: Vector2):
	var gesture_name = ""
	match gesture_type:
		MobileInputManager.GestureType.SWIPE_LEFT:
			gesture_name = "SWIPE_LEFT"
		MobileInputManager.GestureType.SWIPE_RIGHT:
			gesture_name = "SWIPE_RIGHT"
		MobileInputManager.GestureType.SWIPE_UP:
			gesture_name = "SWIPE_UP"
		MobileInputManager.GestureType.SWIPE_DOWN:
			gesture_name = "SWIPE_DOWN"
		MobileInputManager.GestureType.TAP:
			gesture_name = "TAP"
		MobileInputManager.GestureType.LONG_PRESS:
			gesture_name = "LONG_PRESS"
		MobileInputManager.GestureType.TWO_FINGER_TAP:
			gesture_name = "TWO_FINGER_TAP"
	
	var message = "Detected: " + gesture_name + " at " + str(position)
	print("Gesture detected: ", gesture_name, " at position: ", position)
	update_status(message)

func _input(event):
	# Test input action detection
	if event.is_action_pressed("swipe_left"):
		print("Swipe left action detected!")
	elif event.is_action_pressed("swipe_right"):
		print("Swipe right action detected!")
	elif event.is_action_pressed("swipe_up"):
		print("Swipe up action detected!")
	elif event.is_action_pressed("swipe_down"):
		print("Swipe down action detected!")
	elif event.is_action_pressed("tap"):
		print("Tap action detected!")
	elif event.is_action_pressed("long_press"):
		print("Long press action detected!")
	elif event.is_action_pressed("two_finger_tap"):
		print("Two finger tap action detected!")