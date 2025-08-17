extends Control

## Demo Launcher
## Simple launcher to choose between game and gesture demo

func _ready():
	setup_launcher_ui()

func setup_launcher_ui():
	# Set up the control to fill the screen
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Create background
	var bg = ColorRect.new()
	bg.color = Color(0.15, 0.15, 0.25, 1.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	# Title
	var title = Label.new()
	title.text = "Legends of Aetherion - Demo Launcher"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	title.position.y = 50
	title.size.y = 50
	add_child(title)
	
	# Subtitle
	var subtitle = Label.new()
	subtitle.text = "Choose a demo to run:"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	subtitle.position.y = 120
	subtitle.size.y = 30
	add_child(subtitle)
	
	# Button container
	var button_container = VBoxContainer.new()
	button_container.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	button_container.position = Vector2(-150, -100)
	button_container.size = Vector2(300, 200)
	button_container.add_theme_constant_override("separation", 20)
	add_child(button_container)
	
	# Main game button
	var game_button = Button.new()
	game_button.text = "🎮 Main Game (3D Runner)"
	game_button.custom_minimum_size = Vector2(300, 50)
	game_button.pressed.connect(_on_game_button_pressed)
	button_container.add_child(game_button)
	
	# Mouse gesture demo button
	var gesture_button = Button.new()
	gesture_button.text = "🖱️ Mouse Gesture Demo"
	gesture_button.custom_minimum_size = Vector2(300, 50)
	gesture_button.pressed.connect(_on_gesture_demo_button_pressed)
	button_container.add_child(gesture_button)
	
	# Mobile input demo button
	var mobile_button = Button.new()
	mobile_button.text = "📱 Mobile Input Demo"
	mobile_button.custom_minimum_size = Vector2(300, 50)
	mobile_button.pressed.connect(_on_mobile_demo_button_pressed)
	button_container.add_child(mobile_button)
	
	# Instructions
	var instructions = Label.new()
	instructions.text = """Mouse Gesture Controls:
• Left Click + Drag: Swipe gestures
• Left Click (Quick): Tap
• Left Click (Hold 0.5s): Long press
• Right Click: Two-finger tap"""
	instructions.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instructions.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	instructions.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	instructions.position.y = -120
	instructions.size.y = 100
	add_child(instructions)

func _on_game_button_pressed():
	print("Loading main game...")
	get_tree().change_scene_to_file("res://scenes/Main3D.tscn")

func _on_gesture_demo_button_pressed():
	print("Loading mouse gesture demo...")
	get_tree().change_scene_to_file("res://scenes/MouseGestureDemo.tscn")

func _on_mobile_demo_button_pressed():
	print("Loading mobile input demo...")
	get_tree().change_scene_to_file("res://scenes/MobileInputDemo.tscn")