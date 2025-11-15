extends Node
class_name DaiCombatIntegration

## Dragon Quest Dai Combat Integration Manager
## Central hub that connects all DQ Dai combat systems together
## Add this as a child of your game manager or main scene

# Combat systems
var combat_controller: DaiCombatController
var skill_acquisition: SkillAcquisitionSystem
var combat_ui: DaiCombatUI

# References
@export var player: Node3D
@export var game_manager: Node
@export var ui_container: Control

# Auto-created systems
var auto_created_controller: bool = false
var auto_created_acquisition: bool = false
var auto_created_ui: bool = false

# Input configuration
@export var enable_keyboard_input: bool = true
@export var enable_mobile_input: bool = true
@export_group("Keyboard Bindings")
@export var skill_1_key: Key = KEY_1
@export var skill_2_key: Key = KEY_2
@export var skill_3_key: Key = KEY_3
@export var skill_4_key: Key = KEY_4


func _ready() -> void:
	setup_combat_systems()
	setup_starter_skills()
	connect_signals()
	print("DaiCombatIntegration: DQ Dai combat system initialized!")


func setup_combat_systems() -> void:
	"""Initialize all combat systems"""
	# Get or create combat controller
	combat_controller = get_node_or_null("DaiCombatController")
	if not combat_controller:
		combat_controller = DaiCombatController.new()
		combat_controller.name = "DaiCombatController"
		add_child(combat_controller)
		auto_created_controller = true

	# Get or create skill acquisition system
	skill_acquisition = get_node_or_null("SkillAcquisitionSystem")
	if not skill_acquisition:
		skill_acquisition = SkillAcquisitionSystem.new()
		skill_acquisition.name = "SkillAcquisitionSystem"
		add_child(skill_acquisition)
		auto_created_acquisition = true

	# Get or create combat UI
	combat_ui = get_node_or_null("DaiCombatUI")
	if not combat_ui:
		combat_ui = DaiCombatUI.new()
		combat_ui.name = "DaiCombatUI"

		# Add to UI container if available
		if ui_container:
			ui_container.add_child(combat_ui)
		else:
			# Try to find canvas layer or create one
			var canvas = get_tree().root.get_node_or_null("CanvasLayer")
			if not canvas:
				canvas = CanvasLayer.new()
				canvas.name = "DaiCombatCanvas"
				get_tree().root.add_child(canvas)
			canvas.add_child(combat_ui)

		auto_created_ui = true

	# Set references
	if player:
		combat_controller.player = player
		skill_acquisition.player = player
		combat_ui.set_player(player)

	combat_ui.set_combat_controller(combat_controller)


func setup_starter_skills() -> void:
	"""Give player starter skills"""
	var starter_skills = DaiAbilityLibrary.get_starter_loadout()

	# Unlock starter skills
	for skill in starter_skills:
		skill.is_unlocked = true
		skill_acquisition.unlocked_skills[skill.ability_name] = skill

	# Equip to combat controller
	for i in range(min(4, starter_skills.size())):
		combat_controller.equip_skill(starter_skills[i], i)
		skill_acquisition.equip_skill(starter_skills[i], i)

	print("DaiCombatIntegration: Equipped ", starter_skills.size(), " starter skills")


func connect_signals() -> void:
	"""Connect system signals"""
	# Combat controller signals
	if combat_controller:
		combat_controller.skill_activated.connect(_on_skill_activated)
		combat_controller.auto_attack_hit.connect(_on_auto_attack_hit)
		combat_controller.boss_staggered.connect(_on_boss_staggered)
		combat_controller.break_mode_activated.connect(_on_break_mode_activated)
		combat_controller.vulnerability_window_opened.connect(_on_vulnerability_opened)

	# Skill acquisition signals
	if skill_acquisition:
		skill_acquisition.skill_unlocked.connect(_on_skill_unlocked)
		skill_acquisition.skill_upgraded.connect(_on_skill_upgraded)


func _process(_delta: float) -> void:
	handle_input()


func handle_input() -> void:
	"""Handle skill activation input"""
	if not enable_keyboard_input:
		return

	if Input.is_action_just_pressed("ui_accept") or Input.is_key_pressed(skill_1_key):
		activate_skill(0)
	elif Input.is_key_pressed(skill_2_key):
		activate_skill(1)
	elif Input.is_key_pressed(skill_3_key):
		activate_skill(2)
	elif Input.is_key_pressed(skill_4_key):
		activate_skill(3)


func activate_skill(skill_index: int) -> void:
	"""Activate a skill by index"""
	if combat_controller:
		combat_controller.activate_skill(skill_index)


## Boss Management

func register_boss(boss: Node3D) -> void:
	"""Register a boss for combat tracking"""
	if combat_controller:
		combat_controller.set_current_boss(boss)

	if combat_ui:
		combat_ui.set_boss(boss)

	print("DaiCombatIntegration: Registered boss - ", boss.name)


func unregister_boss() -> void:
	"""Unregister the current boss"""
	if combat_controller:
		combat_controller.current_boss = null

	if combat_ui:
		combat_ui.clear_boss()


func open_boss_vulnerability_window(duration: float = 3.0) -> void:
	"""Manually open a boss vulnerability window"""
	if combat_controller:
		combat_controller.open_vulnerability_window()


## Skill Management API

func unlock_skill(skill_name: String) -> bool:
	"""Unlock a skill by name"""
	var skill = DaiAbilityLibrary.get_ability_by_name(skill_name)
	if not skill:
		return false

	skill.is_unlocked = true
	skill_acquisition.unlocked_skills[skill_name] = skill
	return true


func equip_skill_to_slot(skill_name: String, slot: int) -> bool:
	"""Equip a skill to a specific slot"""
	var skill = skill_acquisition.unlocked_skills.get(skill_name)
	if not skill:
		return false

	combat_controller.equip_skill(skill, slot)
	skill_acquisition.equip_skill(skill, slot)
	return true


func add_skill_fragments(skill_name: String, count: int = 1) -> void:
	"""Add skill fragments"""
	skill_acquisition.add_skill_fragments(skill_name, count)


func use_skill_scroll(scroll: SkillAcquisitionSystem.SkillScroll) -> bool:
	"""Use a skill scroll"""
	return skill_acquisition.use_skill_scroll(scroll)


## Enemy Defeat Handling

func on_enemy_defeated(enemy: Node3D) -> void:
	"""Called when an enemy is defeated"""
	var enemy_type = "normal"

	# Check if it's a boss
	if enemy is BossEnemy:
		enemy_type = "boss"

	# Process fragment drops
	skill_acquisition.process_enemy_defeat(enemy_type)


## Signal Handlers

func _on_skill_activated(skill_index: int, skill_name: String) -> void:
	"""Called when a skill is activated"""
	print("DaiCombatIntegration: Skill activated - ", skill_name)

	# Could trigger visual/audio feedback here
	if game_manager and game_manager.has_method("on_skill_used"):
		game_manager.on_skill_used(skill_name)


func _on_auto_attack_hit(target: Node3D, damage: float) -> void:
	"""Called when auto-attack hits"""
	# Could show damage numbers
	pass


func _on_boss_staggered(boss: Node3D) -> void:
	"""Called when boss is staggered"""
	print("DaiCombatIntegration: Boss STAGGERED!")

	# Could show special UI message
	if game_manager and game_manager.has_method("on_boss_staggered"):
		game_manager.on_boss_staggered(boss)


func _on_break_mode_activated(boss: Node3D) -> void:
	"""Called when boss enters break mode"""
	print("DaiCombatIntegration: BREAK MODE activated!")

	# Could play dramatic sound/animation
	if game_manager and game_manager.has_method("on_break_mode"):
		game_manager.on_break_mode(boss)


func _on_vulnerability_opened(boss: Node3D) -> void:
	"""Called when vulnerability window opens"""
	print("DaiCombatIntegration: Vulnerability window opened!")


func _on_skill_unlocked(skill: AbilityData) -> void:
	"""Called when a skill is unlocked"""
	print("DaiCombatIntegration: NEW SKILL UNLOCKED - ", skill.ability_name, "!")

	# Could show unlock notification
	if game_manager and game_manager.has_method("on_skill_unlocked"):
		game_manager.on_skill_unlocked(skill)


func _on_skill_upgraded(skill: AbilityData, new_level: int) -> void:
	"""Called when a skill is upgraded"""
	print("DaiCombatIntegration: Skill upgraded - ", skill.ability_name, " -> Level ", new_level)


## Public API for Game Manager

func get_combat_controller() -> DaiCombatController:
	"""Get the combat controller"""
	return combat_controller


func get_skill_acquisition() -> SkillAcquisitionSystem:
	"""Get the skill acquisition system"""
	return skill_acquisition


func get_combat_ui() -> DaiCombatUI:
	"""Get the combat UI"""
	return combat_ui


func enable_auto_attack(enabled: bool) -> void:
	"""Enable/disable auto-attack"""
	if combat_controller:
		combat_controller.auto_attack_enabled = enabled


func set_auto_attack_damage(damage: float) -> void:
	"""Set auto-attack damage"""
	if combat_controller:
		combat_controller.auto_attack_damage = damage


## Debug/Testing Functions

func debug_unlock_all_skills() -> void:
	"""Debug: Unlock all skills"""
	var all_skills: Array[AbilityData] = []
	all_skills.append_array(DaiAbilityLibrary.get_all_basic_abilities())
	all_skills.append_array(DaiAbilityLibrary.get_all_advanced_abilities())
	all_skills.append_array(DaiAbilityLibrary.get_all_ultimate_abilities())

	for skill in all_skills:
		skill.is_unlocked = true
		skill_acquisition.unlocked_skills[skill.ability_name] = skill

	print("DaiCombatIntegration: DEBUG - Unlocked all skills!")


func debug_max_all_fragments() -> void:
	"""Debug: Give max fragments for all skills"""
	for skill_name in skill_acquisition.fragments_required.keys():
		var required = skill_acquisition.fragments_required[skill_name]
		skill_acquisition.add_skill_fragments(skill_name, required)

	print("DaiCombatIntegration: DEBUG - Maxed all fragments!")


func debug_print_status() -> void:
	"""Debug: Print combat system status"""
	print("=== DQ Dai Combat System Status ===")
	print("Unlocked Skills: ", skill_acquisition.unlocked_skills.size())
	print("Equipped Skills: ", combat_controller.skills.size())
	print("Auto-Attack Enabled: ", combat_controller.auto_attack_enabled)
	print("Current Boss: ", combat_controller.current_boss)

	if combat_controller.current_boss:
		print("  - Boss Vulnerable: ", combat_controller.current_boss.is_boss_vulnerable())
		print("  - Boss Staggered: ", combat_controller.current_boss.is_boss_staggered())
		print("  - Break Mode: ", combat_controller.current_boss.is_boss_in_break_mode())

	print("=================================")
