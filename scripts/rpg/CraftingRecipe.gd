class_name CraftingRecipe
extends Resource

# Recipe identification
@export var recipe_id: String
@export var name: String
@export var description: String
@export var category: String  # "weapons", "armor", "accessories", "consumables"

# Requirements
@export var required_materials: Dictionary = {}  # material_id -> quantity
@export var required_level: int = 1
@export var required_skill_points: Dictionary = {}  # skill_tree -> points_needed
@export var prerequisite_recipes: Array[String] = []

# Output
@export var output_item: Equipment
@export var output_quantity: int = 1
@export var success_rate: float = 1.0  # 0.0 to 1.0

# Crafting properties
@export var crafting_time: float = 2.0  # Seconds to craft
@export var experience_reward: int = 10
@export var unlock_chapter: int = 1
@export var is_unlocked: bool = false

# Visual and audio
@export var icon_path: String
@export var crafting_animation: String = "default"
@export var success_sound: String = "craft_success"
@export var failure_sound: String = "craft_failure"

signal recipe_unlocked()
signal crafting_started()
signal crafting_completed(success: bool, item: Equipment)

func can_craft(player_data: PlayerData) -> bool:
	"""Check if the player can craft this recipe"""
	# Check if recipe is unlocked
	if not is_unlocked:
		return false
	
	# Check level requirement
	if player_data.stats.level < required_level:
		return false
	
	# Check skill point requirements
	for skill_tree in required_skill_points:
		var points_needed = required_skill_points[skill_tree]
		match skill_tree:
			"warrior":
				if player_data.stats.warrior_points < points_needed:
					return false
			"mage":
				if player_data.stats.mage_points < points_needed:
					return false
			"rogue":
				if player_data.stats.rogue_points < points_needed:
					return false
	
	# Check material requirements
	for material_id in required_materials:
		var needed_quantity = required_materials[material_id]
		if player_data.get_material_count(material_id) < needed_quantity:
			return false
	
	# Check prerequisite recipes
	for prereq_recipe in prerequisite_recipes:
		if not prereq_recipe in player_data.unlocked_recipes:
			return false
	
	return true

func get_missing_requirements(player_data: PlayerData) -> Dictionary:
	"""Get a list of missing requirements for crafting"""
	var missing = {
		"level": 0,
		"materials": {},
		"skill_points": {},
		"recipes": []
	}
	
	# Check level
	if player_data.stats.level < required_level:
		missing["level"] = required_level - player_data.stats.level
	
	# Check materials
	for material_id in required_materials:
		var needed = required_materials[material_id]
		var have = player_data.get_material_count(material_id)
		if have < needed:
			missing["materials"][material_id] = needed - have
	
	# Check skill points
	for skill_tree in required_skill_points:
		var needed = required_skill_points[skill_tree]
		var have = 0
		match skill_tree:
			"warrior":
				have = player_data.stats.warrior_points
			"mage":
				have = player_data.stats.mage_points
			"rogue":
				have = player_data.stats.rogue_points
		
		if have < needed:
			missing["skill_points"][skill_tree] = needed - have
	
	# Check prerequisite recipes
	for prereq_recipe in prerequisite_recipes:
		if not prereq_recipe in player_data.unlocked_recipes:
			missing["recipes"].append(prereq_recipe)
	
	return missing

func attempt_craft(player_data: PlayerData) -> Dictionary:
	"""Attempt to craft the item, returns result dictionary"""
	var result = {
		"success": false,
		"item": null,
		"message": "",
		"materials_consumed": {}
	}
	
	# Check if crafting is possible
	if not can_craft(player_data):
		result["message"] = "Cannot craft: missing requirements"
		return result
	
	# Consume materials
	for material_id in required_materials:
		var quantity = required_materials[material_id]
		if player_data.use_material(material_id, quantity):
			result["materials_consumed"][material_id] = quantity
		else:
			# Refund already consumed materials if this fails
			for consumed_material in result["materials_consumed"]:
				player_data.add_material(consumed_material, result["materials_consumed"][consumed_material])
			result["message"] = "Failed to consume materials"
			return result
	
	crafting_started.emit()
	
	# Check success rate
	var roll = randf()
	if roll <= success_rate:
		# Success!
		result["success"] = true
		result["item"] = output_item.duplicate_equipment() if output_item else null
		result["message"] = "Successfully crafted " + name + "!"
		
		# Add item to inventory
		if result["item"]:
			player_data.add_to_inventory(result["item"])
		
		# Grant experience
		player_data.stats.gain_experience(experience_reward)
		player_data.items_crafted += 1
		
	else:
		# Failure - materials are still consumed
		result["success"] = false
		result["message"] = "Crafting failed! Materials were lost."
	
	crafting_completed.emit(result["success"], result["item"])
	return result

func unlock_recipe():
	"""Unlock this recipe for crafting"""
	if not is_unlocked:
		is_unlocked = true
		recipe_unlocked.emit()
		print("Recipe unlocked: ", name)

func get_tooltip_text() -> String:
	"""Generate tooltip text for UI display"""
	var tooltip = name + "\n"
	tooltip += description + "\n\n"
	
	# Requirements
	tooltip += "Requirements:\n"
	if required_level > 1:
		tooltip += "• Level " + str(required_level) + "\n"
	
	# Skill point requirements
	for skill_tree in required_skill_points:
		var points = required_skill_points[skill_tree]
		tooltip += "• " + skill_tree.capitalize() + " Points: " + str(points) + "\n"
	
	# Material requirements
	tooltip += "\nMaterials:\n"
	for material_id in required_materials:
		var quantity = required_materials[material_id]
		tooltip += "• " + material_id.replace("_", " ").capitalize() + ": " + str(quantity) + "\n"
	
	# Prerequisites
	if not prerequisite_recipes.is_empty():
		tooltip += "\nPrerequisite Recipes:\n"
		for recipe in prerequisite_recipes:
			tooltip += "• " + recipe.replace("_", " ").capitalize() + "\n"
	
	# Output
	tooltip += "\nCreates:\n"
	if output_item:
		tooltip += "• " + output_item.name
		if output_quantity > 1:
			tooltip += " x" + str(output_quantity)
		tooltip += "\n"
	
	# Success rate
	if success_rate < 1.0:
		tooltip += "\nSuccess Rate: " + str(int(success_rate * 100)) + "%\n"
	
	# Experience reward
	tooltip += "Experience: " + str(experience_reward) + " XP"
	
	return tooltip

func get_save_data() -> Dictionary:
	"""Get recipe data for saving"""
	return {
		"recipe_id": recipe_id,
		"is_unlocked": is_unlocked
	}

func load_save_data(data: Dictionary):
	"""Load recipe data from save"""
	is_unlocked = data.get("is_unlocked", false)