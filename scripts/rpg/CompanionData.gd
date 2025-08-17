class_name CompanionData
extends Resource

# Companion identification
@export var companion_id: String
@export var name: String
@export var description: String
@export var portrait_path: String

# Companion class and role
@export var class_type: CompanionClass
@export var role: CompanionRole

# Stats and progression
@export var level: int = 1
@export var bond_level: int = 1
@export var experience: int = 0
@export var base_health: float = 80.0
@export var base_attack: float = 8.0
@export var base_defense: float = 4.0
@export var base_speed: float = 10.0

# Equipment
@export var equipped_weapon: Equipment
@export var equipped_armor: Equipment
@export var equipped_accessory: Equipment

# Abilities and skills
@export var unlocked_abilities: Array[String] = []
@export var class_abilities: Array[String] = []
@export var bond_abilities: Array[String] = []

# Bond system
@export var bond_experience: int = 0
@export var bond_conversations: Array[String] = []
@export var completed_conversations: Array[String] = []
@export var relationship_status: String = "Acquaintance"

# AI behavior settings
@export var aggression_level: float = 0.5  # 0.0 = defensive, 1.0 = aggressive
@export var support_priority: float = 0.5  # 0.0 = self-focused, 1.0 = team-focused
@export var ability_usage_frequency: float = 0.7  # How often to use abilities

# Companion availability and story
@export var is_unlocked: bool = false
@export var unlock_chapter: int = 1
@export var unlock_mission: String = ""
@export var story_flags: Array[String] = []

# Visual and audio
@export var model_path: String
@export var animation_set: String
@export var voice_lines: Dictionary = {}

signal bond_level_changed(new_level: int)
signal ability_unlocked(ability_id: String)
signal conversation_completed(conversation_id: String)
signal stats_changed()

enum CompanionClass {
	WARRIOR,
	MAGE,
	ROGUE,
	TANK,
	HEALER,
	SUPPORT
}

enum CompanionRole {
	TANK,      # High health, draws enemy attention, defensive abilities
	HEALER,    # Support abilities, healing, buffs
	DPS,       # High damage output, offensive abilities
	SUPPORT    # Utility abilities, debuffs, crowd control
}

func _init():
	# Set default abilities based on class
	setup_class_abilities()

func setup_class_abilities():
	"""Set up default abilities based on companion class"""
	match class_type:
		CompanionClass.WARRIOR:
			class_abilities = ["warrior_strike", "defensive_stance", "taunt"]
			role = CompanionRole.TANK
		CompanionClass.MAGE:
			class_abilities = ["magic_missile", "heal", "mana_shield"]
			role = CompanionRole.HEALER
		CompanionClass.ROGUE:
			class_abilities = ["backstab", "stealth", "poison_dart"]
			role = CompanionRole.DPS
		CompanionClass.TANK:
			class_abilities = ["shield_bash", "provoke", "armor_up"]
			role = CompanionRole.TANK
		CompanionClass.HEALER:
			class_abilities = ["group_heal", "cure", "blessing"]
			role = CompanionRole.HEALER
		CompanionClass.SUPPORT:
			class_abilities = ["buff_allies", "debuff_enemies", "crowd_control"]
			role = CompanionRole.SUPPORT

func get_total_health() -> float:
	"""Calculate total health including equipment bonuses"""
	var total = base_health + (level * 5.0)  # 5 HP per level
	
	if equipped_armor:
		total += equipped_armor.get_stat_bonus("health")
	if equipped_accessory:
		total += equipped_accessory.get_stat_bonus("health")
	
	return total

func get_total_attack() -> float:
	"""Calculate total attack including equipment bonuses"""
	var total = base_attack + (level * 1.5)  # 1.5 attack per level
	
	if equipped_weapon:
		total += equipped_weapon.get_stat_bonus("attack")
	if equipped_accessory:
		total += equipped_accessory.get_stat_bonus("attack")
	
	return total

func get_total_defense() -> float:
	"""Calculate total defense including equipment bonuses"""
	var total = base_defense + (level * 1.0)  # 1 defense per level
	
	if equipped_armor:
		total += equipped_armor.get_stat_bonus("defense")
	if equipped_accessory:
		total += equipped_accessory.get_stat_bonus("defense")
	
	return total

func get_total_speed() -> float:
	"""Calculate total speed including equipment bonuses"""
	var total = base_speed
	
	if equipped_weapon:
		total += equipped_weapon.get_stat_bonus("speed")
	if equipped_armor:
		total += equipped_armor.get_stat_bonus("speed")
	if equipped_accessory:
		total += equipped_accessory.get_stat_bonus("speed")
	
	return total

func gain_experience(amount: int):
	"""Add experience and handle level ups"""
	experience += amount
	
	var exp_needed = level * 80  # Experience needed for next level
	while experience >= exp_needed:
		level_up()
		exp_needed = level * 80

func level_up():
	"""Handle companion level up"""
	experience -= level * 80
	level += 1
	
	# Increase base stats
	base_health += 8.0
	base_attack += 1.2
	base_defense += 0.8
	
	# Check for new ability unlocks
	check_ability_unlocks()
	
	stats_changed.emit()
	print(name, " leveled up to level ", level, "!")

func gain_bond_experience(amount: int):
	"""Add bond experience and handle bond level ups"""
	bond_experience += amount
	
	var bond_exp_needed = bond_level * 100  # Bond experience needed for next level
	while bond_experience >= bond_exp_needed:
		bond_level_up()
		bond_exp_needed = bond_level * 100

func bond_level_up():
	"""Handle bond level increase"""
	bond_experience -= bond_level * 100
	bond_level += 1
	
	# Update relationship status
	update_relationship_status()
	
	# Unlock bond abilities
	check_bond_ability_unlocks()
	
	bond_level_changed.emit(bond_level)
	print("Bond with ", name, " increased to level ", bond_level, "!")

func update_relationship_status():
	"""Update relationship status based on bond level"""
	match bond_level:
		1, 2:
			relationship_status = "Acquaintance"
		3, 4:
			relationship_status = "Friend"
		5, 6:
			relationship_status = "Close Friend"
		7, 8:
			relationship_status = "Trusted Ally"
		9, 10:
			relationship_status = "Loyal Companion"
		_:
			relationship_status = "Unbreakable Bond"

func check_ability_unlocks():
	"""Check for new abilities based on level"""
	var new_abilities = []
	
	# Level-based ability unlocks
	if level >= 3 and not "advanced_attack" in unlocked_abilities:
		unlocked_abilities.append("advanced_attack")
		new_abilities.append("Advanced Attack")
	
	if level >= 5 and not "special_ability" in unlocked_abilities:
		unlocked_abilities.append("special_ability")
		new_abilities.append("Special Ability")
	
	if level >= 8 and not "ultimate_ability" in unlocked_abilities:
		unlocked_abilities.append("ultimate_ability")
		new_abilities.append("Ultimate Ability")
	
	# Emit signals for new abilities
	for ability in new_abilities:
		ability_unlocked.emit(ability)

func check_bond_ability_unlocks():
	"""Check for new bond abilities based on bond level"""
	var new_abilities = []
	
	# Bond-based ability unlocks
	if bond_level >= 2 and not "bond_boost" in bond_abilities:
		bond_abilities.append("bond_boost")
		new_abilities.append("Bond Boost")
	
	if bond_level >= 4 and not "combo_attack" in bond_abilities:
		bond_abilities.append("combo_attack")
		new_abilities.append("Combo Attack")
	
	if bond_level >= 6 and not "protective_instinct" in bond_abilities:
		bond_abilities.append("protective_instinct")
		new_abilities.append("Protective Instinct")
	
	if bond_level >= 8 and not "synchronized_strike" in bond_abilities:
		bond_abilities.append("synchronized_strike")
		new_abilities.append("Synchronized Strike")
	
	# Emit signals for new abilities
	for ability in new_abilities:
		ability_unlocked.emit(ability)

func equip_item(item: Equipment, slot: String) -> bool:
	"""Equip an item to the companion"""
	if not item or item.slot != slot:
		return false
	
	match slot:
		"weapon":
			equipped_weapon = item
		"armor":
			equipped_armor = item
		"accessory":
			equipped_accessory = item
		_:
			return false
	
	stats_changed.emit()
	return true

func unequip_item(slot: String) -> Equipment:
	"""Unequip an item from the companion"""
	var unequipped_item: Equipment = null
	
	match slot:
		"weapon":
			unequipped_item = equipped_weapon
			equipped_weapon = null
		"armor":
			unequipped_item = equipped_armor
			equipped_armor = null
		"accessory":
			unequipped_item = equipped_accessory
			equipped_accessory = null
	
	if unequipped_item:
		stats_changed.emit()
	
	return unequipped_item

func has_ability(ability_id: String) -> bool:
	"""Check if companion has a specific ability"""
	return (ability_id in class_abilities or 
			ability_id in unlocked_abilities or 
			ability_id in bond_abilities)

func get_available_conversations() -> Array[String]:
	"""Get list of available conversations based on bond level and story progress"""
	var available = []
	
	for conversation_id in bond_conversations:
		if not conversation_id in completed_conversations:
			# Check if conversation requirements are met
			if can_start_conversation(conversation_id):
				available.append(conversation_id)
	
	return available

func can_start_conversation(conversation_id: String) -> bool:
	"""Check if a conversation can be started"""
	# This would check bond level requirements, story flags, etc.
	# For now, just check if it's not completed
	return not conversation_id in completed_conversations

func complete_conversation(conversation_id: String):
	"""Mark a conversation as completed and gain bond experience"""
	if not conversation_id in completed_conversations:
		completed_conversations.append(conversation_id)
		gain_bond_experience(25)  # Conversations give bond experience
		conversation_completed.emit(conversation_id)
		print("Completed conversation with ", name, ": ", conversation_id)

func get_ai_behavior_data() -> Dictionary:
	"""Get AI behavior settings for combat"""
	return {
		"role": role,
		"aggression_level": aggression_level,
		"support_priority": support_priority,
		"ability_usage_frequency": ability_usage_frequency,
		"available_abilities": get_all_abilities()
	}

func get_all_abilities() -> Array[String]:
	"""Get all available abilities"""
	var all_abilities = []
	all_abilities.append_array(class_abilities)
	all_abilities.append_array(unlocked_abilities)
	all_abilities.append_array(bond_abilities)
	return all_abilities

func unlock_companion():
	"""Unlock this companion for recruitment"""
	is_unlocked = true
	print("Companion unlocked: ", name)

func add_story_flag(flag: String):
	"""Add a story flag for this companion"""
	if not flag in story_flags:
		story_flags.append(flag)

func has_story_flag(flag: String) -> bool:
	"""Check if companion has a specific story flag"""
	return flag in story_flags

func get_save_data() -> Dictionary:
	"""Get companion data for saving"""
	return {
		"companion_id": companion_id,
		"name": name,
		"description": description,
		"class_type": class_type,
		"role": role,
		"level": level,
		"bond_level": bond_level,
		"experience": experience,
		"bond_experience": bond_experience,
		"base_health": base_health,
		"base_attack": base_attack,
		"base_defense": base_defense,
		"base_speed": base_speed,
		"equipped_weapon": equipped_weapon,
		"equipped_armor": equipped_armor,
		"equipped_accessory": equipped_accessory,
		"unlocked_abilities": unlocked_abilities,
		"bond_abilities": bond_abilities,
		"completed_conversations": completed_conversations,
		"relationship_status": relationship_status,
		"is_unlocked": is_unlocked,
		"story_flags": story_flags,
		"aggression_level": aggression_level,
		"support_priority": support_priority,
		"ability_usage_frequency": ability_usage_frequency
	}

func load_save_data(data: Dictionary):
	"""Load companion data from save"""
	companion_id = data.get("companion_id", "")
	name = data.get("name", "")
	description = data.get("description", "")
	class_type = data.get("class_type", CompanionClass.WARRIOR)
	role = data.get("role", CompanionRole.TANK)
	level = data.get("level", 1)
	bond_level = data.get("bond_level", 1)
	experience = data.get("experience", 0)
	bond_experience = data.get("bond_experience", 0)
	base_health = data.get("base_health", 80.0)
	base_attack = data.get("base_attack", 8.0)
	base_defense = data.get("base_defense", 4.0)
	base_speed = data.get("base_speed", 10.0)
	equipped_weapon = data.get("equipped_weapon", null)
	equipped_armor = data.get("equipped_armor", null)
	equipped_accessory = data.get("equipped_accessory", null)
	unlocked_abilities = data.get("unlocked_abilities", [])
	bond_abilities = data.get("bond_abilities", [])
	completed_conversations = data.get("completed_conversations", [])
	relationship_status = data.get("relationship_status", "Acquaintance")
	is_unlocked = data.get("is_unlocked", false)
	story_flags = data.get("story_flags", [])
	aggression_level = data.get("aggression_level", 0.5)
	support_priority = data.get("support_priority", 0.5)
	ability_usage_frequency = data.get("ability_usage_frequency", 0.7)