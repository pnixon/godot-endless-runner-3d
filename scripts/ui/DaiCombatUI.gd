extends Control
class_name DaiCombatUI

## Dragon Quest Dai Combat UI
## Displays skills, charge bars, HP/MP, boss indicators, etc.

signal skill_button_pressed(skill_index: int)
signal skill_activated(skill_index: int)

# Node references (to be set in editor or created dynamically)
@onready var hp_bar: ProgressBar
@onready var mp_bar: ProgressBar
@onready var boss_hp_bar: ProgressBar
@onready var boss_name_label: Label

# Skill UI containers
var skill_buttons: Array[Button] = []
var skill_charge_bars: Array[ProgressBar] = []
var skill_cooldown_labels: Array[Label] = []
var skill_name_labels: Array[Label] = []
var skill_icons: Array[TextureRect] = []

# Status indicators
var auto_attack_indicator: Panel
var stagger_indicator: Panel
var break_mode_indicator: Panel
var vulnerability_indicator: Panel

# Combat controller reference
var combat_controller: DaiCombatController
var player: Node3D
var current_boss: Node3D

# UI Settings
@export var skill_button_size: Vector2 = Vector2(100, 100)
@export var show_skill_names: bool = true
@export var show_cooldown_text: bool = true
@export var skill_button_spacing: float = 10.0


func _ready() -> void:
	setup_ui()
	update_layout()


func setup_ui() -> void:
	"""Create UI elements dynamically"""
	# Create main containers
	create_player_status_bar()
	create_skill_bar()
	create_boss_status_bar()
	create_combat_indicators()


func create_player_status_bar() -> void:
	"""Create HP/MP bars for player"""
	var player_panel = Panel.new()
	player_panel.name = "PlayerStatusPanel"
	add_child(player_panel)

	var vbox = VBoxContainer.new()
	vbox.name = "PlayerStatusVBox"
	player_panel.add_child(vbox)

	# HP Bar
	var hp_container = HBoxContainer.new()
	vbox.add_child(hp_container)

	var hp_label = Label.new()
	hp_label.text = "HP"
	hp_label.custom_minimum_size = Vector2(40, 0)
	hp_container.add_child(hp_label)

	hp_bar = ProgressBar.new()
	hp_bar.name = "HPBar"
	hp_bar.custom_minimum_size = Vector2(200, 25)
	hp_bar.max_value = 100
	hp_bar.value = 100
	hp_bar.show_percentage = true
	hp_container.add_child(hp_bar)

	# Style HP bar
	var hp_style = StyleBoxFlat.new()
	hp_style.bg_color = Color(0.8, 0.2, 0.2)
	hp_bar.add_theme_stylebox_override("fill", hp_style)

	# MP Bar
	var mp_container = HBoxContainer.new()
	vbox.add_child(mp_container)

	var mp_label = Label.new()
	mp_label.text = "MP"
	mp_label.custom_minimum_size = Vector2(40, 0)
	mp_container.add_child(mp_label)

	mp_bar = ProgressBar.new()
	mp_bar.name = "MPBar"
	mp_bar.custom_minimum_size = Vector2(200, 25)
	mp_bar.max_value = 100
	mp_bar.value = 100
	mp_bar.show_percentage = true
	mp_container.add_child(mp_bar)

	# Style MP bar
	var mp_style = StyleBoxFlat.new()
	mp_style.bg_color = Color(0.2, 0.4, 0.9)
	mp_bar.add_theme_stylebox_override("fill", mp_style)


func create_skill_bar() -> void:
	"""Create skill buttons and charge bars"""
	var skill_panel = Panel.new()
	skill_panel.name = "SkillPanel"
	add_child(skill_panel)

	var skill_container = HBoxContainer.new()
	skill_container.name = "SkillContainer"
	skill_container.add_theme_constant_override("separation", skill_button_spacing)
	skill_panel.add_child(skill_container)

	# Create 4 skill slots
	for i in range(4):
		var skill_slot = create_skill_slot(i)
		skill_container.add_child(skill_slot)


func create_skill_slot(index: int) -> VBoxContainer:
	"""Create a single skill slot with button, charge bar, etc."""
	var slot = VBoxContainer.new()
	slot.name = "SkillSlot" + str(index)

	# Skill name label
	var name_label = Label.new()
	name_label.text = "Skill " + str(index + 1)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.custom_minimum_size = Vector2(skill_button_size.x, 0)
	slot.add_child(name_label)
	skill_name_labels.append(name_label)

	# Skill button
	var button = Button.new()
	button.name = "SkillButton" + str(index)
	button.custom_minimum_size = skill_button_size
	button.text = "---"
	button.disabled = true
	button.pressed.connect(_on_skill_button_pressed.bind(index))
	slot.add_child(button)
	skill_buttons.append(button)

	# Charge bar
	var charge_bar = ProgressBar.new()
	charge_bar.name = "ChargeBar" + str(index)
	charge_bar.custom_minimum_size = Vector2(skill_button_size.x, 15)
	charge_bar.max_value = 100
	charge_bar.value = 0
	charge_bar.show_percentage = false
	slot.add_child(charge_bar)
	skill_charge_bars.append(charge_bar)

	# Style charge bar
	var charge_style = StyleBoxFlat.new()
	charge_style.bg_color = Color(0.2, 0.8, 0.2)
	charge_bar.add_theme_stylebox_override("fill", charge_style)

	# Cooldown label
	var cooldown_label = Label.new()
	cooldown_label.text = ""
	cooldown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cooldown_label.custom_minimum_size = Vector2(skill_button_size.x, 0)
	cooldown_label.add_theme_color_override("font_color", Color.YELLOW)
	slot.add_child(cooldown_label)
	skill_cooldown_labels.append(cooldown_label)

	return slot


func create_boss_status_bar() -> void:
	"""Create boss HP bar and name"""
	var boss_panel = Panel.new()
	boss_panel.name = "BossStatusPanel"
	boss_panel.visible = false  # Hidden until boss appears
	add_child(boss_panel)

	var vbox = VBoxContainer.new()
	boss_panel.add_child(vbox)

	# Boss name
	boss_name_label = Label.new()
	boss_name_label.text = "Boss"
	boss_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_name_label.add_theme_font_size_override("font_size", 24)
	boss_name_label.add_theme_color_override("font_color", Color.RED)
	vbox.add_child(boss_name_label)

	# Boss HP bar
	boss_hp_bar = ProgressBar.new()
	boss_hp_bar.name = "BossHPBar"
	boss_hp_bar.custom_minimum_size = Vector2(400, 40)
	boss_hp_bar.max_value = 100
	boss_hp_bar.value = 100
	boss_hp_bar.show_percentage = true
	vbox.add_child(boss_hp_bar)

	# Style boss HP bar
	var boss_hp_style = StyleBoxFlat.new()
	boss_hp_style.bg_color = Color(0.9, 0.1, 0.1)
	boss_hp_bar.add_theme_stylebox_override("fill", boss_hp_style)


func create_combat_indicators() -> void:
	"""Create indicators for auto-attack, stagger, break mode, etc."""
	var indicator_panel = HBoxContainer.new()
	indicator_panel.name = "CombatIndicators"
	add_child(indicator_panel)

	# Auto-attack indicator
	auto_attack_indicator = Panel.new()
	auto_attack_indicator.custom_minimum_size = Vector2(120, 40)
	var auto_label = Label.new()
	auto_label.text = "AUTO-ATK"
	auto_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	auto_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	auto_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	auto_attack_indicator.add_child(auto_label)
	indicator_panel.add_child(auto_attack_indicator)

	# Stagger indicator
	stagger_indicator = Panel.new()
	stagger_indicator.custom_minimum_size = Vector2(120, 40)
	stagger_indicator.visible = false
	var stagger_label = Label.new()
	stagger_label.text = "STAGGERED!"
	stagger_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stagger_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stagger_label.add_theme_color_override("font_color", Color.YELLOW)
	stagger_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	stagger_indicator.add_child(stagger_label)
	indicator_panel.add_child(stagger_indicator)

	# Break mode indicator
	break_mode_indicator = Panel.new()
	break_mode_indicator.custom_minimum_size = Vector2(150, 50)
	break_mode_indicator.visible = false
	var break_label = Label.new()
	break_label.text = "BREAK MODE!!"
	break_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	break_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	break_label.add_theme_color_override("font_color", Color.CYAN)
	break_label.add_theme_font_size_override("font_size", 20)
	break_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	break_mode_indicator.add_child(break_label)
	indicator_panel.add_child(break_mode_indicator)

	# Vulnerability indicator
	vulnerability_indicator = Panel.new()
	vulnerability_indicator.custom_minimum_size = Vector2(120, 40)
	vulnerability_indicator.visible = false
	var vuln_label = Label.new()
	vuln_label.text = "VULNERABLE"
	vuln_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vuln_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	vuln_label.add_theme_color_override("font_color", Color.ORANGE)
	vuln_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	vulnerability_indicator.add_child(vuln_label)
	indicator_panel.add_child(vulnerability_indicator)


func update_layout() -> void:
	"""Position UI elements on screen"""
	# Player status (top-left)
	var player_panel = get_node_or_null("PlayerStatusPanel")
	if player_panel:
		player_panel.position = Vector2(20, 20)

	# Skill bar (bottom-center)
	var skill_panel = get_node_or_null("SkillPanel")
	if skill_panel:
		skill_panel.position = Vector2(
			(get_viewport_rect().size.x - skill_panel.size.x) / 2,
			get_viewport_rect().size.y - 150
		)

	# Boss status (top-center)
	var boss_panel = get_node_or_null("BossStatusPanel")
	if boss_panel:
		boss_panel.position = Vector2(
			(get_viewport_rect().size.x - 420) / 2,
			20
		)

	# Combat indicators (top-right)
	var indicators = get_node_or_null("CombatIndicators")
	if indicators:
		indicators.position = Vector2(
			get_viewport_rect().size.x - 500,
			20
		)


func _process(_delta: float) -> void:
	if combat_controller:
		update_skill_ui()
		update_player_status()
		update_boss_status()


func update_skill_ui() -> void:
	"""Update skill buttons, charge bars, and cooldowns"""
	for i in range(min(4, combat_controller.skills.size())):
		var skill = combat_controller.skills[i]

		if skill:
			# Update button text and state
			skill_buttons[i].text = skill.ability_name.substr(0, 10)  # Truncate long names
			skill_buttons[i].disabled = not combat_controller.is_skill_ready(i)

			# Update name label
			skill_name_labels[i].text = skill.ability_name

			# Update charge bar
			var charge_percent = combat_controller.get_skill_charge_percent(i)
			skill_charge_bars[i].value = charge_percent

			# Update cooldown text
			var cooldown = combat_controller.skill_cooldowns[i]
			if cooldown > 0:
				skill_cooldown_labels[i].text = "%.1fs" % cooldown
			else:
				skill_cooldown_labels[i].text = ""

			# Color coding
			if combat_controller.is_skill_ready(i):
				var ready_style = StyleBoxFlat.new()
				ready_style.bg_color = Color(0.2, 0.9, 0.2)
				ready_style.border_width_all = 2
				ready_style.border_color = Color.GOLD
				skill_buttons[i].add_theme_stylebox_override("normal", ready_style)
			else:
				skill_buttons[i].remove_theme_stylebox_override("normal")
		else:
			# Empty slot
			skill_buttons[i].text = "---"
			skill_buttons[i].disabled = true
			skill_name_labels[i].text = "Empty Slot"
			skill_charge_bars[i].value = 0
			skill_cooldown_labels[i].text = ""


func update_player_status() -> void:
	"""Update player HP/MP bars"""
	if not player:
		return

	# Update HP
	if player.has_method("get_health_percentage"):
		hp_bar.value = player.get_health_percentage()

	# Update MP
	if player.has_method("get_mp_percentage"):
		mp_bar.value = player.get_mp_percentage()


func update_boss_status() -> void:
	"""Update boss HP bar and indicators"""
	var boss_panel = get_node_or_null("BossStatusPanel")
	if not boss_panel:
		return

	if current_boss:
		boss_panel.visible = true

		# Update HP
		if current_boss.has_method("get_health_percentage"):
			boss_hp_bar.value = current_boss.get_health_percentage()

		# Update indicators
		if current_boss.has_method("is_boss_staggered"):
			stagger_indicator.visible = current_boss.is_boss_staggered()

		if current_boss.has_method("is_boss_in_break_mode"):
			break_mode_indicator.visible = current_boss.is_boss_in_break_mode()

		if current_boss.has_method("is_boss_vulnerable"):
			vulnerability_indicator.visible = current_boss.is_boss_vulnerable()
	else:
		boss_panel.visible = false
		stagger_indicator.visible = false
		break_mode_indicator.visible = false
		vulnerability_indicator.visible = false


func _on_skill_button_pressed(skill_index: int) -> void:
	"""Handle skill button press"""
	if combat_controller:
		if combat_controller.activate_skill(skill_index):
			emit_signal("skill_activated", skill_index)
			print("DaiCombatUI: Activated skill ", skill_index)


## Public API

func set_combat_controller(controller: DaiCombatController) -> void:
	"""Set the combat controller reference"""
	combat_controller = controller


func set_player(player_node: Node3D) -> void:
	"""Set the player reference"""
	player = player_node


func set_boss(boss_node: Node3D) -> void:
	"""Set the current boss reference"""
	current_boss = boss_node

	if boss_node:
		# Connect to boss signals
		if not boss_node.is_connected("boss_staggered", _on_boss_staggered):
			boss_node.connect("boss_staggered", _on_boss_staggered)
		if not boss_node.is_connected("break_mode_entered", _on_break_mode_entered):
			boss_node.connect("break_mode_entered", _on_break_mode_entered)
		if not boss_node.is_connected("break_mode_ended", _on_break_mode_ended):
			boss_node.connect("break_mode_ended", _on_break_mode_ended)
		if not boss_node.is_connected("vulnerability_opened", _on_vulnerability_opened):
			boss_node.connect("vulnerability_opened", _on_vulnerability_opened)
		if not boss_node.is_connected("vulnerability_closed", _on_vulnerability_closed):
			boss_node.connect("vulnerability_closed", _on_vulnerability_closed)

		# Update boss name
		if boss_name_label:
			boss_name_label.text = "Boss (Tier " + str(boss_node.boss_tier) + ")"


func clear_boss() -> void:
	"""Clear the boss reference"""
	current_boss = null


## Signal handlers

func _on_boss_staggered() -> void:
	"""Called when boss is staggered"""
	# Could add animation/flash here
	pass


func _on_break_mode_entered() -> void:
	"""Called when boss enters break mode"""
	# Could add special visual effects
	pass


func _on_break_mode_ended() -> void:
	"""Called when boss exits break mode"""
	pass


func _on_vulnerability_opened() -> void:
	"""Called when vulnerability window opens"""
	# Could add pulsing animation
	pass


func _on_vulnerability_closed() -> void:
	"""Called when vulnerability window closes"""
	pass
