extends CanvasLayer

## Mode Selection UI
## Allows players to choose between Story, Challenge, and Timed modes

signal mode_selected(mode: BaseGameMode)
signal back_to_menu()

## UI References (to be set in scene or code)
@onready var mode_tabs_container: Control = $Panel/VBox/TabContainer if has_node("Panel/VBox/TabContainer") else null
@onready var story_tab: Control = null
@onready var challenge_tab: Control = null
@onready var timed_tab: Control = null

## Current selection
var selected_mode: BaseGameMode = null
var current_tab: int = 0

enum Tab { STORY, CHALLENGE, TIMED }

func _ready() -> void:
	_setup_ui()
	_populate_modes()

func _setup_ui() -> void:
	"""Create UI programmatically if not set up in scene"""
	# This is a simplified version - in a real implementation,
	# you'd create this in the Godot editor or use a more robust UI system

	# For now, we'll create a basic structure
	if not has_node("Panel"):
		var panel = Panel.new()
		panel.name = "Panel"
		add_child(panel)

		var vbox = VBoxContainer.new()
		vbox.name = "VBox"
		panel.add_child(vbox)

		# Title
		var title = Label.new()
		title.text = "SELECT GAME MODE"
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(title)

		# Tab container
		var tab_container = TabContainer.new()
		tab_container.name = "TabContainer"
		vbox.add_child(tab_container)

		# Story tab
		var story_scroll = ScrollContainer.new()
		story_scroll.name = "Story"
		tab_container.add_child(story_scroll)
		story_tab = VBoxContainer.new()
		story_scroll.add_child(story_tab)

		# Challenge tab
		var challenge_scroll = ScrollContainer.new()
		challenge_scroll.name = "Challenge"
		tab_container.add_child(challenge_scroll)
		challenge_tab = VBoxContainer.new()
		challenge_scroll.add_child(challenge_tab)

		# Timed tab
		var timed_scroll = ScrollContainer.new()
		timed_scroll.name = "Timed"
		tab_container.add_child(timed_scroll)
		timed_tab = VBoxContainer.new()
		timed_scroll.add_child(timed_tab)

		# Back button
		var back_button = Button.new()
		back_button.text = "Back to Menu"
		back_button.pressed.connect(_on_back_pressed)
		vbox.add_child(back_button)

		mode_tabs_container = tab_container

	hide()

func _populate_modes() -> void:
	"""Populate the UI with available modes"""
	if not GameModeManager:
		print("GameModeManager not found!")
		return

	_populate_story_modes()
	_populate_challenge_modes()
	_populate_timed_modes()

func _populate_story_modes() -> void:
	"""Add story level buttons"""
	if not story_tab:
		return

	# Clear existing
	for child in story_tab.get_children():
		child.queue_free()

	var unlocked_levels = GameModeManager.get_unlocked_story_levels()

	for mode in unlocked_levels:
		var level_button = _create_mode_button(mode)
		story_tab.add_child(level_button)

	# Add locked levels (grayed out)
	for level_id in GameModeManager.story_levels.keys():
		if not GameModeManager.is_mode_unlocked(level_id):
			var mode = GameModeManager.story_levels[level_id]
			var locked_button = _create_mode_button(mode, true)
			story_tab.add_child(locked_button)

func _populate_challenge_modes() -> void:
	"""Add challenge mode buttons"""
	if not challenge_tab:
		return

	for child in challenge_tab.get_children():
		child.queue_free()

	var unlocked_challenges = GameModeManager.get_unlocked_challenges()

	for mode in unlocked_challenges:
		var challenge_button = _create_mode_button(mode)
		challenge_tab.add_child(challenge_button)

	# Add locked challenges
	for challenge_id in GameModeManager.challenge_modes.keys():
		if not GameModeManager.is_mode_unlocked(challenge_id):
			var mode = GameModeManager.challenge_modes[challenge_id]
			var locked_button = _create_mode_button(mode, true)
			challenge_tab.add_child(locked_button)

func _populate_timed_modes() -> void:
	"""Add timed challenge buttons"""
	if not timed_tab:
		return

	for child in timed_tab.get_children():
		child.queue_free()

	var unlocked_timed = GameModeManager.get_unlocked_timed_challenges()

	for mode in unlocked_timed:
		var timed_button = _create_mode_button(mode)
		timed_tab.add_child(timed_button)

	# Add locked timed challenges
	for timed_id in GameModeManager.timed_challenges.keys():
		if not GameModeManager.is_mode_unlocked(timed_id):
			var mode = GameModeManager.timed_challenges[timed_id]
			var locked_button = _create_mode_button(mode, true)
			timed_tab.add_child(locked_button)

func _create_mode_button(mode: BaseGameMode, locked: bool = false) -> Button:
	"""Create a button for a game mode"""
	var button = Button.new()
	button.custom_minimum_size = Vector2(400, 80)

	# Build button text
	var button_text = mode.mode_name
	if mode is StoryMode:
		var progress = GameModeManager.get_story_progress((mode as StoryMode).level_id)
		if progress.has("stars"):
			button_text += " [%d ★]" % progress["stars"]
	elif mode is ChallengeMode:
		var challenge_type = ChallengeMode.ChallengeType.keys()[(mode as ChallengeMode).challenge_type].to_lower()
		var record = GameModeManager.get_challenge_record(challenge_type)
		if record.has("high_score"):
			button_text += " [Best: %d]" % record["high_score"]
	elif mode is TimedMode:
		var timed_type = TimedMode.TimedType.keys()[(mode as TimedMode).timed_type].to_lower()
		var record = GameModeManager.get_timed_record(timed_type)
		if record.has("best_rank"):
			button_text += " [%s]" % record["best_rank"]

	button.text = button_text if not locked else "[LOCKED] " + mode.mode_name
	button.disabled = locked

	if not locked:
		button.pressed.connect(_on_mode_button_pressed.bind(mode))

	# Add tooltip with description
	button.tooltip_text = mode.mode_description

	return button

func _on_mode_button_pressed(mode: BaseGameMode) -> void:
	"""Handle mode selection"""
	selected_mode = mode
	mode_selected.emit(mode)

func _on_back_pressed() -> void:
	"""Return to main menu"""
	back_to_menu.emit()
	hide()

func show_selection() -> void:
	"""Show the mode selection UI"""
	_populate_modes()  # Refresh in case progress changed
	show()

func _input(event: InputEvent) -> void:
	"""Handle input for quick navigation"""
	if not visible:
		return

	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
		accept_event()
