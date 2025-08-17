class_name PlayerData
extends Resource

# Player identification and progression
@export var player_name: String = "Hero"
@export var player_id: String = ""
@export var creation_date: String = ""

# Core stats and progression
@export var stats: PlayerStats
@export var current_chapter: int = 1
@export var completed_missions: Array[String] = []
@export var unlocked_abilities: Array[String] = []

# Equipment system
@export var equipped_weapon: Equipment
@export var equipped_armor: Equipment
@export var equipped_accessory: Equipment
@export var inventory: Array[Equipment] = []

# Skill tree progression
@export var unlocked_warrior_abilities: Array[String] = []
@export var unlocked_mage_abilities: Array[String] = []
@export var unlocked_rogue_abilities: Array[String] = []

# Companion relationships
@export var companion_bonds: Dictionary = {}  # companion_id -> bond_level
@export var unlocked_companions: Array[String] = []
@export var active_companions: Array[String] = []  # Max 2 companions per mission

# Crafting and materials
@export var materials: Dictionary = {}  # material_id -> quantity
@export var unlocked_recipes: Array[String] = []
@export var crafting_level: int = 1

# Game progress and achievements
@export var total_playtime: float = 0.0
@export var missions_completed: int = 0
@export var enemies_defeated: int = 0
@export var items_crafted: int = 0
@export var achievements: Array[String] = []

# Settings and preferences
@export var settings: Dictionary = {
	"music_volume": 0.8,
	"sfx_volume": 0.8,
	"haptic_feedback": true,
	"auto_save": true
}

signal data_changed()
signal equipment_changed(slot: String, item: Equipment)
signal companion_bond_changed(companion_id: String, new_level: int)
signal achievement_unlocked(achievement_id: String)

func _init():
	if not stats:
		stats = PlayerStats.new()
	
	# Generate unique player ID if not set
	if player_id.is_empty():
		player_id = generate_player_id()
	
	# Set creation date if not set
	if creation_date.is_empty():
		creation_date = Time.get_datetime_string_from_system()
	
	# Connect to stats signals
	if stats:
		stats.stats_changed.connect(_on_stats_changed)
		stats.level_up.connect(_on_level_up)

func generate_player_id() -> String:
	"""Generate a unique player ID"""
	var timestamp = Time.get_unix_time_from_system()
	var random_suffix = randi() % 10000
	return "player_" + str(timestamp) + "_" + str(random_suffix)

func _on_stats_changed():
	"""Handle stats changes"""
	data_changed.emit()

func _on_level_up(new_level: int):
	"""Handle level up events"""
	print("Player leveled up to level ", new_level, "!")
	
	# Unlock new abilities based on level
	check_ability_unlocks(new_level)
	
	data_changed.emit()

func check_ability_unlocks(level: int):
	"""Check and unlock new abilities based on level and skill points"""
	var new_abilities = []
	
	# Warrior abilities
	if stats.warrior_points >= 1 and not "warrior_charge" in unlocked_warrior_abilities:
		unlocked_warrior_abilities.append("warrior_charge")
		new_abilities.append("Warrior Charge")
	
	if stats.warrior_points >= 3 and not "warrior_shield" in unlocked_warrior_abilities:
		unlocked_warrior_abilities.append("warrior_shield")
		new_abilities.append("Shield Bash")
	
	if stats.warrior_points >= 5 and not "warrior_berserker" in unlocked_warrior_abilities:
		unlocked_warrior_abilities.append("warrior_berserker")
		new_abilities.append("Berserker Rage")
	
	# Mage abilities
	if stats.mage_points >= 1 and not "mage_fireball" in unlocked_mage_abilities:
		unlocked_mage_abilities.append("mage_fireball")
		new_abilities.append("Fireball")
	
	if stats.mage_points >= 3 and not "mage_heal" in unlocked_mage_abilities:
		unlocked_mage_abilities.append("mage_heal")
		new_abilities.append("Healing Light")
	
	if stats.mage_points >= 5 and not "mage_lightning" in unlocked_mage_abilities:
		unlocked_mage_abilities.append("mage_lightning")
		new_abilities.append("Lightning Storm")
	
	# Rogue abilities
	if stats.rogue_points >= 1 and not "rogue_dash" in unlocked_rogue_abilities:
		unlocked_rogue_abilities.append("rogue_dash")
		new_abilities.append("Shadow Dash")
	
	if stats.rogue_points >= 3 and not "rogue_stealth" in unlocked_rogue_abilities:
		unlocked_rogue_abilities.append("rogue_stealth")
		new_abilities.append("Stealth")
	
	if stats.rogue_points >= 5 and not "rogue_poison" in unlocked_rogue_abilities:
		unlocked_rogue_abilities.append("rogue_poison")
		new_abilities.append("Poison Strike")
	
	# Print newly unlocked abilities
	for ability in new_abilities:
		print("New ability unlocked: ", ability)

func equip_item(item: Equipment, slot: String) -> bool:
	"""Equip an item to the specified slot"""
	if not item:
		return false
	
	# Check if item can be equipped in this slot
	if item.slot != slot:
		print("Cannot equip ", item.name, " in slot ", slot)
		return false
	
	# Store previously equipped item
	var previous_item: Equipment = null
	
	match slot:
		"weapon":
			previous_item = equipped_weapon
			equipped_weapon = item
		"armor":
			previous_item = equipped_armor
			equipped_armor = item
		"accessory":
			previous_item = equipped_accessory
			equipped_accessory = item
		_:
			print("Invalid equipment slot: ", slot)
			return false
	
	# Remove item from inventory
	if item in inventory:
		inventory.erase(item)
	
	# Add previous item back to inventory if it exists
	if previous_item:
		inventory.append(previous_item)
	
	# Recalculate stats with new equipment
	if stats:
		stats.calculate_derived_stats()
	
	equipment_changed.emit(slot, item)
	data_changed.emit()
	
	print("Equipped ", item.name, " in ", slot, " slot")
	return true

func unequip_item(slot: String) -> Equipment:
	"""Unequip an item from the specified slot"""
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
		_:
			print("Invalid equipment slot: ", slot)
			return null
	
	# Add item back to inventory
	if unequipped_item:
		inventory.append(unequipped_item)
		
		# Recalculate stats without equipment
		if stats:
			stats.calculate_derived_stats()
		
		equipment_changed.emit(slot, null)
		data_changed.emit()
		
		print("Unequipped ", unequipped_item.name, " from ", slot, " slot")
	
	return unequipped_item

func add_to_inventory(item: Equipment):
	"""Add an item to the inventory"""
	inventory.append(item)
	data_changed.emit()
	print("Added ", item.name, " to inventory")

func remove_from_inventory(item: Equipment) -> bool:
	"""Remove an item from the inventory"""
	if item in inventory:
		inventory.erase(item)
		data_changed.emit()
		print("Removed ", item.name, " from inventory")
		return true
	return false

func add_material(material_id: String, quantity: int):
	"""Add crafting materials"""
	if materials.has(material_id):
		materials[material_id] += quantity
	else:
		materials[material_id] = quantity
	
	data_changed.emit()
	print("Added ", quantity, " ", material_id, " (Total: ", materials[material_id], ")")

func use_material(material_id: String, quantity: int) -> bool:
	"""Use crafting materials, returns true if successful"""
	if not materials.has(material_id) or materials[material_id] < quantity:
		return false
	
	materials[material_id] -= quantity
	if materials[material_id] <= 0:
		materials.erase(material_id)
	
	data_changed.emit()
	return true

func get_material_count(material_id: String) -> int:
	"""Get the count of a specific material"""
	return materials.get(material_id, 0)

func unlock_companion(companion_id: String):
	"""Unlock a new companion"""
	if not companion_id in unlocked_companions:
		unlocked_companions.append(companion_id)
		companion_bonds[companion_id] = 1  # Start at bond level 1
		data_changed.emit()
		print("Unlocked companion: ", companion_id)

func increase_companion_bond(companion_id: String, amount: int = 1):
	"""Increase bond level with a companion"""
	if not companion_id in companion_bonds:
		companion_bonds[companion_id] = 1
	
	companion_bonds[companion_id] += amount
	companion_bond_changed.emit(companion_id, companion_bonds[companion_id])
	data_changed.emit()
	
	print("Bond with ", companion_id, " increased to level ", companion_bonds[companion_id])

func get_companion_bond_level(companion_id: String) -> int:
	"""Get the bond level with a specific companion"""
	return companion_bonds.get(companion_id, 0)

func set_active_companions(companion_list: Array[String]):
	"""Set the active companions for missions (max 2)"""
	active_companions = companion_list.slice(0, 2)  # Limit to 2 companions
	data_changed.emit()

func complete_mission(mission_id: String):
	"""Mark a mission as completed"""
	if not mission_id in completed_missions:
		completed_missions.append(mission_id)
		missions_completed += 1
		data_changed.emit()
		print("Mission completed: ", mission_id)

func unlock_recipe(recipe_id: String):
	"""Unlock a new crafting recipe"""
	if not recipe_id in unlocked_recipes:
		unlocked_recipes.append(recipe_id)
		data_changed.emit()
		print("Recipe unlocked: ", recipe_id)

func unlock_achievement(achievement_id: String):
	"""Unlock an achievement"""
	if not achievement_id in achievements:
		achievements.append(achievement_id)
		achievement_unlocked.emit(achievement_id)
		data_changed.emit()
		print("Achievement unlocked: ", achievement_id)

func update_playtime(delta: float):
	"""Update total playtime"""
	total_playtime += delta

func get_save_data() -> Dictionary:
	"""Get all data for saving"""
	return {
		"player_name": player_name,
		"player_id": player_id,
		"creation_date": creation_date,
		"stats": stats,
		"current_chapter": current_chapter,
		"completed_missions": completed_missions,
		"unlocked_abilities": unlocked_abilities,
		"equipped_weapon": equipped_weapon,
		"equipped_armor": equipped_armor,
		"equipped_accessory": equipped_accessory,
		"inventory": inventory,
		"unlocked_warrior_abilities": unlocked_warrior_abilities,
		"unlocked_mage_abilities": unlocked_mage_abilities,
		"unlocked_rogue_abilities": unlocked_rogue_abilities,
		"companion_bonds": companion_bonds,
		"unlocked_companions": unlocked_companions,
		"active_companions": active_companions,
		"materials": materials,
		"unlocked_recipes": unlocked_recipes,
		"crafting_level": crafting_level,
		"total_playtime": total_playtime,
		"missions_completed": missions_completed,
		"enemies_defeated": enemies_defeated,
		"items_crafted": items_crafted,
		"achievements": achievements,
		"settings": settings
	}

func load_save_data(data: Dictionary):
	"""Load data from save file"""
	player_name = data.get("player_name", "Hero")
	player_id = data.get("player_id", generate_player_id())
	creation_date = data.get("creation_date", Time.get_datetime_string_from_system())
	
	if data.has("stats"):
		stats = data["stats"]
	
	current_chapter = data.get("current_chapter", 1)
	completed_missions = data.get("completed_missions", [])
	unlocked_abilities = data.get("unlocked_abilities", [])
	
	equipped_weapon = data.get("equipped_weapon", null)
	equipped_armor = data.get("equipped_armor", null)
	equipped_accessory = data.get("equipped_accessory", null)
	inventory = data.get("inventory", [])
	
	unlocked_warrior_abilities = data.get("unlocked_warrior_abilities", [])
	unlocked_mage_abilities = data.get("unlocked_mage_abilities", [])
	unlocked_rogue_abilities = data.get("unlocked_rogue_abilities", [])
	
	companion_bonds = data.get("companion_bonds", {})
	unlocked_companions = data.get("unlocked_companions", [])
	active_companions = data.get("active_companions", [])
	
	materials = data.get("materials", {})
	unlocked_recipes = data.get("unlocked_recipes", [])
	crafting_level = data.get("crafting_level", 1)
	
	total_playtime = data.get("total_playtime", 0.0)
	missions_completed = data.get("missions_completed", 0)
	enemies_defeated = data.get("enemies_defeated", 0)
	items_crafted = data.get("items_crafted", 0)
	achievements = data.get("achievements", [])
	settings = data.get("settings", {
		"music_volume": 0.8,
		"sfx_volume": 0.8,
		"haptic_feedback": true,
		"auto_save": true
	})
	
	data_changed.emit()
	print("Player data loaded successfully")