extends Node
class_name SkillAcquisitionSystem

## Skill Acquisition System
## Handles unlocking skills through equipment, scrolls, and skill fragments (DQ Dai style)

signal skill_unlocked(skill: AbilityData)
signal skill_upgraded(skill: AbilityData, new_level: int)
signal equipment_acquired(equipment: Equipment)
signal scroll_used(scroll: SkillScroll)
signal fragments_collected(skill_name: String, count: int)

enum AcquisitionMethod {
	EQUIPMENT,        # Unlock by equipping specific weapons/items
	SCROLL,           # One-time scroll to instantly unlock
	FRAGMENTS,        # Collect fragments to unlock
	LEVEL_UP,         # Unlock at specific player level
	QUEST_REWARD      # Unlock from quest/boss completion
}

# Player reference
var player: Node3D

# Unlocked skills database
var unlocked_skills: Dictionary = {}  # skill_name -> AbilityData
var equipped_skills: Array[AbilityData] = []  # Currently equipped skills (max 4)

# Skill fragments inventory
var skill_fragments: Dictionary = {}  # skill_name -> fragment_count
var fragments_required: Dictionary = {}  # skill_name -> total_fragments_needed

# Equipment inventory
var equipment_inventory: Array[Equipment] = []
var equipped_weapon: Equipment = null
var equipped_armor: Equipment = null
var equipped_accessory: Equipment = null

# Skill scrolls inventory
var scroll_inventory: Array[SkillScroll] = []

# Configuration
@export var max_equipped_skills: int = 4
@export var fragment_drop_rate: float = 0.3  # 30% chance to drop fragments


func _ready() -> void:
	setup_fragment_requirements()


func setup_fragment_requirements() -> void:
	"""Define how many fragments are needed for each skill"""
	# Basic skills - 10 fragments
	fragments_required["Air Slash"] = 10
	fragments_required["Gira"] = 10
	fragments_required["Hyado"] = 10
	fragments_required["Heal"] = 15

	# Advanced skills - 25 fragments
	fragments_required["Avan Strash"] = 25
	fragments_required["Io"] = 25
	fragments_required["Beast King Blitz"] = 30
	fragments_required["Twin Sword Flash"] = 30

	# Ultimate skills - 50 fragments
	fragments_required["Bloody Scryde"] = 50
	fragments_required["Gigastrash"] = 75


## Equipment System

func acquire_equipment(equipment: Equipment) -> void:
	"""Add equipment to inventory"""
	equipment_inventory.append(equipment)
	emit_signal("equipment_acquired", equipment)

	# Check if equipment grants skills
	if equipment.grants_skills:
		for skill_name in equipment.skill_list:
			unlock_skill_by_equipment(skill_name, equipment)


func equip_weapon(equipment: Equipment) -> bool:
	"""Equip a weapon"""
	if equipment.equipment_type != Equipment.EquipmentType.WEAPON:
		return false

	# Unequip current weapon skills
	if equipped_weapon:
		unequip_weapon_skills(equipped_weapon)

	equipped_weapon = equipment

	# Equip new weapon skills
	equip_weapon_skills(equipment)
	return true


func equip_weapon_skills(equipment: Equipment) -> void:
	"""Unlock skills granted by weapon"""
	if not equipment.grants_skills:
		return

	for skill_name in equipment.skill_list:
		var skill = DaiAbilityLibrary.get_ability_by_name(skill_name)
		if skill:
			skill.is_unlocked = true
			unlocked_skills[skill_name] = skill
			print("SkillAcquisition: Unlocked skill '", skill_name, "' from equipment!")


func unequip_weapon_skills(equipment: Equipment) -> void:
	"""Remove skills when equipment is unequipped (unless permanently unlocked)"""
	if not equipment.grants_skills:
		return

	for skill_name in equipment.skill_list:
		# Only remove if not permanently unlocked through other means
		if unlocked_skills.has(skill_name):
			var skill = unlocked_skills[skill_name]
			# Check if skill was unlocked via fragments or scrolls (permanent)
			if not is_skill_permanently_unlocked(skill_name):
				skill.is_unlocked = false
				unlocked_skills.erase(skill_name)


func is_skill_permanently_unlocked(skill_name: String) -> bool:
	"""Check if skill is permanently unlocked (not just from equipment)"""
	# Check if fragments were used
	if skill_fragments.get(skill_name, 0) >= fragments_required.get(skill_name, 999):
		return true

	# Check if scroll was used (would be marked in unlocked_skills metadata)
	if unlocked_skills.has(skill_name):
		var skill = unlocked_skills[skill_name]
		# Could add a custom property to AbilityData to track unlock method
		return true  # For now, assume unlocked skills are permanent

	return false


## Skill Scroll System

func use_skill_scroll(scroll: SkillScroll) -> bool:
	"""Use a scroll to instantly unlock a skill"""
	if not scroll_inventory.has(scroll):
		return false

	var skill = DaiAbilityLibrary.get_ability_by_name(scroll.skill_name)
	if not skill:
		return false

	# Unlock the skill permanently
	skill.is_unlocked = true
	unlocked_skills[scroll.skill_name] = skill

	# Remove scroll from inventory
	scroll_inventory.erase(scroll)

	emit_signal("scroll_used", scroll)
	emit_signal("skill_unlocked", skill)

	print("SkillAcquisition: Used scroll to unlock '", scroll.skill_name, "'!")
	return true


func add_scroll(scroll: SkillScroll) -> void:
	"""Add a skill scroll to inventory"""
	scroll_inventory.append(scroll)


## Skill Fragment System

func add_skill_fragments(skill_name: String, count: int = 1) -> void:
	"""Add skill fragments"""
	var current_count = skill_fragments.get(skill_name, 0)
	skill_fragments[skill_name] = current_count + count

	emit_signal("fragments_collected", skill_name, count)

	# Check if enough fragments to unlock
	check_fragment_unlock(skill_name)


func check_fragment_unlock(skill_name: String) -> void:
	"""Check if player has enough fragments to unlock skill"""
	var current = skill_fragments.get(skill_name, 0)
	var required = fragments_required.get(skill_name, 999)

	if current >= required:
		unlock_skill_by_fragments(skill_name)


func unlock_skill_by_fragments(skill_name: String) -> bool:
	"""Unlock a skill using fragments"""
	var current = skill_fragments.get(skill_name, 0)
	var required = fragments_required.get(skill_name, 999)

	if current < required:
		print("SkillAcquisition: Not enough fragments for '", skill_name, "'. Need ", required, ", have ", current)
		return false

	# Check if already unlocked
	if unlocked_skills.has(skill_name):
		print("SkillAcquisition: Skill '", skill_name, "' already unlocked!")
		return false

	var skill = DaiAbilityLibrary.get_ability_by_name(skill_name)
	if not skill:
		return false

	# Unlock permanently
	skill.is_unlocked = true
	unlocked_skills[skill_name] = skill

	emit_signal("skill_unlocked", skill)
	print("SkillAcquisition: Unlocked '", skill_name, "' using ", required, " fragments!")
	return true


func unlock_skill_by_equipment(skill_name: String, equipment: Equipment) -> void:
	"""Unlock skill via equipment"""
	var skill = DaiAbilityLibrary.get_ability_by_name(skill_name)
	if skill:
		skill.is_unlocked = true
		unlocked_skills[skill_name] = skill
		emit_signal("skill_unlocked", skill)


func get_fragment_progress(skill_name: String) -> Dictionary:
	"""Get fragment collection progress for a skill"""
	return {
		"current": skill_fragments.get(skill_name, 0),
		"required": fragments_required.get(skill_name, 0),
		"percentage": float(skill_fragments.get(skill_name, 0)) / float(fragments_required.get(skill_name, 1)) * 100.0
	}


## Skill Management

func equip_skill(skill: AbilityData, slot_index: int) -> bool:
	"""Equip a skill to a slot"""
	if slot_index < 0 or slot_index >= max_equipped_skills:
		return false

	if not skill.is_unlocked:
		return false

	# Ensure equipped_skills array is large enough
	while equipped_skills.size() <= slot_index:
		equipped_skills.append(null)

	equipped_skills[slot_index] = skill
	return true


func unequip_skill(slot_index: int) -> bool:
	"""Unequip a skill from a slot"""
	if slot_index < 0 or slot_index >= equipped_skills.size():
		return false

	equipped_skills[slot_index] = null
	return true


func get_equipped_skills() -> Array[AbilityData]:
	"""Get all currently equipped skills"""
	return equipped_skills


func get_unlocked_skills() -> Array[AbilityData]:
	"""Get all unlocked skills"""
	var skills: Array[AbilityData] = []
	for skill in unlocked_skills.values():
		skills.append(skill)
	return skills


func is_skill_unlocked(skill_name: String) -> bool:
	"""Check if a skill is unlocked"""
	return unlocked_skills.has(skill_name)


## Upgrade System

func upgrade_skill(skill_name: String) -> bool:
	"""Upgrade a skill to the next level"""
	if not unlocked_skills.has(skill_name):
		return false

	var skill = unlocked_skills[skill_name]
	if skill.upgrade_ability():
		emit_signal("skill_upgraded", skill, skill.current_level)
		print("SkillAcquisition: Upgraded '", skill_name, "' to level ", skill.current_level, "!")
		return true

	return false


## Drop System (for enemy defeats)

func roll_fragment_drop(enemy_type: String = "normal") -> Dictionary:
	"""Roll for skill fragment drops after defeating enemy"""
	if randf() > fragment_drop_rate:
		return {}  # No drop

	# Select random skill to drop fragments for
	var available_skills = fragments_required.keys()
	if available_skills.is_empty():
		return {}

	var skill_name = available_skills[randi() % available_skills.size()]

	# Determine fragment count (1-3 for normal, 3-5 for bosses)
	var fragment_count = 1
	if enemy_type == "boss":
		fragment_count = randi_range(3, 5)
	else:
		fragment_count = randi_range(1, 3)

	return {
		"skill_name": skill_name,
		"count": fragment_count
	}


func process_enemy_defeat(enemy_type: String = "normal") -> void:
	"""Process enemy defeat for drops"""
	var drop = roll_fragment_drop(enemy_type)
	if drop.has("skill_name"):
		add_skill_fragments(drop["skill_name"], drop["count"])
		print("SkillAcquisition: Dropped ", drop["count"], "x ", drop["skill_name"], " fragments!")


## Save/Load (for persistence)

func get_save_data() -> Dictionary:
	"""Get data for saving"""
	return {
		"unlocked_skills": unlocked_skills.keys(),
		"equipped_skills": equipped_skills.map(func(s): return s.ability_name if s else ""),
		"skill_fragments": skill_fragments,
		"equipped_weapon": equipped_weapon.equipment_name if equipped_weapon else ""
	}


func load_save_data(data: Dictionary) -> void:
	"""Load from saved data"""
	# Restore unlocked skills
	for skill_name in data.get("unlocked_skills", []):
		var skill = DaiAbilityLibrary.get_ability_by_name(skill_name)
		if skill:
			skill.is_unlocked = true
			unlocked_skills[skill_name] = skill

	# Restore equipped skills
	var equipped_names = data.get("equipped_skills", [])
	for i in range(equipped_names.size()):
		if equipped_names[i] != "":
			var skill = DaiAbilityLibrary.get_ability_by_name(equipped_names[i])
			if skill:
				equip_skill(skill, i)

	# Restore fragments
	skill_fragments = data.get("skill_fragments", {})


## Equipment and Scroll Resource Classes
## (Define these as separate Resource files if needed)

class Equipment:
	var equipment_name: String
	var equipment_type: EquipmentType
	var grants_skills: bool = false
	var skill_list: Array[String] = []
	var stat_bonuses: Dictionary = {}

	enum EquipmentType {
		WEAPON,
		ARMOR,
		ACCESSORY
	}


class SkillScroll:
	var scroll_name: String
	var skill_name: String
	var rarity: ScrollRarity

	enum ScrollRarity {
		COMMON,
		RARE,
		LEGENDARY
	}
