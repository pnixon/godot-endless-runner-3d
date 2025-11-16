extends Control

## Tutorial Main Menu
## Demonstrates how to create a simple menu system using the modular components

# Menu state
enum MenuState {
	MAIN,
	MODE_SELECT,
	OPTIONS,
	CREDITS
}

var current_state: MenuState = MenuState.MAIN

# UI Elements (will be created programmatically)
var main_container: VBoxContainer = null
var title_label: Label = null
var button_container: VBoxContainer = null

# Buttons
var start_tutorial_button: Button = null
var play_runner_button: Button = null
var play_combat_button: Button = null
var mode_select_button: Button = null
var options_button: Button = null
var credits_button: Button = null
var quit_button: Button = null
var back_button: Button = null

# Mode selection
var mode_list_container: VBoxContainer = null

func _ready():
	print("=== Tutorial Main Menu ===")
	_setup_ui()
	_show_main_menu()

func _setup_ui():
	"""Create menu UI programmatically"""
	# Set background color
	var bg_panel = Panel.new()
	bg_panel.name = "Background"
	bg_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg_panel)

	# Create a ColorRect for better background
	var bg_color = ColorRect.new()
	bg_color.color = Color(0.1, 0.1, 0.15, 1.0)  # Dark blue
	bg_color.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg_color)

	# Main container (centered)
	main_container = VBoxContainer.new()
	main_container.name = "MainContainer"
	main_container.set_anchors_preset(Control.PRESET_CENTER)
	main_container.position = Vector2(400, 200)  # Adjust based on window size
	main_container.custom_minimum_size = Vector2(400, 0)
	add_child(main_container)

	# Title
	title_label = Label.new()
	title_label.name = "TitleLabel"
	title_label.text = "Modular Game Tutorial"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 48)
	title_label.add_theme_color_override("font_color", Color(1, 1, 0))  # Yellow
	main_container.add_child(title_label)

	# Spacer
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 40)
	main_container.add_child(spacer1)

	# Button container
	button_container = VBoxContainer.new()
	button_container.name = "ButtonContainer"
	main_container.add_child(button_container)

	# Create buttons
	_create_buttons()

	# Mode selection container (hidden initially)
	mode_list_container = VBoxContainer.new()
	mode_list_container.name = "ModeListContainer"
	mode_list_container.visible = false
	main_container.add_child(mode_list_container)

func _create_buttons():
	"""Create menu buttons"""
	# Start Tutorial button
	start_tutorial_button = _create_button("Start Tutorial Arena")
	start_tutorial_button.pressed.connect(_on_start_tutorial_pressed)
	button_container.add_child(start_tutorial_button)

	_add_button_spacer()

	# Play Runner Mode
	play_runner_button = _create_button("Play Runner Mode")
	play_runner_button.pressed.connect(_on_play_runner_pressed)
	button_container.add_child(play_runner_button)

	_add_button_spacer()

	# Play Combat Mode
	play_combat_button = _create_button("Play Combat Level")
	play_combat_button.pressed.connect(_on_play_combat_pressed)
	button_container.add_child(play_combat_button)

	_add_button_spacer()

	# Mode Select
	mode_select_button = _create_button("Game Mode Selection")
	mode_select_button.pressed.connect(_on_mode_select_pressed)
	button_container.add_child(mode_select_button)

	_add_button_spacer()

	# Options
	options_button = _create_button("Options")
	options_button.pressed.connect(_on_options_pressed)
	button_container.add_child(options_button)

	_add_button_spacer()

	# Credits
	credits_button = _create_button("Credits")
	credits_button.pressed.connect(_on_credits_pressed)
	button_container.add_child(credits_button)

	_add_button_spacer()

	# Quit
	quit_button = _create_button("Quit")
	quit_button.pressed.connect(_on_quit_pressed)
	button_container.add_child(quit_button)

	# Back button (hidden initially)
	back_button = _create_button("< Back")
	back_button.pressed.connect(_on_back_pressed)
	back_button.visible = false
	button_container.add_child(back_button)

func _create_button(text: String) -> Button:
	"""Helper to create styled button"""
	var button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(400, 50)
	button.add_theme_font_size_override("font_size", 24)

	# Style
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.2, 0.3, 0.5)
	style_normal.border_color = Color(0.5, 0.6, 0.8)
	style_normal.border_width_all = 2
	style_normal.corner_radius_all = 8

	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color(0.3, 0.4, 0.6)
	style_hover.border_color = Color(0.7, 0.8, 1.0)
	style_hover.border_width_all = 3
	style_hover.corner_radius_all = 8

	button.add_theme_stylebox_override("normal", style_normal)
	button.add_theme_stylebox_override("hover", style_hover)
	button.add_theme_stylebox_override("pressed", style_hover)

	return button

func _add_button_spacer():
	"""Add small spacer between buttons"""
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	button_container.add_child(spacer)

func _show_main_menu():
	"""Show main menu buttons"""
	current_state = MenuState.MAIN
	title_label.text = "Modular Game Tutorial"

	# Show main buttons
	start_tutorial_button.visible = true
	play_runner_button.visible = true
	play_combat_button.visible = true
	mode_select_button.visible = true
	options_button.visible = true
	credits_button.visible = true
	quit_button.visible = true

	# Hide others
	back_button.visible = false
	mode_list_container.visible = false

func _show_mode_select():
	"""Show game mode selection"""
	current_state = MenuState.MODE_SELECT
	title_label.text = "Select Game Mode"

	# Hide main buttons
	start_tutorial_button.visible = false
	play_runner_button.visible = false
	play_combat_button.visible = false
	mode_select_button.visible = false
	options_button.visible = false
	credits_button.visible = false
	quit_button.visible = false

	# Show back button and mode list
	back_button.visible = true
	mode_list_container.visible = true

	# Populate mode list
	_populate_mode_list()

func _populate_mode_list():
	"""Populate game mode selection UI"""
	# Clear existing
	for child in mode_list_container.get_children():
		child.queue_free()

	# Check if GameModeManager exists
	var mode_manager = get_node_or_null("/root/GameModeManager")

	if mode_manager:
		# Use actual game modes
		var info_label = Label.new()
		info_label.text = "Available Game Modes:"
		info_label.add_theme_font_size_override("font_size", 20)
		mode_list_container.add_child(info_label)

		_add_button_spacer()

		# Story Mode
		var story_button = _create_button("Story Mode")
		story_button.pressed.connect(_on_mode_selected.bind("story"))
		mode_list_container.add_child(story_button)

		_add_button_spacer()

		# Challenge Mode
		var challenge_button = _create_button("Challenge Mode")
		challenge_button.pressed.connect(_on_mode_selected.bind("challenge"))
		mode_list_container.add_child(challenge_button)

		_add_button_spacer()

		# Timed Mode
		var timed_button = _create_button("Timed Mode")
		timed_button.pressed.connect(_on_mode_selected.bind("timed"))
		mode_list_container.add_child(timed_button)

	else:
		# Fallback: show info message
		var info_label = Label.new()
		info_label.text = "Game modes use the modular GameModeManager system.\n\n"
		info_label.text += "To enable:\n"
		info_label.text += "1. Add GameModeManager as autoload singleton\n"
		info_label.text += "2. Use BaseGameMode to create custom modes\n"
		info_label.text += "3. Register modes with GameModeManager\n\n"
		info_label.text += "See TUTORIAL_MODULAR_SETUP.md for details!"
		info_label.add_theme_font_size_override("font_size", 18)
		info_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		info_label.custom_minimum_size = Vector2(400, 0)
		mode_list_container.add_child(info_label)

func _show_options():
	"""Show options screen"""
	current_state = MenuState.OPTIONS
	title_label.text = "Options"

	# Hide main buttons
	start_tutorial_button.visible = false
	play_runner_button.visible = false
	play_combat_button.visible = false
	mode_select_button.visible = false
	options_button.visible = false
	credits_button.visible = false
	quit_button.visible = false

	# Show back button
	back_button.visible = true

	# TODO: Add actual options (sound, graphics, controls, etc.)
	print("Options menu - to be implemented")

func _show_credits():
	"""Show credits screen"""
	current_state = MenuState.CREDITS
	title_label.text = "Credits"

	# Hide main buttons
	start_tutorial_button.visible = false
	play_runner_button.visible = false
	play_combat_button.visible = false
	mode_select_button.visible = false
	options_button.visible = false
	credits_button.visible = false
	quit_button.visible = false

	# Show back button
	back_button.visible = true

	print("Credits screen - to be implemented")

# Button callbacks
func _on_start_tutorial_pressed():
	"""Start the tutorial arena level"""
	print("Starting tutorial arena...")
	get_tree().change_scene_to_file("res://scenes/TutorialArena.tscn")

func _on_play_runner_pressed():
	"""Start runner mode"""
	print("Starting runner mode...")

	# Try to use game mode system
	var mode_manager = get_node_or_null("/root/GameModeManager")
	if mode_manager:
		# Load and set classic challenge mode
		var challenge_mode_script = load("res://scripts/game_modes/ChallengeMode.gd")
		if challenge_mode_script and challenge_mode_script.has_method("create_classic_challenge"):
			var classic_mode = challenge_mode_script.create_classic_challenge()
			if mode_manager.has_method("set_active_mode"):
				mode_manager.set_active_mode(classic_mode)

	# Load runner scene
	var runner_scene = "res://scenes/Main3D.tscn"
	if ResourceLoader.exists(runner_scene):
		get_tree().change_scene_to_file(runner_scene)
	else:
		print("Runner scene not found: ", runner_scene)
		# Fallback to Main.tscn
		get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_play_combat_pressed():
	"""Start combat level"""
	print("Starting combat level...")

	var combat_scene = "res://scenes/CombatLevel.tscn"
	if ResourceLoader.exists(combat_scene):
		get_tree().change_scene_to_file(combat_scene)
	else:
		print("Combat scene not found: ", combat_scene)

func _on_mode_select_pressed():
	"""Show mode selection"""
	_show_mode_select()

func _on_options_pressed():
	"""Show options"""
	_show_options()

func _on_credits_pressed():
	"""Show credits"""
	_show_credits()

func _on_quit_pressed():
	"""Quit game"""
	print("Quitting...")
	get_tree().quit()

func _on_back_pressed():
	"""Return to main menu"""
	_show_main_menu()

func _on_mode_selected(mode_type: String):
	"""Handle mode selection"""
	print("Mode selected: ", mode_type)

	var mode_manager = get_node_or_null("/root/GameModeManager")
	if not mode_manager:
		print("GameModeManager not found!")
		return

	# Create and set the selected mode
	match mode_type:
		"story":
			var story_script = load("res://scripts/game_modes/StoryMode.gd")
			if story_script:
				var story_mode = story_script.new()
				if mode_manager.has_method("set_active_mode"):
					mode_manager.set_active_mode(story_mode)

		"challenge":
			var challenge_script = load("res://scripts/game_modes/ChallengeMode.gd")
			if challenge_script and challenge_script.has_method("create_classic_challenge"):
				var challenge_mode = challenge_script.create_classic_challenge()
				if mode_manager.has_method("set_active_mode"):
					mode_manager.set_active_mode(challenge_mode)

		"timed":
			var timed_script = load("res://scripts/game_modes/TimedMode.gd")
			if timed_script:
				var timed_mode = timed_script.new()
				if mode_manager.has_method("set_active_mode"):
					mode_manager.set_active_mode(timed_mode)

	# Start the game
	get_tree().change_scene_to_file("res://scenes/Main3D.tscn")

func _input(event):
	"""Handle keyboard shortcuts"""
	if event.is_action_pressed("ui_cancel"):  # Escape key
		if current_state != MenuState.MAIN:
			_on_back_pressed()
		else:
			_on_quit_pressed()
