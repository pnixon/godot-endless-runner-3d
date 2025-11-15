extends Node
class_name DaiCombatIntegration

## DaiCombatIntegration - Main integration hub for Dragon Quest Dai combat system
## This node manages the combat controller, skill system, and UI for DQ Dai style combat
## Add this as a child of your player or game manager to enable combat features

# ============================================================================
# SIGNALS
# ============================================================================

signal combat_ready()
signal skill_activated(skill_name: String)
signal skill_unlocked(skill_name: String)
signal auto_attack_performed(target: Node)
signal break_mode_activated()
signal break_mode_ended()

# ============================================================================
# EXPORT CONFIGURATION
# ============================================================================

@export_group("Combat Controller")
@export var auto_create_controller: bool = true
@export var auto_attack_enabled: bool = true
@export var auto_attack_interval: float = GameConstants.AUTO_ATTACK_INTERVAL
@export var auto_attack_range: float = GameConstants.AUTO_ATTACK_RANGE

@export_group("Skill System")
@export var auto_create_skill_system: bool = true
@export var starting_skills: Array[String] = ["Air Slash", "Heal"]
@export var max_skill_slots: int = GameConstants.ACTIVE_SKILL_SLOTS

@export_group("UI")
@export var auto_create_ui: bool = true
@export var ui_position: Vector2 = Vector2(20, 20)

@export_group("Input")
@export var skill_key_1: Key = KEY_1
@export var skill_key_2: Key = KEY_2
@export var skill_key_3: Key = KEY_3
@export var skill_key_4: Key = KEY_4
@export var enable_debug_commands: bool = true

# ============================================================================
# COMPONENTS
# ============================================================================

var combat_controller: Node
var skill_acquisition: Node
var combat_ui: CanvasLayer
var ability_library: Node

# ============================================================================
# STATE
# ============================================================================

var is_initialized: bool = false
var player: Node = null

# ============================================================================
# INITIALIZATION
# ============================================================================

func _ready():
	"""Initialize combat integration system"""
	# Wait a frame for parent to be ready
	await get_tree().process_frame

	# Find player
	player = _find_player()
	if not player:
		push_warning("DaiCombatIntegration: No player found. Combat system disabled.")
		return

	# Create components
	if auto_create_controller:
		_create_combat_controller()

	if auto_create_skill_system:
		_create_skill_acquisition_system()

	if auto_create_ui:
		_create_combat_ui()

	# Load ability library
	_load_ability_library()

	# Grant starting skills
	_grant_starting_skills()

	is_initialized = true
	combat_ready.emit()

	print("✅ DaiCombatIntegration initialized successfully")
	_print_status()

func _find_player() -> Node:
	"""Find the player node"""
	# Try parent first
	if get_parent().is_in_group("player") or get_parent().is_in_group("rpg_player"):
		return get_parent()

	# Try finding in scene
	var player_node = get_tree().get_first_node_in_group("rpg_player")
	if not player_node:
		player_node = get_tree().get_first_node_in_group("player")

	return player_node

func _create_combat_controller():
	"""Create the main combat controller"""
	# Check if DaiCombatController script exists
	var script_path = "res://scripts/combat/DaiCombatController.gd"
	if not ResourceLoader.exists(script_path):
		push_error("DaiCombatIntegration: Cannot find DaiCombatController.gd")
		return

	var ControllerScript = load(script_path)
	combat_controller = ControllerScript.new()
	combat_controller.name = "DaiCombatController"

	# Configure controller
	if combat_controller.has("auto_attack_enabled"):
		combat_controller.set("auto_attack_enabled", auto_attack_enabled)
	if combat_controller.has("auto_attack_interval"):
		combat_controller.set("auto_attack_interval", auto_attack_interval)
	if combat_controller.has("auto_attack_range"):
		combat_controller.set("auto_attack_range", auto_attack_range)

	add_child(combat_controller)

	# Connect signals
	if combat_controller.has_signal("skill_activated"):
		combat_controller.skill_activated.connect(_on_skill_activated)
	if combat_controller.has_signal("break_mode_started"):
		combat_controller.break_mode_started.connect(_on_break_mode_started)
	if combat_controller.has_signal("break_mode_ended"):
		combat_controller.break_mode_ended.connect(_on_break_mode_ended)

func _create_skill_acquisition_system():
	"""Create the skill acquisition/unlock system"""
	var script_path = "res://scripts/combat/SkillAcquisitionSystem.gd"
	if not ResourceLoader.exists(script_path):
		push_warning("DaiCombatIntegration: Cannot find SkillAcquisitionSystem.gd, skipping")
		return

	var SkillScript = load(script_path)
	skill_acquisition = SkillScript.new()
	skill_acquisition.name = "SkillAcquisitionSystem"
	add_child(skill_acquisition)

	# Connect signals
	if skill_acquisition.has_signal("skill_unlocked"):
		skill_acquisition.skill_unlocked.connect(_on_skill_unlocked)

func _create_combat_ui():
	"""Create the combat UI layer"""
	var script_path = "res://scripts/ui/DaiCombatUI.gd"
	if not ResourceLoader.exists(script_path):
		push_warning("DaiCombatIntegration: Cannot find DaiCombatUI.gd, skipping UI")
		return

	var UIScript = load(script_path)
	combat_ui = UIScript.new()
	combat_ui.name = "DaiCombatUI"

	# Add to root to overlay everything
	get_tree().root.add_child(combat_ui)

	# Connect to combat controller if available
	if combat_controller and combat_ui.has_method("set_combat_controller"):
		combat_ui.set_combat_controller(combat_controller)

func _load_ability_library():
	"""Load the ability library resource"""
	var library_path = "res://scripts/combat/DaiAbilityLibrary.gd"
	if ResourceLoader.exists(library_path):
		ability_library = load(library_path).new()
		ability_library.name = "DaiAbilityLibrary"
		add_child(ability_library)
		print("✓ Ability library loaded with abilities")

func _grant_starting_skills():
	"""Grant starting skills to player"""
	if not combat_controller:
		return

	for skill_name in starting_skills:
		if combat_controller.has_method("unlock_skill"):
			combat_controller.unlock_skill(skill_name)
			print("  Granted starting skill: ", skill_name)

# ============================================================================
# INPUT HANDLING
# ============================================================================

func _input(event: InputEvent):
	"""Handle skill activation input"""
	if not is_initialized or not combat_controller:
		return

	if event is InputEventKey and event.pressed:
		# Skill activation
		if event.keycode == skill_key_1:
			activate_skill_slot(0)
		elif event.keycode == skill_key_2:
			activate_skill_slot(1)
		elif event.keycode == skill_key_3:
			activate_skill_slot(2)
		elif event.keycode == skill_key_4:
			activate_skill_slot(3)

		# Debug commands (if enabled)
		if enable_debug_commands and OS.is_debug_build():
			_handle_debug_input(event)

func _handle_debug_input(event: InputEventKey):
	"""Handle debug keyboard commands"""
	match event.keycode:
		KEY_F5:
			print_skill_status()
		KEY_F6:
			unlock_random_skill()
		KEY_F7:
			refill_resources()
		KEY_F8:
			trigger_break_mode()

# ============================================================================
# PUBLIC METHODS
# ============================================================================

func activate_skill_slot(slot_index: int) -> bool:
	"""Activate a skill in the specified slot"""
	if not combat_controller or not combat_controller.has_method("activate_skill_slot"):
		return false

	return combat_controller.activate_skill_slot(slot_index)

func activate_skill_by_name(skill_name: String) -> bool:
	"""Activate a skill by its name"""
	if not combat_controller or not combat_controller.has_method("activate_skill"):
		return false

	return combat_controller.activate_skill(skill_name)

func unlock_skill(skill_name: String) -> bool:
	"""Unlock a skill for the player"""
	if not combat_controller or not combat_controller.has_method("unlock_skill"):
		return false

	return combat_controller.unlock_skill(skill_name)

func add_skill_fragments(skill_name: String, amount: int):
	"""Add fragments toward unlocking a skill"""
	if skill_acquisition and skill_acquisition.has_method("add_fragments"):
		skill_acquisition.add_fragments(skill_name, amount)

func equip_skill_to_slot(skill_name: String, slot_index: int) -> bool:
	"""Equip a skill to a specific slot"""
	if not combat_controller or not combat_controller.has_method("equip_skill"):
		return false

	return combat_controller.equip_skill(skill_name, slot_index)

func get_equipped_skills() -> Array:
	"""Get array of currently equipped skills"""
	if combat_controller and combat_controller.has_method("get_equipped_skills"):
		return combat_controller.get_equipped_skills()
	return []

func get_unlocked_skills() -> Array:
	"""Get array of all unlocked skills"""
	if combat_controller and combat_controller.has_method("get_unlocked_skills"):
		return combat_controller.get_unlocked_skills()
	return []

func is_skill_ready(skill_name: String) -> bool:
	"""Check if a skill is off cooldown and has enough resources"""
	if combat_controller and combat_controller.has_method("is_skill_ready"):
		return combat_controller.is_skill_ready(skill_name)
	return false

func get_skill_cooldown(skill_name: String) -> float:
	"""Get remaining cooldown time for a skill"""
	if combat_controller and combat_controller.has_method("get_skill_cooldown"):
		return combat_controller.get_skill_cooldown(skill_name)
	return 0.0

func get_auto_attack_target() -> Node:
	"""Get current auto-attack target"""
	if combat_controller and combat_controller.has_method("get_auto_attack_target"):
		return combat_controller.get_auto_attack_target()
	return null

func set_auto_attack_enabled(enabled: bool):
	"""Enable or disable auto-attacking"""
	auto_attack_enabled = enabled
	if combat_controller and combat_controller.has("auto_attack_enabled"):
		combat_controller.set("auto_attack_enabled", enabled)

# ============================================================================
# DEBUG COMMANDS
# ============================================================================

func print_skill_status():
	"""Print current skill status to console"""
	if not combat_controller:
		print("No combat controller available")
		return

	print("\n=== COMBAT STATUS ===")
	print("Equipped Skills:")
	var equipped = get_equipped_skills()
	for i in range(equipped.size()):
		var skill = equipped[i]
		if skill:
			var ready = is_skill_ready(skill)
			var cooldown = get_skill_cooldown(skill)
			print("  Slot ", i + 1, ": ", skill, " - ", "READY" if ready else "CD: %.1fs" % cooldown)
		else:
			print("  Slot ", i + 1, ": [Empty]")

	print("\nUnlocked Skills:")
	var unlocked = get_unlocked_skills()
	for skill in unlocked:
		print("  - ", skill)

	var target = get_auto_attack_target()
	print("\nAuto-Attack Target: ", target.name if target else "None")
	print("==================\n")

func unlock_random_skill():
	"""Unlock a random skill (debug)"""
	if not ability_library or not ability_library.has_method("get_all_ability_names"):
		print("No ability library available")
		return

	var all_skills = ability_library.get_all_ability_names()
	var unlocked = get_unlocked_skills()

	# Find skills not yet unlocked
	var locked_skills = []
	for skill in all_skills:
		if skill not in unlocked:
			locked_skills.append(skill)

	if locked_skills.is_empty():
		print("All skills already unlocked!")
		return

	var random_skill = locked_skills[randi() % locked_skills.size()]
	unlock_skill(random_skill)
	print("🎁 Unlocked: ", random_skill)

func refill_resources():
	"""Refill all MP/Stamina (debug)"""
	if player and player.has_method("heal"):
		player.heal(9999)
	if player and player.has("mana"):
		player.mana = player.get("max_mana") if player.has("max_mana") else 100
	if player and player.has("stamina"):
		player.stamina = player.get("max_stamina") if player.has("max_stamina") else 100
	print("💙 Resources refilled")

func trigger_break_mode():
	"""Force trigger break mode (debug)"""
	if combat_controller and combat_controller.has_method("activate_break_mode"):
		combat_controller.activate_break_mode()
		print("💥 Break mode activated!")

# ============================================================================
# SIGNAL HANDLERS
# ============================================================================

func _on_skill_activated(skill_name: String):
	"""Handle skill activation"""
	print("⚔️ Skill activated: ", skill_name)
	skill_activated.emit(skill_name)

func _on_skill_unlocked(skill_name: String):
	"""Handle skill unlock"""
	print("🎓 Skill unlocked: ", skill_name)
	skill_unlocked.emit(skill_name)

func _on_break_mode_started():
	"""Handle break mode activation"""
	print("💥 BREAK MODE ACTIVATED!")
	break_mode_activated.emit()

func _on_break_mode_ended():
	"""Handle break mode end"""
	print("Break mode ended")
	break_mode_ended.emit()

# ============================================================================
# UTILITY
# ============================================================================

func _print_status():
	"""Print integration status"""
	print("\n=== DAI COMBAT INTEGRATION STATUS ===")
	print("  Combat Controller: ", "✓" if combat_controller else "✗")
	print("  Skill System: ", "✓" if skill_acquisition else "✗")
	print("  Combat UI: ", "✓" if combat_ui else "✗")
	print("  Ability Library: ", "✓" if ability_library else "✗")
	print("  Player: ", player.name if player else "Not found")
	print("  Starting Skills: ", starting_skills)
	print("\n  Controls:")
	print("    ", OS.get_keycode_string(skill_key_1), " - Skill Slot 1")
	print("    ", OS.get_keycode_string(skill_key_2), " - Skill Slot 2")
	print("    ", OS.get_keycode_string(skill_key_3), " - Skill Slot 3")
	print("    ", OS.get_keycode_string(skill_key_4), " - Skill Slot 4")
	if enable_debug_commands and OS.is_debug_build():
		print("\n  Debug Commands:")
		print("    F5 - Print skill status")
		print("    F6 - Unlock random skill")
		print("    F7 - Refill resources")
		print("    F8 - Trigger break mode")
	print("====================================\n")

# ============================================================================
# CLEANUP
# ============================================================================

func _exit_tree():
	"""Clean up when removed from scene"""
	# UI is in root, needs manual cleanup
	if combat_ui and is_instance_valid(combat_ui):
		combat_ui.queue_free()
