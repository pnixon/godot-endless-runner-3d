class_name LevelUpSystem
extends Node

# Level Up System handles level progression, stat increases, and ability unlocks
# Provides a centralized system for managing character advancement

signal level_up_processed(new_level: int, stat_increases: Dictionary, new_abilities: Array[String])
signal skill_point_allocated(skill_tree: String, points_spent: int)
signal ability_unlocked(ability_id: String, skill_tree: String)

var player_data: PlayerData
var level_up_effects: Array[Dictionary] = []

# Level up stat progression tables
const LEVEL_UP_STATS = {
	"base_health": 10.0,
	"base_mana": 5.0,
	"base_attack": 2.0,
	"base_defense": 1.0
}

# Skill tree ability unlock requirements
const SKILL_TREE_ABILITIES = {
	"warrior": {
		1: ["warrior_charge", "Warrior Charge", "Charge forward dealing damage"],
		3: ["warrior_shield", "Shield Bash", "Bash enemies with shield for damage and stun"],
		5: ["warrior_berserker", "Berserker Rage", "Increase attack speed and damage"],
		7: ["warrior_taunt", "Taunt", "Force enemies to target you"],
		10: ["warrior_whirlwind", "Whirlwind", "Spin attack hitting all nearby enemies"]
	},
	"mage": {
		1: ["mage_fireball", "Fireball", "Launch a fireball at enemies"],
		3: ["mage_heal", "Healing Light", "Restore health to self or allies"],
		5: ["mage_lightning", "Lightning Storm", "Strike multiple enemies with lightning"],
		7: ["mage_shield", "Mana Shield", "Absorb damage using mana"],
		10: ["mage_meteor", "Meteor", "Devastating area attack"]
	},
	"rogue": {
		1: ["rogue_dash", "Shadow Dash", "Quickly dash through enemies"],
		3: ["rogue_stealth", "Stealth", "Become invisible for a short time"],
		5: ["rogue_poison", "Poison Strike", "Attacks apply poison damage"],
		7: ["rogue_backstab", "Backstab", "Critical damage from behind"],
		10: ["rogue_assassinate", "Assassinate", "Instant kill low-health enemies"]
	}
}

# Experience requirements per level (exponential growth)
const BASE_XP_REQUIREMENT = 100
const XP_GROWTH_RATE = 1.2

func initialize(data: PlayerData):
	"""Initialize the level up system with player data"""
	player_data = data
	
	if player_data and player_data.stats:
		# Connect to level up signal
		player_data.stats.level_up.connect(_on_level_up)
		
		# Ensure experience requirements are set correctly
		update_experience_requirements()
	
	print("LevelUpSystem initialized")

func update_experience_requirements():
	"""Update experience requirements based on current level"""
	if not player_data or not player_data.stats:
		return
	
	var stats = player_data.stats
	var required_xp = calculate_xp_requirement(stats.level)
	stats.experience_to_next_level = required_xp
	
	print("Updated XP requirement for level ", stats.level, ": ", required_xp)

func calculate_xp_requirement(level: int) -> int:
	"""Calculate experience requirement for a specific level"""
	return int(BASE_XP_REQUIREMENT * pow(XP_GROWTH_RATE, level - 1))

func _on_level_up(new_level: int):
	"""Handle level up event from PlayerStats"""
	print("Processing level up to level ", new_level)
	
	# Calculate stat increases
	var stat_increases = calculate_level_up_stats(new_level)
	
	# Check for new ability unlocks
	var new_abilities = check_ability_unlocks(new_level)
	
	# Update experience requirement for next level
	update_experience_requirements()
	
	# Create level up effect data
	var level_up_data = {
		"level": new_level,
		"stat_increases": stat_increases,
		"new_abilities": new_abilities,
		"timestamp": Time.get_unix_time_from_system()
	}
	
	level_up_effects.append(level_up_data)
	
	# Emit processed signal
	level_up_processed.emit(new_level, stat_increases, new_abilities)
	
	print("Level up processed: Level ", new_level, ", Stats: ", stat_increases, ", Abilities: ", new_abilities)

func calculate_level_up_stats(level: int) -> Dictionary:
	"""Calculate stat increases for level up"""
	var increases = {}
	
	# Base stat increases per level
	for stat_name in LEVEL_UP_STATS:
		increases[stat_name] = LEVEL_UP_STATS[stat_name]
	
	# Bonus increases every 5 levels
	if level % 5 == 0:
		increases["base_health"] += 5.0
		increases["base_attack"] += 1.0
		print("Bonus stats for level ", level, "!")
	
	# Bonus increases every 10 levels
	if level % 10 == 0:
		increases["base_health"] += 10.0
		increases["base_mana"] += 10.0
		increases["base_attack"] += 2.0
		increases["base_defense"] += 2.0
		print("Major bonus stats for level ", level, "!")
	
	return increases

func check_ability_unlocks(level: int) -> Array[String]:
	"""Check for new ability unlocks based on level and skill points"""
	var new_abilities: Array[String] = []
	
	if not player_data or not player_data.stats:
		return new_abilities
	
	var stats = player_data.stats
	
	# Check warrior abilities
	new_abilities.append_array(check_skill_tree_unlocks("warrior", stats.warrior_points))
	
	# Check mage abilities
	new_abilities.append_array(check_skill_tree_unlocks("mage", stats.mage_points))
	
	# Check rogue abilities
	new_abilities.append_array(check_skill_tree_unlocks("rogue", stats.rogue_points))
	
	return new_abilities

func check_skill_tree_unlocks(skill_tree: String, points: int) -> Array[String]:
	"""Check for ability unlocks in a specific skill tree"""
	var unlocked_abilities: Array[String] = []
	
	if not SKILL_TREE_ABILITIES.has(skill_tree):
		return unlocked_abilities
	
	var tree_abilities = SKILL_TREE_ABILITIES[skill_tree]
	var existing_abilities = get_existing_abilities(skill_tree)
	
	# Check each ability requirement
	for required_points in tree_abilities:
		if points >= required_points:
			var ability_data = tree_abilities[required_points]
			var ability_id = ability_data[0]
			
			# Only unlock if not already unlocked
			if not ability_id in existing_abilities:
				unlocked_abilities.append(ability_id)
				unlock_ability(ability_id, skill_tree)
				
				var ability_name = ability_data[1]
				print("Unlocked ", skill_tree, " ability: ", ability_name)
				ability_unlocked.emit(ability_id, skill_tree)
	
	return unlocked_abilities

func get_existing_abilities(skill_tree: String) -> Array[String]:
	"""Get existing unlocked abilities for a skill tree"""
	if not player_data:
		return []
	
	match skill_tree:
		"warrior":
			return player_data.unlocked_warrior_abilities
		"mage":
			return player_data.unlocked_mage_abilities
		"rogue":
			return player_data.unlocked_rogue_abilities
		_:
			return []

func unlock_ability(ability_id: String, skill_tree: String):
	"""Unlock an ability in the specified skill tree"""
	if not player_data:
		return
	
	match skill_tree:
		"warrior":
			if not ability_id in player_data.unlocked_warrior_abilities:
				player_data.unlocked_warrior_abilities.append(ability_id)
		"mage":
			if not ability_id in player_data.unlocked_mage_abilities:
				player_data.unlocked_mage_abilities.append(ability_id)
		"rogue":
			if not ability_id in player_data.unlocked_rogue_abilities:
				player_data.unlocked_rogue_abilities.append(ability_id)
	
	# Also add to general unlocked abilities
	if not ability_id in player_data.unlocked_abilities:
		player_data.unlocked_abilities.append(ability_id)

func allocate_skill_point(skill_tree: String) -> bool:
	"""Allocate a skill point to a specific skill tree"""
	if not player_data or not player_data.stats:
		return false
	
	var stats = player_data.stats
	
	# Check if player has available skill points
	if stats.available_skill_points <= 0:
		print("No skill points available")
		return false
	
	# Allocate point to the specified tree
	var success = stats.allocate_skill_point(skill_tree)
	
	if success:
		# Check for new ability unlocks
		var new_abilities = check_skill_tree_unlocks(skill_tree, get_skill_tree_points(skill_tree))
		
		skill_point_allocated.emit(skill_tree, 1)
		print("Allocated skill point to ", skill_tree, " tree")
		
		# Emit ability unlock signals for any new abilities
		for ability_id in new_abilities:
			ability_unlocked.emit(ability_id, skill_tree)
	
	return success

func get_skill_tree_points(skill_tree: String) -> int:
	"""Get current points in a skill tree"""
	if not player_data or not player_data.stats:
		return 0
	
	var stats = player_data.stats
	
	match skill_tree:
		"warrior":
			return stats.warrior_points
		"mage":
			return stats.mage_points
		"rogue":
			return stats.rogue_points
		_:
			return 0

func get_available_abilities(skill_tree: String) -> Array[Dictionary]:
	"""Get all available abilities for a skill tree with their requirements"""
	var abilities: Array[Dictionary] = []
	
	if not SKILL_TREE_ABILITIES.has(skill_tree):
		return abilities
	
	var tree_abilities = SKILL_TREE_ABILITIES[skill_tree]
	var current_points = get_skill_tree_points(skill_tree)
	var unlocked_abilities = get_existing_abilities(skill_tree)
	
	for required_points in tree_abilities:
		var ability_data = tree_abilities[required_points]
		var ability_info = {
			"id": ability_data[0],
			"name": ability_data[1],
			"description": ability_data[2],
			"required_points": required_points,
			"is_unlocked": ability_data[0] in unlocked_abilities,
			"can_unlock": current_points >= required_points and not ability_data[0] in unlocked_abilities
		}
		abilities.append(ability_info)
	
	return abilities

func get_next_level_preview() -> Dictionary:
	"""Get preview of what the next level will provide"""
	if not player_data or not player_data.stats:
		return {}
	
	var stats = player_data.stats
	var next_level = stats.level + 1
	
	var preview = {
		"level": next_level,
		"xp_required": stats.experience_to_next_level - stats.experience,
		"stat_increases": calculate_level_up_stats(next_level),
		"skill_points_gained": 1,
		"potential_abilities": []
	}
	
	# Check what abilities could be unlocked with one more skill point
	for skill_tree in ["warrior", "mage", "rogue"]:
		var current_points = get_skill_tree_points(skill_tree)
		var potential_abilities = check_skill_tree_unlocks(skill_tree, current_points + 1)
		if not potential_abilities.is_empty():
			preview.potential_abilities.append({
				"skill_tree": skill_tree,
				"abilities": potential_abilities
			})
	
	return preview

func get_level_up_history() -> Array[Dictionary]:
	"""Get history of recent level ups"""
	return level_up_effects.duplicate()

func clear_level_up_history():
	"""Clear level up history"""
	level_up_effects.clear()

func get_total_stat_increases() -> Dictionary:
	"""Get total stat increases from all level ups"""
	var totals = {}
	
	for level_up_data in level_up_effects:
		var increases = level_up_data.stat_increases
		for stat_name in increases:
			if totals.has(stat_name):
				totals[stat_name] += increases[stat_name]
			else:
				totals[stat_name] = increases[stat_name]
	
	return totals

func simulate_level_up(target_level: int) -> Dictionary:
	"""Simulate what stats and abilities would be at target level"""
	if not player_data or not player_data.stats:
		return {}
	
	var current_level = player_data.stats.level
	if target_level <= current_level:
		return {}
	
	var simulation = {
		"levels_gained": target_level - current_level,
		"total_stat_increases": {},
		"skill_points_gained": target_level - current_level,
		"potential_abilities": {}
	}
	
	# Calculate total stat increases
	for level in range(current_level + 1, target_level + 1):
		var increases = calculate_level_up_stats(level)
		for stat_name in increases:
			if simulation.total_stat_increases.has(stat_name):
				simulation.total_stat_increases[stat_name] += increases[stat_name]
			else:
				simulation.total_stat_increases[stat_name] = increases[stat_name]
	
	# Calculate potential abilities for each skill tree
	for skill_tree in ["warrior", "mage", "rogue"]:
		var current_points = get_skill_tree_points(skill_tree)
		var max_possible_points = current_points + simulation.skill_points_gained
		var abilities = get_available_abilities(skill_tree)
		
		var unlockable = []
		for ability in abilities:
			if not ability.is_unlocked and ability.required_points <= max_possible_points:
				unlockable.append(ability)
		
		simulation.potential_abilities[skill_tree] = unlockable
	
	return simulation

func debug_level_system():
	"""Debug information about the level system"""
	print("=== LEVEL SYSTEM DEBUG ===")
	if player_data and player_data.stats:
		var stats = player_data.stats
		print("Current Level: ", stats.level)
		print("Experience: ", stats.experience, "/", stats.experience_to_next_level)
		print("Available Skill Points: ", stats.available_skill_points)
		print("Warrior Points: ", stats.warrior_points)
		print("Mage Points: ", stats.mage_points)
		print("Rogue Points: ", stats.rogue_points)
		
		print("\nUnlocked Abilities:")
		print("Warrior: ", player_data.unlocked_warrior_abilities)
		print("Mage: ", player_data.unlocked_mage_abilities)
		print("Rogue: ", player_data.unlocked_rogue_abilities)
		
		print("\nNext Level Preview:")
		var preview = get_next_level_preview()
		print(preview)
	else:
		print("No player data available")
	print("==========================")