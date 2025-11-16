extends Control

## Demo Launcher
## Simple launcher to choose between game and gesture demo

var background_music_player: AudioStreamPlayer

func _ready():
	setup_launcher_ui()
	setup_background_music()

func setup_background_music():
	# Create AudioStreamPlayer for background music
	background_music_player = AudioStreamPlayer.new()
	background_music_player.name = "LauncherMusicPlayer"
	
	# Load music file
	var music_stream = load("res://audio/chiptunes awesomeness.mp3")
	if music_stream:
		background_music_player.stream = music_stream
		background_music_player.volume_db = linear_to_db(0.3)  # Quieter for launcher
		
		# Set loop
		if music_stream is AudioStreamMP3:
			music_stream.loop = true
		
		# Add to scene and play
		add_child(background_music_player)
		background_music_player.play()
		print("🎵 Launcher music started")
	else:
		print("❌ Could not load launcher music")

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

	# Combat level button
	var combat_button = Button.new()
	combat_button.text = "⚔️ Combat Level (Multi-Enemy)"
	combat_button.custom_minimum_size = Vector2(300, 50)
	combat_button.pressed.connect(_on_combat_level_button_pressed)
	button_container.add_child(combat_button)
	
	# Instructions
	var instructions = Label.new()
	instructions.text = """🎵 Background music is now playing!

Mouse Gesture Controls:
• Left Click + Drag: Swipe gestures
• Left Click (Quick): Tap
• Left Click (Hold 0.5s): Long press
• Right Click: Two-finger tap

Game Controls: M = toggle music, +/- = volume"""
	instructions.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instructions.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	instructions.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	instructions.position.y = -140
	instructions.size.y = 120
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

func _on_combat_level_button_pressed():
	print("Loading combat level...")
	get_tree().change_scene_to_file("res://scenes/CombatLevel.tscn")

func _input(event):
	# Music controls
	if event.is_action_pressed("ui_accept") and Input.is_key_pressed(KEY_M):
		toggle_music()
	elif event.is_action_pressed("ui_accept") and Input.is_key_pressed(KEY_EQUAL):
		adjust_volume(0.1)
	elif event.is_action_pressed("ui_accept") and Input.is_key_pressed(KEY_MINUS):
		adjust_volume(-0.1)

func toggle_music():
	if background_music_player:
		if background_music_player.playing:
			background_music_player.stop()
			print("🎵 Launcher music stopped")
		else:
			background_music_player.play()
			print("🎵 Launcher music started")

func adjust_volume(adjustment: float):
	if background_music_player:
		var current_linear = db_to_linear(background_music_player.volume_db)
		var new_linear = clamp(current_linear + adjustment, 0.0, 1.0)
		background_music_player.volume_db = linear_to_db(new_linear)
		print("🎵 Launcher music volume: ", int(new_linear * 100), "%")
