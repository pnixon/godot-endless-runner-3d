# Equipment class
class_name Equipment
extends Resource

# Basic item information
@export var item_id: String
@export var name: String
@export var description: String
@export var icon_path: String

# Equipment properties
@export var slot: String  # "weapon", "armor", "accessory"
@export var rarity: EquipmentRarity
@export var level_requirement: int = 1
@export var class_restrictions: Array[String] = []  # Empty = no restrictions

# Base stats
@export var stat_bonuses: Dictionary = {}  # stat_name -> bonus_value
@export var special_abilities: Array[String] = []
@export var set_id: String = ""  # For equipment sets

# Visual data
@export var visual_data: Resource = null
@export var model_path: String
@export var texture_path: String

# Crafting and economy
@export var base_value: int = 10
@export var crafting_materials: Dictionary = {}  # material_id -> quantity
@export var can_be_sold: bool = true
@export var can_be_dismantled: bool = true

# Durability and condition
@export var max_durability: int = 100
@export var current_durability: int = 100
@export var repair_cost_multiplier: float = 0.1

signal durability_changed(new_durability: int)
signal equipment_broken()

enum EquipmentRarity {
	COMMON,
	UNCOMMON,
	RARE,
	EPIC,
	LEGENDARY
}

func _init():
	current_durability = max_durability

func get_stat_bonus(stat_name: String) -> float:
	"""Get the bonus value for a specific stat"""
	return stat_bonuses.get(stat_name, 0.0)

func get_all_stat_bonuses() -> Dictionary:
	"""Get all stat bonuses this equipment provides"""
	return stat_bonuses.duplicate()

func add_stat_bonus(stat_name: String, bonus: float):
	"""Add or modify a stat bonus"""
	stat_bonuses[stat_name] = bonus

func has_special_ability(ability_id: String) -> bool:
	"""Check if equipment has a specific special ability"""
	return ability_id in special_abilities

func add_special_ability(ability_id: String):
	"""Add a special ability to the equipment"""
	if not ability_id in special_abilities:
		special_abilities.append(ability_id)

func remove_special_ability(ability_id: String):
	"""Remove a special ability from the equipment"""
	special_abilities.erase(ability_id)

func can_be_equipped_by_class(character_class: String) -> bool:
	"""Check if this equipment can be equipped by a specific class"""
	return class_restrictions.is_empty() or character_class in class_restrictions

func get_rarity_color() -> Color:
	"""Get the color associated with this equipment's rarity"""
	match rarity:
		EquipmentRarity.COMMON:
			return Color.WHITE
		EquipmentRarity.UNCOMMON:
			return Color.GREEN
		EquipmentRarity.RARE:
			return Color.BLUE
		EquipmentRarity.EPIC:
			return Color.PURPLE
		EquipmentRarity.LEGENDARY:
			return Color.ORANGE
		_:
			return Color.WHITE

func get_rarity_name() -> String:
	"""Get the string name of the rarity"""
	match rarity:
		EquipmentRarity.COMMON:
			return "Common"
		EquipmentRarity.UNCOMMON:
			return "Uncommon"
		EquipmentRarity.RARE:
			return "Rare"
		EquipmentRarity.EPIC:
			return "Epic"
		EquipmentRarity.LEGENDARY:
			return "Legendary"
		_:
			return "Unknown"

func get_total_value() -> int:
	"""Calculate the total value including rarity multiplier"""
	var multiplier = 1.0
	match rarity:
		EquipmentRarity.UNCOMMON:
			multiplier = 2.0
		EquipmentRarity.RARE:
			multiplier = 5.0
		EquipmentRarity.EPIC:
			multiplier = 10.0
		EquipmentRarity.LEGENDARY:
			multiplier = 25.0
	
	return int(base_value * multiplier * (current_durability / float(max_durability)))

func take_durability_damage(damage: int = 1):
	"""Reduce durability from use"""
	current_durability = max(0, current_durability - damage)
	durability_changed.emit(current_durability)
	
	if current_durability <= 0:
		equipment_broken.emit()

func repair(amount: int = -1):
	"""Repair the equipment (amount = -1 means full repair)"""
	if amount == -1:
		current_durability = max_durability
	else:
		current_durability = min(max_durability, current_durability + amount)
	
	durability_changed.emit(current_durability)

func get_repair_cost() -> int:
	"""Calculate the cost to fully repair this equipment"""
	var damage_ratio = 1.0 - (current_durability / float(max_durability))
	return int(get_total_value() * repair_cost_multiplier * damage_ratio)

func is_broken() -> bool:
	"""Check if equipment is broken (0 durability)"""
	return current_durability <= 0

func get_durability_percentage() -> float:
	"""Get durability as a percentage"""
	return current_durability / float(max_durability) if max_durability > 0 else 0.0

func get_tooltip_text() -> String:
	"""Generate tooltip text for UI display"""
	var tooltip = name + "\n"
	tooltip += get_rarity_name() + " " + slot.capitalize() + "\n"
	
	if level_requirement > 1:
		tooltip += "Level " + str(level_requirement) + " Required\n"
	
	tooltip += "\n"
	
	# Add stat bonuses
	for stat_name in stat_bonuses:
		var bonus = stat_bonuses[stat_name]
		if bonus > 0:
			tooltip += "+" + str(bonus) + " " + stat_name.capitalize() + "\n"
		elif bonus < 0:
			tooltip += str(bonus) + " " + stat_name.capitalize() + "\n"
	
	# Add special abilities
	if not special_abilities.is_empty():
		tooltip += "\nSpecial Abilities:\n"
		for ability in special_abilities:
			tooltip += "• " + ability.replace("_", " ").capitalize() + "\n"
	
	# Add durability info
	tooltip += "\nDurability: " + str(current_durability) + "/" + str(max_durability)
	
	# Add value
	tooltip += "\nValue: " + str(get_total_value()) + " gold"
	
	if not description.is_empty():
		tooltip += "\n\n" + description
	
	return tooltip

func duplicate_equipment() -> Equipment:
	"""Create a copy of this equipment"""
	var copy = Equipment.new()
	copy.item_id = item_id
	copy.name = name
	copy.description = description
	copy.icon_path = icon_path
	copy.slot = slot
	copy.rarity = rarity
	copy.level_requirement = level_requirement
	copy.class_restrictions = class_restrictions.duplicate()
	copy.stat_bonuses = stat_bonuses.duplicate()
	copy.special_abilities = special_abilities.duplicate()
	copy.set_id = set_id
	copy.visual_data = visual_data
	copy.model_path = model_path
	copy.texture_path = texture_path
	copy.base_value = base_value
	copy.crafting_materials = crafting_materials.duplicate()
	copy.can_be_sold = can_be_sold
	copy.can_be_dismantled = can_be_dismantled
	copy.max_durability = max_durability
	copy.current_durability = current_durability
	copy.repair_cost_multiplier = repair_cost_multiplier
	
	return copy
