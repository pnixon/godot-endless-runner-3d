class_name AbilitySystem
extends Node

# Ability System handles skill execution, cooldowns, and resource management
# Integrates with the lane-based combat system for tactical ability usage

signal ability_used(ability_id: String, success: bool)
signal ability_cooldown_started(ability_id: String, duration: float)
signal ability_ready(ability_id: String)
signal resource_insufficient(ability_id: String, resource_type: String, required: float, available: float)

var player_node: Node3D
var player_data: PlayerData
var active_cooldowns: Dictionary = {}  # ability_id -> remaining_time
var ability_definitions: Dictionary = {}
var queued_abilities: Array[String] = []

# Ability execution context
var current_lane: int = 1
var current_row: int = 1
var is_in_combat: bool = false

func _ready():
	"""Initialize ability system"""
	# Load ability definitions
	load_ability_definitions()
	
	# Set up cooldown processing
	set_process(true)

func initialize(player: Node3D, data: PlayerData):
	"""Initialize with player references"""
	player_node = player
	player_data = data
	
	# Connect to player signals if available
	if player_node.has_signal("stats_changed"):
		player_node.stats_changed.connect(_on_player_stats_changed)
	
	print("AbilitySystem initialized")

func load_ability_definitions():
	"""Load all ability definitions"""
	ability_definitions = {
		# Warrior Abilities
		"warrior_charge": {
			"name": "Warrior Charge",
			"description": "Charge forward dealing damage to enemies in your path",
			"cooldown": 8.0,
			"mana_cost": 20.0,
			"stamina_cost": 0.0,
			"cast_time": 0.5,
			"range": 3,
			"damage": 25.0,
			"effects": ["forward_movement", "damage_enemies"],
			"skill_tree": "warrior"
		},
		"warrior_shield": {
			"name": "Shield Bash",
			"description": "Bash enemies with shield for damage and brief stun",
			"cooldown": 6.0,
			"mana_cost": 15.0,
			"stamina_cost": 10.0,
			"cast_time": 0.3,
			"range": 1,
			"damage": 20.0,
			"effects": ["damage_enemies", "stun"],
			"skill_tree": "warrior"
		},
		"warrior_berserker": {
			"name": "Berserker Rage",
			"description": "Increase attack speed and damage for a duration",
			"cooldown": 15.0,
			"mana_cost": 30.0,
			"stamina_cost": 0.0,
			"cast_time": 0.2,
			"range": 0,
			"damage": 0.0,
			"effects": ["buff_attack_speed", "buff_damage"],
			"duration": 10.0,
			"skill_tree": "warrior"
		},
		"warrior_taunt": {
			"name": "Taunt",
			"description": "Force nearby enemies to target you",
			"cooldown": 12.0,
			"mana_cost": 10.0,
			"stamina_cost": 0.0,
			"cast_time": 0.1,
			"range": 2,
			"damage": 0.0,
			"effects": ["taunt_enemies"],
			"duration": 5.0,
			"skill_tree": "warrior"
		},
		"warrior_whirlwind": {
			"name": "Whirlwind",
			"description": "Spin attack hitting all nearby enemies",
			"cooldown": 20.0,
			"mana_cost": 40.0,
			"stamina_cost": 20.0,
			"cast_time": 1.0,
			"range": 2,
			"damage": 35.0,
			"effects": ["area_damage", "knockback"],
			"skill_tree": "warrior"
		},
		
		# Mage Abilities
		"mage_fireball": {
			"name": "Fireball",
			"description": "Launch a fireball at enemies in target lane",
			"cooldown": 4.0,
			"mana_cost": 25.0,
			"stamina_cost": 0.0,
			"cast_time": 0.8,
			"range": 4,
			"damage": 30.0,
			"effects": ["projectile", "fire_damage"],
			"skill_tree": "mage"
		},
		"mage_heal": {
			"name": "Healing Light",
			"description": "Restore health to self or companions",
			"cooldown": 10.0,
			"mana_cost": 30.0,
			"stamina_cost": 0.0,
			"cast_time": 1.0,
			"range": 0,
			"damage": 0.0,
			"effects": ["heal_self", "heal_companions"],
			"heal_amount": 40.0,
			"skill_tree": "mage"
		},
		"mage_lightning": {
			"name": "Lightning Storm",
			"description": "Strike multiple enemies with chain lightning",
			"cooldown": 12.0,
			"mana_cost": 35.0,
			"stamina_cost": 0.0,
			"cast_time": 1.2,
			"range": 3,
			"damage": 25.0,
			"effects": ["chain_lightning", "stun"],
			"max_targets": 3,
			"skill_tree": "mage"
		},
		"mage_shield": {
			"name": "Mana Shield",
			"description": "Absorb damage using mana instead of health",
			"cooldown": 18.0,
			"mana_cost": 20.0,
			"stamina_cost": 0.0,
			"cast_time": 0.5,
			"range": 0,
			"damage": 0.0,
			"effects": ["mana_shield"],
			"duration": 15.0,
			"skill_tree": "mage"
		},
		"mage_meteor": {
			"name": "Meteor",
			"description": "Devastating area attack with long cast time",
			"cooldown": 25.0,
			"mana_cost": 50.0,
			"stamina_cost": 0.0,
			"cast_time": 2.0,
			"range": 4,
			"damage": 60.0,
			"effects": ["area_damage", "knockdown"],
			"area_size": 2,
			"skill_tree": "mage"
		},
		
		# Rogue Abilities
		"rogue_dash": {
			"name": "Shadow Dash",
			"description": "Quickly dash through enemies, avoiding damage",
			"cooldown": 6.0,
			"mana_cost": 15.0,
			"stamina_cost": 20.0,
			"cast_time": 0.2,
			"range": 2,
			"damage": 15.0,
			"effects": ["dash_movement", "invulnerability"],
			"duration": 0.5,
			"skill_tree": "rogue"
		},
		"rogue_stealth": {
			"name": "Stealth",
			"description": "Become invisible and avoid enemy attacks",
			"cooldown": 15.0,
			"mana_cost": 25.0,
			"stamina_cost": 0.0,
			"cast_time": 0.3,
			"range": 0,
			"damage": 0.0,
			"effects": ["invisibility", "speed_boost"],
			"duration": 8.0,
			"skill_tree": "rogue"
		},
		"rogue_poison": {
			"name": "Poison Strike",
			"description": "Next attacks apply poison damage over time",
			"cooldown": 10.0,
			"mana_cost": 20.0,
			"stamina_cost": 10.0,
			"cast_time": 0.2,
			"range": 0,
			"damage": 0.0,
			"effects": ["poison_weapon"],
			"duration": 12.0,
			"poison_damage": 5.0,
			"skill_tree": "rogue"
		},
		"rogue_backstab": {
			"name": "Backstab",
			"description": "Critical damage when attacking from behind",
			"cooldown": 8.0,
			"mana_cost": 20.0,
			"stamina_cost": 15.0,
			"cast_time": 0.4,
			"range": 1,
			"damage": 40.0,
			"effects": ["critical_damage", "position_based"],
			"skill_tree": "rogue"
		},
		"rogue_assassinate": {
			"name": "Assassinate",
			"description": "Instant kill enemies below 25% health",
			"cooldown": 20.0,
			"mana_cost": 40.0,
			"stamina_cost": 25.0,
			"cast_time": 0.6,
			"range": 1,
			"damage": 999.0,
			"effects": ["execute", "stealth_required"],
			"health_threshold": 0.25,
			"skill_tree": "rogue"
		}
	}
	
	print("Loaded ", ability_definitions.size(), " ability definitions")

func _process(delta):
	"""Update cooldowns and process queued abilities"""
	# Update cooldowns
	var completed_cooldowns = []
	for ability_id in active_cooldowns:
		active_cooldowns[ability_id] -= delta
		if active_cooldowns[ability_id] <= 0:
			completed_cooldowns.append(ability_id)
	
	# Remove completed cooldowns
	for ability_id in completed_cooldowns:
		active_cooldowns.erase(ability_id)
		ability_ready.emit(ability_id)
		print("Ability ready: ", get_ability_name(ability_id))
	
	# Process queued abilities
	process_ability_queue()

func use_ability(ability_id: String, target_lane: int = -1, target_row: int = -1) -> bool:
	"""Attempt to use an ability"""
	# Check if ability exists
	if not ability_definitions.has(ability_id):
		print("Unknown ability: ", ability_id)
		return false
	
	# Check if player has unlocked this ability
	if not is_ability_unlocked(ability_id):
		print("Ability not unlocked: ", ability_id)
		return false
	
	# Check cooldown
	if is_ability_on_cooldown(ability_id):
		var remaining = get_cooldown_remaining(ability_id)
		print("Ability on cooldown: ", ability_id, " (", remaining, "s remaining)")
		return false
	
	var ability = ability_definitions[ability_id]
	
	# Check resource costs
	if not can_afford_ability(ability):
		var mana_cost = ability.get("mana_cost", 0.0)
		var stamina_cost = ability.get("stamina_cost", 0.0)
		if mana_cost > 0:
			resource_insufficient.emit(ability_id, "mana", mana_cost, get_current_mana())
		if stamina_cost > 0:
			resource_insufficient.emit(ability_id, "stamina", stamina_cost, get_current_stamina())
		return false
	
	# Execute ability
	var success = execute_ability(ability_id, ability, target_lane, target_row)
	
	if success:
		# Consume resources
		consume_ability_resources(ability)
		
		# Start cooldown
		start_cooldown(ability_id, ability.cooldown)
		
		ability_used.emit(ability_id, true)
		print("Used ability: ", ability.name)
	else:
		ability_used.emit(ability_id, false)
		print("Failed to use ability: ", ability.name)
	
	return success

func execute_ability(ability_id: String, ability: Dictionary, target_lane: int, target_row: int) -> bool:
	"""Execute the actual ability effects"""
	print("Executing ability: ", ability.name)
	
	# Get current player position
	if player_node:
		current_lane = player_node.get("current_lane")
		current_row = player_node.get("current_row")
	
	# Use target position if specified, otherwise use current position
	var effective_lane = target_lane if target_lane >= 0 else current_lane
	var effective_row = target_row if target_row >= 0 else current_row
	
	# Process ability effects
	var effects = ability.get("effects", [])
	for effect in effects:
		execute_ability_effect(ability_id, effect, ability, effective_lane, effective_row)
	
	# Create visual and audio feedback
	create_ability_feedback(ability_id, ability, effective_lane, effective_row)
	
	return true

func execute_ability_effect(ability_id: String, effect: String, ability: Dictionary, lane: int, row: int):
	"""Execute a specific ability effect"""
	match effect:
		"forward_movement":
			execute_movement_effect(ability_id, "forward", ability.get("range", 1))
		"damage_enemies":
			execute_damage_effect(ability_id, ability.get("damage", 0.0), lane, row, ability.get("range", 1))
		"area_damage":
			execute_area_damage_effect(ability_id, ability.get("damage", 0.0), lane, row, ability.get("area_size", 1))
		"heal_self":
			execute_heal_effect(ability_id, ability.get("heal_amount", 20.0), true, false)
		"heal_companions":
			execute_heal_effect(ability_id, ability.get("heal_amount", 20.0), false, true)
		"buff_attack_speed":
			execute_buff_effect(ability_id, "attack_speed", 1.5, ability.get("duration", 10.0))
		"buff_damage":
			execute_buff_effect(ability_id, "damage", 1.3, ability.get("duration", 10.0))
		"projectile":
			execute_projectile_effect(ability_id, ability.get("damage", 0.0), lane, row, ability.get("range", 3))
		"chain_lightning":
			execute_chain_lightning_effect(ability_id, ability.get("damage", 0.0), ability.get("max_targets", 3))
		"dash_movement":
			execute_dash_effect(ability_id, ability.get("range", 2), ability.get("duration", 0.5))
		"invisibility":
			execute_invisibility_effect(ability_id, ability.get("duration", 5.0))
		"poison_weapon":
			execute_poison_weapon_effect(ability_id, ability.get("duration", 10.0), ability.get("poison_damage", 5.0))
		"critical_damage":
			execute_critical_damage_effect(ability_id, ability.get("damage", 0.0))
		"stun":
			execute_stun_effect(ability_id, lane, row, ability.get("range", 1))
		"knockback":
			execute_knockback_effect(ability_id, lane, row, ability.get("range", 1))
		"mana_shield":
			execute_mana_shield_effect(ability_id, ability.get("duration", 15.0))
		_:
			print("Unknown ability effect: ", effect)

func execute_movement_effect(ability_id: String, direction: String, distance: int):
	"""Execute movement-based ability effects"""
	if not player_node:
		return
	
	print("Movement effect: ", direction, " distance: ", distance)
	# In lane-based system, forward movement could move player forward in rows
	# This would integrate with the existing movement system

func execute_damage_effect(ability_id: String, damage: float, lane: int, row: int, range: int):
	"""Execute damage effects on enemies"""
	print("Damage effect: ", damage, " at lane ", lane, " row ", row, " range ", range)
	# Find enemies in the specified area and apply damage
	# This would integrate with the existing hazard/enemy system

func execute_area_damage_effect(ability_id: String, damage: float, lane: int, row: int, area_size: int):
	"""Execute area damage effects"""
	print("Area damage effect: ", damage, " at lane ", lane, " row ", row, " area ", area_size)
	# Apply damage to all enemies in the area

func execute_heal_effect(ability_id: String, heal_amount: float, heal_self: bool, heal_companions: bool):
	"""Execute healing effects"""
	if heal_self and player_node and player_node.has_method("heal"):
		player_node.heal(heal_amount)
		print("Healed self for ", heal_amount)
	
	if heal_companions:
		# Heal companions (would integrate with companion system)
		print("Healed companions for ", heal_amount)

func execute_buff_effect(ability_id: String, buff_type: String, multiplier: float, duration: float):
	"""Execute buff effects"""
	print("Buff effect: ", buff_type, " x", multiplier, " for ", duration, "s")
	# Apply temporary stat buffs

func execute_projectile_effect(ability_id: String, damage: float, lane: int, row: int, range: int):
	"""Execute projectile-based attacks"""
	print("Projectile effect: ", damage, " damage to lane ", lane, " range ", range)
	# Create projectile that travels forward and damages enemies

func execute_chain_lightning_effect(ability_id: String, damage: float, max_targets: int):
	"""Execute chain lightning effect"""
	print("Chain lightning: ", damage, " damage to ", max_targets, " targets")
	# Find nearby enemies and chain lightning between them

func execute_dash_effect(ability_id: String, distance: int, duration: float):
	"""Execute dash movement effect"""
	print("Dash effect: distance ", distance, " duration ", duration)
	# Quickly move player forward while providing invulnerability

func execute_invisibility_effect(ability_id: String, duration: float):
	"""Execute invisibility effect"""
	print("Invisibility effect: duration ", duration)
	# Make player invisible to enemies

func execute_poison_weapon_effect(ability_id: String, duration: float, poison_damage: float):
	"""Execute poison weapon effect"""
	print("Poison weapon: duration ", duration, " damage ", poison_damage)
	# Next attacks apply poison

func execute_critical_damage_effect(ability_id: String, damage: float):
	"""Execute critical damage effect"""
	print("Critical damage: ", damage)
	# Apply critical damage multiplier

func execute_stun_effect(ability_id: String, lane: int, row: int, range: int):
	"""Execute stun effect on enemies"""
	print("Stun effect at lane ", lane, " row ", row, " range ", range)
	# Stun enemies in area

func execute_knockback_effect(ability_id: String, lane: int, row: int, range: int):
	"""Execute knockback effect"""
	print("Knockback effect at lane ", lane, " row ", row, " range ", range)
	# Push enemies away

func execute_mana_shield_effect(ability_id: String, duration: float):
	"""Execute mana shield effect"""
	print("Mana shield: duration ", duration)
	# Absorb damage using mana

func create_ability_feedback(ability_id: String, ability: Dictionary, lane: int, row: int):
	"""Create visual and audio feedback for ability use"""
	print("Creating feedback for ability: ", ability.name)
	# Create particle effects, screen shake, sound effects, etc.
	# This would integrate with the existing effect systems

func queue_ability(ability_id: String):
	"""Queue an ability for execution when possible"""
	if not ability_id in queued_abilities:
		queued_abilities.append(ability_id)
		print("Queued ability: ", get_ability_name(ability_id))

func process_ability_queue():
	"""Process queued abilities"""
	if queued_abilities.is_empty():
		return
	
	# Try to execute the first queued ability
	var ability_id = queued_abilities[0]
	if use_ability(ability_id):
		queued_abilities.pop_front()
	# If ability can't be used, keep it queued for next frame

func clear_ability_queue():
	"""Clear all queued abilities"""
	queued_abilities.clear()

func is_ability_unlocked(ability_id: String) -> bool:
	"""Check if player has unlocked an ability"""
	if not player_data:
		return false
	
	# Check in all skill trees
	return (ability_id in player_data.unlocked_warrior_abilities or
			ability_id in player_data.unlocked_mage_abilities or
			ability_id in player_data.unlocked_rogue_abilities or
			ability_id in player_data.unlocked_abilities)

func is_ability_on_cooldown(ability_id: String) -> bool:
	"""Check if ability is on cooldown"""
	return active_cooldowns.has(ability_id)

func get_cooldown_remaining(ability_id: String) -> float:
	"""Get remaining cooldown time for ability"""
	return active_cooldowns.get(ability_id, 0.0)

func start_cooldown(ability_id: String, duration: float):
	"""Start cooldown for an ability"""
	active_cooldowns[ability_id] = duration
	ability_cooldown_started.emit(ability_id, duration)

func can_afford_ability(ability: Dictionary) -> bool:
	"""Check if player can afford ability costs"""
	var mana_cost = ability.get("mana_cost", 0.0)
	var stamina_cost = ability.get("stamina_cost", 0.0)
	
	return (get_current_mana() >= mana_cost and get_current_stamina() >= stamina_cost)

func consume_ability_resources(ability: Dictionary):
	"""Consume resources for ability use"""
	var mana_cost = ability.get("mana_cost", 0.0)
	var stamina_cost = ability.get("stamina_cost", 0.0)
	
	if mana_cost > 0 and player_node and player_node.has_method("use_stamina"):
		player_node.use_stamina(mana_cost)  # Using stamina method for mana
	
	if stamina_cost > 0:
		# Additional stamina cost beyond mana
		print("Additional stamina cost: ", stamina_cost)

func get_current_mana() -> float:
	"""Get current mana from player"""
	if player_node and player_node.has_method("get_current_mana"):
		return player_node.get_current_mana()
	return 0.0

func get_current_stamina() -> float:
	"""Get current stamina from player"""
	if player_node and player_node.has_method("get_current_stamina"):
		return player_node.get_current_stamina()
	return 0.0

func get_ability_name(ability_id: String) -> String:
	"""Get display name for ability"""
	if ability_definitions.has(ability_id):
		return ability_definitions[ability_id].name
	return ability_id

func get_ability_description(ability_id: String) -> String:
	"""Get description for ability"""
	if ability_definitions.has(ability_id):
		return ability_definitions[ability_id].description
	return ""

func get_ability_info(ability_id: String) -> Dictionary:
	"""Get complete information about an ability"""
	if not ability_definitions.has(ability_id):
		return {}
	
	var ability = ability_definitions[ability_id].duplicate()
	ability["is_unlocked"] = is_ability_unlocked(ability_id)
	ability["is_on_cooldown"] = is_ability_on_cooldown(ability_id)
	ability["cooldown_remaining"] = get_cooldown_remaining(ability_id)
	ability["can_afford"] = can_afford_ability(ability_definitions[ability_id])
	
	return ability

func get_unlocked_abilities() -> Array[String]:
	"""Get list of all unlocked abilities"""
	var unlocked: Array[String] = []
	
	for ability_id in ability_definitions:
		if is_ability_unlocked(ability_id):
			unlocked.append(ability_id)
	
	return unlocked

func get_abilities_by_skill_tree(skill_tree: String) -> Array[String]:
	"""Get abilities for a specific skill tree"""
	var abilities: Array[String] = []
	
	for ability_id in ability_definitions:
		var ability = ability_definitions[ability_id]
		if ability.get("skill_tree", "") == skill_tree:
			abilities.append(ability_id)
	
	return abilities

func _on_player_stats_changed():
	"""Handle player stats changes"""
	# Could update ability effectiveness based on stats
	pass

func debug_ability_system():
	"""Debug information about ability system"""
	print("=== ABILITY SYSTEM DEBUG ===")
	print("Active cooldowns: ", active_cooldowns.size())
	for ability_id in active_cooldowns:
		print("  ", get_ability_name(ability_id), ": ", active_cooldowns[ability_id], "s")
	
	print("Queued abilities: ", queued_abilities.size())
	for ability_id in queued_abilities:
		print("  ", get_ability_name(ability_id))
	
	print("Unlocked abilities: ", get_unlocked_abilities().size())
	for ability_id in get_unlocked_abilities():
		print("  ", get_ability_name(ability_id))
	
	print("Current resources:")
	print("  Mana: ", get_current_mana())
	print("  Stamina: ", get_current_stamina())
	print("=============================")