extends CanvasLayer

## Mode Objectives UI
## Displays current mode objectives and progress during gameplay

@onready var objectives_panel: Panel = null
@onready var objectives_container: VBoxContainer = null
@onready var mode_title: Label = null
@onready var timer_label: Label = null
@onready var lives_label: Label = null

var current_mode: BaseGameMode = null
var objective_labels: Dictionary = {}

func _ready() -> void:
	_setup_ui()
	hide()

func _setup_ui() -> void:
	"""Create UI structure"""
	# Create panel
	if not has_node("ObjectivesPanel"):
		var panel = Panel.new()
		panel.name = "ObjectivesPanel"
		panel.position = Vector2(20, 100)
		panel.custom_minimum_size = Vector2(300, 200)
		add_child(panel)
		objectives_panel = panel

		var vbox = VBoxContainer.new()
		vbox.name = "VBox"
		panel.add_child(vbox)

		# Mode title
		mode_title = Label.new()
		mode_title.name = "ModeTitle"
		mode_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		mode_title.add_theme_font_size_override("font_size", 18)
		vbox.add_child(mode_title)

		# Timer/Lives info
		var info_hbox = HBoxContainer.new()
		vbox.add_child(info_hbox)

		timer_label = Label.new()
		timer_label.name = "TimerLabel"
		info_hbox.add_child(timer_label)

		lives_label = Label.new()
		lives_label.name = "LivesLabel"
		lives_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		info_hbox.add_child(lives_label)

		# Separator
		var separator = HSeparator.new()
		vbox.add_child(separator)

		# Objectives container
		objectives_container = VBoxContainer.new()
		objectives_container.name = "ObjectivesContainer"
		vbox.add_child(objectives_container)

func set_mode(mode: BaseGameMode) -> void:
	"""Set the current mode and update UI"""
	current_mode = mode
	_update_mode_info()
	_create_objective_labels()
	show()

func _update_mode_info() -> void:
	"""Update mode title and info"""
	if not current_mode or not mode_title:
		return

	mode_title.text = current_mode.mode_name

	# Update timer
	if current_mode.has_time_limit:
		var remaining = current_mode.get_time_remaining()
		timer_label.text = "Time: %d:%02d" % [int(remaining) / 60, int(remaining) % 60]
		timer_label.show()
	else:
		var elapsed = current_mode.elapsed_time
		timer_label.text = "Time: %d:%02d" % [int(elapsed) / 60, int(elapsed) % 60]

	# Update lives
	if current_mode.max_lives > 0:
		lives_label.text = "Lives: %d" % current_mode.get_lives_remaining()
		lives_label.show()
	else:
		lives_label.hide()

func _create_objective_labels() -> void:
	"""Create labels for each objective"""
	if not objectives_container:
		return

	# Clear existing
	for child in objectives_container.get_children():
		child.queue_free()
	objective_labels.clear()

	if not current_mode:
		return

	# Primary objectives
	var primary_label = Label.new()
	primary_label.text = "PRIMARY OBJECTIVES:"
	primary_label.add_theme_font_size_override("font_size", 14)
	objectives_container.add_child(primary_label)

	for objective in current_mode.get_primary_objectives():
		var label = _create_objective_label(objective)
		objectives_container.add_child(label)
		objective_labels[objective] = label

	# Secondary objectives
	var secondary_objectives = current_mode.get_secondary_objectives()
	if secondary_objectives.size() > 0:
		var secondary_label = Label.new()
		secondary_label.text = "\nBONUS OBJECTIVES:"
		secondary_label.add_theme_font_size_override("font_size", 14)
		objectives_container.add_child(secondary_label)

		for objective in secondary_objectives:
			var label = _create_objective_label(objective)
			objectives_container.add_child(label)
			objective_labels[objective] = label

func _create_objective_label(objective: BaseGameMode.Objective) -> Label:
	"""Create a label for an objective"""
	var label = Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_update_objective_label(label, objective)
	return label

func _update_objective_label(label: Label, objective: BaseGameMode.Objective) -> void:
	"""Update objective label text and color"""
	var progress_text = ""

	# Add progress indicator
	if objective.is_complete:
		progress_text = "[✓] "
		label.add_theme_color_override("font_color", Color.GREEN)
	else:
		progress_text = "[ ] "
		label.add_theme_color_override("font_color", Color.WHITE)

	# Add description and progress
	var progress_percent = objective.get_progress_percent()
	label.text = "%s%s (%.0f%%)" % [progress_text, objective.description, progress_percent]

func _process(delta: float) -> void:
	"""Update UI every frame"""
	if not visible or not current_mode or not current_mode.is_active:
		return

	# Update mode info
	_update_mode_info()

	# Update objective labels
	for objective in objective_labels.keys():
		var label = objective_labels[objective]
		_update_objective_label(label, objective)

func show_completion_screen(results: Dictionary) -> void:
	"""Show completion screen with results"""
	# This could create a popup or transition to a results screen
	print("Mode completed with results: ", results)
	# For now, just hide objectives
	hide()

func show_failure_screen(reason: String) -> void:
	"""Show failure screen"""
	print("Mode failed: ", reason)
	hide()

func _on_mode_completed(results: Dictionary) -> void:
	"""Handle mode completion"""
	show_completion_screen(results)

func _on_mode_failed(reason: String) -> void:
	"""Handle mode failure"""
	show_failure_screen(reason)
