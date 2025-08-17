class_name PlayerStats
extends Resource

# Base stats
@export var level: int = 1
@export var experience: int = 0
@export var experience_to_next_level: int = 100

# Core attributes
@export var base_health: float = 100.0
@export var base_mana: float = 50.0
@export var base_attack: float = 10.0
@export var base_defense: float = 5.0
@export var base_speed: float = 12.0

# Derived stats (calculated from base stats + equipment + buffs)
var current_health: float
var max_health: float
var current_mana: float
var max_mana: float
var total_attack: float
var total_defense: float
var total_speed: float

# Skill points and abilities
@export var available_skill_points: int = 0
@export var warrior_points: int = 0
@export var mage_points: int = 0
@export var rogue_points: int = 0

# Status effects and buffs
var active_buffs: Array[Resource] = []
var status_effects: Array[Resource] = []

signal stats_changed()
signal level_up(new_level: int)
signal experience_gained(amount: int)

func _init():
	current_health = base_health
	max_health = base_health
	current_mana = base_mana
	max_mana = base_mana
	calculate_derived_stats()

func calculate_derived_stats():
	"""Calculate total stats from base stats, equipment, and buffs"""
	max_health = base_health
	max_mana = base_mana
	total_attack = base_attack
	total_defense = base_defense
	total_speed = base_speed
	
	# Apply equipment bonuses (will be implemented when equipment system is added)
	# Apply buff bonuses
	for buff in active_buffs:
		if buff.stat_type == "health":
			max_health += buff.value
		elif buff.stat_type == "mana":
			max_mana += buff.value
		elif buff.stat_type == "attack":
			total_attack += buff.value
		elif buff.stat_type == "defense":
			total_defense += buff.value
		elif buff.stat_type == "speed":
			total_speed += buff.value
	
	# Ensure current health/mana don't exceed maximums
	current_health = min(current_health, max_health)
	current_mana = min(current_mana, max_mana)
	
	stats_changed.emit()

func gain_experience(amount: int):
	"""Add experience and handle level ups"""
	experience += amount
	experience_gained.emit(amount)
	
	# Check for level up
	while experience >= experience_to_next_level:
		level_up_player()

func level_up_player():
	"""Handle level up progression"""
	experience -= experience_to_next_level
	level += 1
	
	# Increase base stats on level up
	base_health += 10.0
	base_mana += 5.0
	base_attack += 2.0
	base_defense += 1.0
	
	# Grant skill points
	available_skill_points += 1
	
	# Calculate new experience requirement (increases by 20% each level)
	experience_to_next_level = int(experience_to_next_level * 1.2)
	
	# Fully heal on level up
	current_health = max_health
	current_mana = max_mana
	
	calculate_derived_stats()
	level_up.emit(level)

func allocate_skill_point(skill_tree: String) -> bool:
	"""Allocate a skill point to a specific skill tree"""
	if available_skill_points <= 0:
		return false
	
	match skill_tree:
		"warrior":
			warrior_points += 1
			base_health += 5.0
			base_attack += 1.0
		"mage":
			mage_points += 1
			base_mana += 10.0
			base_attack += 0.5
		"rogue":
			rogue_points += 1
			base_speed += 1.0
			base_attack += 1.5
		_:
			return false
	
	available_skill_points -= 1
	calculate_derived_stats()
	return true

func take_damage(amount: float) -> float:
	"""Apply damage with defense calculation"""
	var actual_damage = max(1.0, amount - (total_defense * 0.5))
	current_health = max(0.0, current_health - actual_damage)
	stats_changed.emit()
	return actual_damage

func heal(amount: float) -> float:
	"""Heal the player, returns actual amount healed"""
	var actual_heal = min(amount, max_health - current_health)
	current_health += actual_heal
	stats_changed.emit()
	return actual_heal

func use_mana(amount: float) -> bool:
	"""Use mana for abilities, returns true if successful"""
	if current_mana >= amount:
		current_mana -= amount
		stats_changed.emit()
		return true
	return false

func restore_mana(amount: float) -> float:
	"""Restore mana, returns actual amount restored"""
	var actual_restore = min(amount, max_mana - current_mana)
	current_mana += actual_restore
	stats_changed.emit()
	return actual_restore

func add_buff(buff: Resource):
	"""Add a temporary stat buff"""
	active_buffs.append(buff)
	calculate_derived_stats()

func remove_buff(buff: Resource):
	"""Remove a stat buff"""
	active_buffs.erase(buff)
	calculate_derived_stats()

func get_health_percentage() -> float:
	"""Get current health as a percentage"""
	return current_health / max_health if max_health > 0 else 0.0

func get_mana_percentage() -> float:
	"""Get current mana as a percentage"""
	return current_mana / max_mana if max_mana > 0 else 0.0

func is_alive() -> bool:
	"""Check if player is alive"""
	return current_health > 0