extends Control

## Mouse Gesture Demo
## Demonstrates mouse-based gesture emulation for desktop testing

var gesture_history: Array[String] = []
var max_history: int = 10

@onready var history_label: Label
@onready var instructions_label: Label

func _ready():
	# Create UI elements
	setup_demo_ui()
	
	# Connect to mobile input manager
	if MobileInputManager:
		MobileInputManager.gesture_detected.connect(_on_gesture_detected)
		print("Mouse gesture demo connected to MobileInputManager")

func setup_demo_ui():
	# Set up the control to fill the screen
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Create background
	var bg = ColorRect.new()
	bg.color = Color(0.1, 0.1, 0.2, 1.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	# Title
	var title = Label.new()
	title.text = "Mouse Gesture Emulation Demo"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	title.position.y = 20
	title.size.y = 40
	add_child(title)
	
	# Instructions
	instructions_label = Label.new()
	instructions_label.text = """MOUSE CONTROLS:
• Left Click + Drag: Swipe gestures (try different directions)
• Left Click (Quick): Tap gesture
• Left Click (Hold 0.5s): Long press gesture  
• Right Click: Two-finger tap gesture

Try the gestures in this area!"""
	instructions_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instructions_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	instructions_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	instructions_label.position = Vector2(-200, -100)
	instructions_label.size = Vector2(400, 200)
	add_child(instructions_label)
	
	# Gesture history
	history_label = Label.new()
	history_label.text = "Gesture History:\n(Try some gestures!)"
	history_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	history_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	history_label.position.y = -150
	history_label.size.y = 130
	add_child(history_label)

func _on_gesture_detected(gesture_type: MobileInputManager.GestureType, position: Vector2):
	var gesture_name = ""
	var color_code = ""
	
	match gesture_type:
		MobileInputManager.GestureType.SWIPE_LEFT:
			gesture_name = "SWIPE LEFT"
			color_code = "[color=cyan]"
		MobileInputManager.GestureType.SWIPE_RIGHT:
			gesture_name = "SWIPE RIGHT"
			color_code = "[color=cyan]"
		MobileInputManager.GestureType.SWIPE_UP:
			gesture_name = "SWIPE UP"
			color_code = "[color=green]"
		MobileInputManager.GestureType.SWIPE_DOWN:
			gesture_name = "SWIPE DOWN"
			color_code = "[color=green]"
		MobileInputManager.GestureType.TAP:
			gesture_name = "TAP"
			color_code = "[color=yellow]"
		MobileInputManager.GestureType.LONG_PRESS:
			gesture_name = "LONG PRESS"
			color_code = "[color=orange]"
		MobileInputManager.GestureType.TWO_FINGER_TAP:
			gesture_name = "TWO-FINGER TAP"
			color_code = "[color=magenta]"
	
	# Add to history
	var timestamp = Time.get_datetime_string_from_system().split(" ")[1]  # Get time part
	var history_entry = "%s%s[/color] at %s" % [color_code, gesture_name, timestamp]
	gesture_history.append(history_entry)
	
	# Keep only recent gestures
	if gesture_history.size() > max_history:
		gesture_history.pop_front()
	
	# Update display
	update_history_display()
	
	# Visual feedback
	show_gesture_feedback(gesture_name, position)

func update_history_display():
	var history_text = "Gesture History:\n"
	for entry in gesture_history:
		history_text += "• " + entry + "\n"
	
	history_label.text = history_text

func show_gesture_feedback(gesture_name: String, position: Vector2):
	# Create temporary feedback label
	var feedback = Label.new()
	feedback.text = gesture_name
	feedback.position = position - Vector2(50, 10)
	feedback.size = Vector2(100, 20)
	feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback.add_theme_font_size_override("font_size", 16)
	feedback.add_theme_color_override("font_color", Color.WHITE)
	add_child(feedback)
	
	# Animate and remove
	var tween = create_tween()
	tween.parallel().tween_property(feedback, "position:y", feedback.position.y - 30, 1.0)
	tween.parallel().tween_property(feedback, "modulate:a", 0.0, 1.0)
	tween.tween_callback(feedback.queue_free)

func _gui_input(event):
	# Handle mouse input for visual feedback
	if event is InputEventMouseButton:
		if event.pressed:
			# Show click indicator
			show_click_indicator(event.position)

func show_click_indicator(pos: Vector2):
	# Create click indicator
	var indicator = ColorRect.new()
	indicator.color = Color.WHITE
	indicator.size = Vector2(4, 4)
	indicator.position = pos - Vector2(2, 2)
	add_child(indicator)
	
	# Animate
	var tween = create_tween()
	tween.parallel().tween_property(indicator, "size", Vector2(20, 20), 0.3)
	tween.parallel().tween_property(indicator, "position", pos - Vector2(10, 10), 0.3)
	tween.parallel().tween_property(indicator, "modulate:a", 0.0, 0.3)
	tween.tween_callback(indicator.queue_free)