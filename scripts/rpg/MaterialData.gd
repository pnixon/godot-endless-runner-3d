class_name MaterialData
extends Resource

# Basic material information
@export var material_id: String
@export var name: String
@export var description: String
@export var icon_path: String

# Material properties
@export var rarity: MaterialRarity
@export var category: String  # "metal", "cloth", "gem", "organic", "magical"
@export var base_value: int = 1
@export var stack_size: int = 99

# Drop and acquisition
@export var drop_sources: Array[String] = []  # Mission IDs, enemy types, etc.
@export var drop_rate: float = 0.1  # 0.0 to 1.0
@export var can_be_purchased: bool = false
@export var purchase_price: int = 10

# Crafting properties
@export var crafting_tier: int = 1  # Higher tier materials for advanced recipes
@export var processing_recipes: Array[String] = []  # Recipes that use this material

# Visual and audio
@export var pickup_sound: String = "pickup_material"
@export var pickup_effect: String = "material_sparkle"

enum MaterialRarity {
	COMMON,
	UNCOMMON,
	RARE,
	EPIC,
	LEGENDARY
}

func get_rarity_color() -> Color:
	"""Get the color associated with this material's rarity"""
	match rarity:
		MaterialRarity.COMMON:
			return Color.WHITE
		MaterialRarity.UNCOMMON:
			return Color.GREEN
		MaterialRarity.RARE:
			return Color.BLUE
		MaterialRarity.EPIC:
			return Color.PURPLE
		MaterialRarity.LEGENDARY:
			return Color.ORANGE
		_:
			return Color.WHITE

func get_rarity_name() -> String:
	"""Get the string name of the rarity"""
	match rarity:
		MaterialRarity.COMMON:
			return "Common"
		MaterialRarity.UNCOMMON:
			return "Uncommon"
		MaterialRarity.RARE:
			return "Rare"
		MaterialRarity.EPIC:
			return "Epic"
		MaterialRarity.LEGENDARY:
			return "Legendary"
		_:
			return "Unknown"

func get_total_value() -> int:
	"""Calculate the total value including rarity multiplier"""
	var multiplier = 1.0
	match rarity:
		MaterialRarity.UNCOMMON:
			multiplier = 2.0
		MaterialRarity.RARE:
			multiplier = 5.0
		MaterialRarity.EPIC:
			multiplier = 10.0
		MaterialRarity.LEGENDARY:
			multiplier = 25.0
	
	return int(base_value * multiplier)

func get_tooltip_text() -> String:
	"""Generate tooltip text for UI display"""
	var tooltip = name + "\n"
	tooltip += get_rarity_name() + " " + category.capitalize() + " Material\n"
	tooltip += "Tier " + str(crafting_tier) + "\n\n"
	
	if not description.is_empty():
		tooltip += description + "\n\n"
	
	# Drop sources
	if not drop_sources.is_empty():
		tooltip += "Found in:\n"
		for source in drop_sources:
			tooltip += "• " + source.replace("_", " ").capitalize() + "\n"
		tooltip += "\n"
	
	# Purchase info
	if can_be_purchased:
		tooltip += "Can be purchased for " + str(purchase_price) + " gold\n"
	
	tooltip += "Value: " + str(get_total_value()) + " gold\n"
	tooltip += "Stack Size: " + str(stack_size)
	
	return tooltip

func can_drop_from_source(source: String) -> bool:
	"""Check if this material can drop from a specific source"""
	return source in drop_sources

func roll_for_drop() -> bool:
	"""Roll to see if this material drops"""
	return randf() <= drop_rate

# Static helper functions for material management
static func create_common_materials() -> Array[MaterialData]:
	"""Create a set of common crafting materials"""
	var materials = []
	
	# Metal materials
	var iron_ore = MaterialData.new()
	iron_ore.material_id = "iron_ore"
	iron_ore.name = "Iron Ore"
	iron_ore.description = "Common metal ore used in basic weapon and armor crafting."
	iron_ore.rarity = MaterialRarity.COMMON
	iron_ore.category = "metal"
	iron_ore.base_value = 2
	iron_ore.crafting_tier = 1
	iron_ore.drop_sources = ["forest_missions", "mountain_missions"]
	iron_ore.drop_rate = 0.3
	materials.append(iron_ore)
	
	var steel_ingot = MaterialData.new()
	steel_ingot.material_id = "steel_ingot"
	steel_ingot.name = "Steel Ingot"
	steel_ingot.description = "Refined metal ingot for advanced crafting."
	steel_ingot.rarity = MaterialRarity.UNCOMMON
	steel_ingot.category = "metal"
	steel_ingot.base_value = 5
	steel_ingot.crafting_tier = 2
	steel_ingot.drop_sources = ["advanced_missions"]
	steel_ingot.drop_rate = 0.15
	materials.append(steel_ingot)
	
	# Cloth materials
	var cotton_fiber = MaterialData.new()
	cotton_fiber.material_id = "cotton_fiber"
	cotton_fiber.name = "Cotton Fiber"
	cotton_fiber.description = "Soft fibers used for basic cloth armor."
	cotton_fiber.rarity = MaterialRarity.COMMON
	cotton_fiber.category = "cloth"
	cotton_fiber.base_value = 1
	cotton_fiber.crafting_tier = 1
	cotton_fiber.drop_sources = ["plains_missions", "village_missions"]
	cotton_fiber.drop_rate = 0.4
	materials.append(cotton_fiber)
	
	var silk_thread = MaterialData.new()
	silk_thread.material_id = "silk_thread"
	silk_thread.name = "Silk Thread"
	silk_thread.description = "Fine thread for high-quality cloth items."
	silk_thread.rarity = MaterialRarity.RARE
	silk_thread.category = "cloth"
	silk_thread.base_value = 8
	silk_thread.crafting_tier = 3
	silk_thread.drop_sources = ["spider_enemies", "luxury_missions"]
	silk_thread.drop_rate = 0.08
	materials.append(silk_thread)
	
	# Gem materials
	var rough_gem = MaterialData.new()
	rough_gem.material_id = "rough_gem"
	rough_gem.name = "Rough Gem"
	rough_gem.description = "Uncut gemstone with magical potential."
	rough_gem.rarity = MaterialRarity.UNCOMMON
	rough_gem.category = "gem"
	rough_gem.base_value = 10
	rough_gem.crafting_tier = 2
	rough_gem.drop_sources = ["cave_missions", "treasure_chests"]
	rough_gem.drop_rate = 0.12
	materials.append(rough_gem)
	
	var crystal_shard = MaterialData.new()
	crystal_shard.material_id = "crystal_shard"
	crystal_shard.name = "Crystal Shard"
	crystal_shard.description = "Magical crystal fragment with powerful enchantments."
	crystal_shard.rarity = MaterialRarity.LEGENDARY
	crystal_shard.category = "magical"
	crystal_shard.base_value = 50
	crystal_shard.crafting_tier = 5
	crystal_shard.drop_sources = ["boss_enemies", "legendary_missions"]
	crystal_shard.drop_rate = 0.02
	materials.append(crystal_shard)
	
	# Organic materials
	var monster_hide = MaterialData.new()
	monster_hide.material_id = "monster_hide"
	monster_hide.name = "Monster Hide"
	monster_hide.description = "Tough hide from defeated monsters, good for armor."
	monster_hide.rarity = MaterialRarity.COMMON
	monster_hide.category = "organic"
	monster_hide.base_value = 3
	monster_hide.crafting_tier = 1
	monster_hide.drop_sources = ["beast_enemies", "forest_missions"]
	monster_hide.drop_rate = 0.25
	materials.append(monster_hide)
	
	var dragon_scale = MaterialData.new()
	dragon_scale.material_id = "dragon_scale"
	dragon_scale.name = "Dragon Scale"
	dragon_scale.description = "Incredibly durable scale from an ancient dragon."
	dragon_scale.rarity = MaterialRarity.EPIC
	dragon_scale.category = "organic"
	dragon_scale.base_value = 25
	dragon_scale.crafting_tier = 4
	dragon_scale.drop_sources = ["dragon_boss", "final_missions"]
	dragon_scale.drop_rate = 0.05
	materials.append(dragon_scale)
	
	return materials

static func get_material_by_id(materials: Array[MaterialData], material_id: String) -> MaterialData:
	"""Find a material by its ID"""
	for material in materials:
		if material.material_id == material_id:
			return material
	return null