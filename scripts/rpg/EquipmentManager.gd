class_name EquipmentManager
extends Node

# Equipment Manager handles visual representation of equipped items
# and stat calculations from equipment bonuses

signal visual_update_needed()
signal equipment_stats_changed()

var player_node: Node3D
var player_data: PlayerData
var equipment_nodes: Dictionary = {}  # slot -> Node3D
var attachment_points: Dictionary = {}  # slot -> bone/node name

# Equipment attachment points for the fighter model
const ATTACHMENT_POINTS = {
	"weapon": "RightHand",
	"armor": "Torso", 
	"accessory": "LeftHand"
}

# Equipment visual cache
var loaded_models: Dictionary = {}  # model_path -> PackedScene

func initialize(player: Node3D, data: PlayerData):
	"""Initialize the equipment manager with player references"""
	player_node = player
	player_data = data
	
	# Connect to equipment change signals
	if player_data:
		player_data.equipment_changed.connect(_on_equipment_changed)
	
	# Set up attachment points
	setup_attachment_points()
	
	# Load initial equipment visuals
	update_visual_equipment()
	
	print("EquipmentManager initialized")

func setup_attachment_points():
	"""Set up attachment points for equipment on the player model"""
	# For now, we'll attach equipment as children of the main fighter model
	# In a more advanced system, we'd find specific bones in the skeleton
	
	var fighter_model = player_node.get_node_or_null("FighterModel/Animation_Running_withSkin")
	if fighter_model:
		# Create attachment point nodes if they don't exist
		for slot in ATTACHMENT_POINTS:
			var attachment_name = ATTACHMENT_POINTS[slot]
			var attachment_node = fighter_model.get_node_or_null(attachment_name)
			
			if not attachment_node:
				# Create attachment point as a Node3D
				attachment_node = Node3D.new()
				attachment_node.name = attachment_name
				fighter_model.add_child(attachment_node)
				
				# Position attachment points appropriately
				match slot:
					"weapon":
						attachment_node.position = Vector3(0.3, 0.8, 0)  # Right hand area
					"armor":
						attachment_node.position = Vector3(0, 0.5, 0)    # Torso area
					"accessory":
						attachment_node.position = Vector3(-0.3, 0.8, 0) # Left hand area
			
			attachment_points[slot] = attachment_node
			print("Set up attachment point for ", slot, " at ", attachment_name)
	else:
		print("Warning: Fighter model not found for equipment attachment")

func update_visual_equipment():
	"""Update all visual equipment based on current player data"""
	if not player_data:
		return
	
	# Update weapon visual
	update_equipment_visual("weapon", player_data.equipped_weapon)
	
	# Update armor visual
	update_equipment_visual("armor", player_data.equipped_armor)
	
	# Update accessory visual
	update_equipment_visual("accessory", player_data.equipped_accessory)
	
	# Recalculate equipment stats
	calculate_equipment_stats()
	
	visual_update_needed.emit()

func update_equipment_visual(slot: String, equipment: Equipment):
	"""Update visual representation of a specific equipment slot"""
	# Remove existing equipment visual
	remove_equipment_visual(slot)
	
	if not equipment or equipment.model_path.is_empty():
		return
	
	# Load equipment model
	var equipment_model = load_equipment_model(equipment.model_path)
	if not equipment_model:
		print("Failed to load equipment model: ", equipment.model_path)
		return
	
	# Instantiate the model
	var equipment_instance = equipment_model.instantiate()
	equipment_instance.name = slot + "_" + equipment.name
	
	# Apply visual data if available
	if equipment.visual_data:
		apply_visual_data(equipment_instance, equipment.visual_data)
	
	# Attach to appropriate attachment point
	var attachment_point = attachment_points.get(slot)
	if attachment_point:
		attachment_point.add_child(equipment_instance)
		equipment_nodes[slot] = equipment_instance
		print("Equipped visual for ", equipment.name, " in slot ", slot)
	else:
		print("Warning: No attachment point found for slot ", slot)
		equipment_instance.queue_free()

func remove_equipment_visual(slot: String):
	"""Remove visual representation of equipment from a slot"""
	if equipment_nodes.has(slot):
		var equipment_node = equipment_nodes[slot]
		if equipment_node and is_instance_valid(equipment_node):
			equipment_node.queue_free()
		equipment_nodes.erase(slot)

func load_equipment_model(model_path: String) -> PackedScene:
	"""Load equipment model with caching"""
	if loaded_models.has(model_path):
		return loaded_models[model_path]
	
	if ResourceLoader.exists(model_path):
		var model = load(model_path) as PackedScene
		if model:
			loaded_models[model_path] = model
			return model
		else:
			print("Failed to load equipment model as PackedScene: ", model_path)
	else:
		print("Equipment model file not found: ", model_path)
	
	return null

func apply_visual_data(equipment_node: Node3D, visual_data: Resource):
	"""Apply visual data settings to equipment node"""
	if not visual_data:
		return
	
	# Apply scale
	equipment_node.scale = visual_data.model_scale
	
	# Apply position offset
	equipment_node.position += visual_data.model_offset
	
	# Apply rotation
	equipment_node.rotation_degrees = visual_data.model_rotation
	
	# Apply material overrides
	if not visual_data.material_overrides.is_empty():
		apply_material_overrides(equipment_node, visual_data.material_overrides)
	
	# Apply glow effect
	if visual_data.glow_intensity > 0:
		apply_glow_effect(equipment_node, visual_data.glow_color, visual_data.glow_intensity)
	
	print("Applied visual data to equipment node")

func apply_material_overrides(node: Node3D, material_overrides: Dictionary):
	"""Apply material overrides to equipment model"""
	# Find all MeshInstance3D nodes and apply material overrides
	var mesh_instances = find_mesh_instances(node)
	
	for mesh_instance in mesh_instances:
		for material_index in material_overrides:
			if material_index is int and material_index < mesh_instance.get_surface_override_material_count():
				var material_path = material_overrides[material_index]
				if ResourceLoader.exists(material_path):
					var material = load(material_path)
					mesh_instance.set_surface_override_material(material_index, material)

func find_mesh_instances(node: Node) -> Array[MeshInstance3D]:
	"""Recursively find all MeshInstance3D nodes"""
	var mesh_instances: Array[MeshInstance3D] = []
	
	if node is MeshInstance3D:
		mesh_instances.append(node)
	
	for child in node.get_children():
		mesh_instances.append_array(find_mesh_instances(child))
	
	return mesh_instances

func apply_glow_effect(node: Node3D, glow_color: Color, intensity: float):
	"""Apply glow effect to equipment"""
	var mesh_instances = find_mesh_instances(node)
	
	for mesh_instance in mesh_instances:
		# Create or modify material to add emission
		var material = mesh_instance.get_surface_override_material(0)
		if not material:
			material = StandardMaterial3D.new()
			mesh_instance.set_surface_override_material(0, material)
		
		if material is StandardMaterial3D:
			material.emission_enabled = true
			material.emission = glow_color * intensity
			material.emission_energy = intensity

func calculate_equipment_stats():
	"""Calculate total stat bonuses from all equipped items"""
	if not player_data or not player_data.stats:
		return
	
	var total_bonuses = {}
	
	# Collect bonuses from all equipped items
	var equipped_items = [
		player_data.equipped_weapon,
		player_data.equipped_armor,
		player_data.equipped_accessory
	]
	
	for item in equipped_items:
		if item:
			var item_bonuses = item.get_all_stat_bonuses()
			for stat_name in item_bonuses:
				if total_bonuses.has(stat_name):
					total_bonuses[stat_name] += item_bonuses[stat_name]
				else:
					total_bonuses[stat_name] = item_bonuses[stat_name]
	
	# Apply bonuses to player stats
	apply_equipment_bonuses(total_bonuses)
	
	equipment_stats_changed.emit()

func apply_equipment_bonuses(bonuses: Dictionary):
	"""Apply equipment stat bonuses to player stats"""
	if not player_data or not player_data.stats:
		return
	
	var stats = player_data.stats
	
	# Store original base stats if not already stored
	if not has_meta("original_base_health"):
		set_meta("original_base_health", stats.base_health)
		set_meta("original_base_mana", stats.base_mana)
		set_meta("original_base_attack", stats.base_attack)
		set_meta("original_base_defense", stats.base_defense)
		set_meta("original_base_speed", stats.base_speed)
	
	# Reset to original base stats
	stats.base_health = get_meta("original_base_health")
	stats.base_mana = get_meta("original_base_mana")
	stats.base_attack = get_meta("original_base_attack")
	stats.base_defense = get_meta("original_base_defense")
	stats.base_speed = get_meta("original_base_speed")
	
	# Apply equipment bonuses
	for stat_name in bonuses:
		var bonus = bonuses[stat_name]
		match stat_name:
			"health":
				stats.base_health += bonus
			"mana":
				stats.base_mana += bonus
			"attack":
				stats.base_attack += bonus
			"defense":
				stats.base_defense += bonus
			"speed":
				stats.base_speed += bonus
	
	# Recalculate derived stats
	stats.calculate_derived_stats()
	
	print("Applied equipment bonuses: ", bonuses)

func get_equipment_special_abilities() -> Array[String]:
	"""Get all special abilities from equipped items"""
	var abilities: Array[String] = []
	
	if not player_data:
		return abilities
	
	var equipped_items = [
		player_data.equipped_weapon,
		player_data.equipped_armor,
		player_data.equipped_accessory
	]
	
	for item in equipped_items:
		if item:
			abilities.append_array(item.special_abilities)
	
	return abilities

func has_equipment_ability(ability_id: String) -> bool:
	"""Check if any equipped item has a specific ability"""
	var abilities = get_equipment_special_abilities()
	return ability_id in abilities

func get_total_equipment_value() -> int:
	"""Get total value of all equipped items"""
	var total_value = 0
	
	if not player_data:
		return total_value
	
	var equipped_items = [
		player_data.equipped_weapon,
		player_data.equipped_armor,
		player_data.equipped_accessory
	]
	
	for item in equipped_items:
		if item:
			total_value += item.get_total_value()
	
	return total_value

func damage_equipment(damage_amount: int = 1):
	"""Apply durability damage to all equipped items"""
	if not player_data:
		return
	
	var equipped_items = [
		player_data.equipped_weapon,
		player_data.equipped_armor,
		player_data.equipped_accessory
	]
	
	for item in equipped_items:
		if item:
			item.take_durability_damage(damage_amount)
			
			# Check if item broke
			if item.is_broken():
				print("Equipment broke: ", item.name)
				# Could trigger special effects or notifications here

func repair_all_equipment():
	"""Fully repair all equipped items"""
	if not player_data:
		return
	
	var equipped_items = [
		player_data.equipped_weapon,
		player_data.equipped_armor,
		player_data.equipped_accessory
	]
	
	for item in equipped_items:
		if item:
			item.repair()
	
	print("All equipment repaired")

func _on_equipment_changed(slot: String, item: Equipment):
	"""Handle equipment change events"""
	print("Equipment changed in slot ", slot, ": ", item.name if item else "None")
	
	# Update visual for the changed slot
	update_equipment_visual(slot, item)
	
	# Recalculate stats
	calculate_equipment_stats()

func get_equipment_info() -> Dictionary:
	"""Get information about all equipped items"""
	var info = {}
	
	if not player_data:
		return info
	
	info["weapon"] = {
		"item": player_data.equipped_weapon,
		"visual_node": equipment_nodes.get("weapon")
	}
	
	info["armor"] = {
		"item": player_data.equipped_armor,
		"visual_node": equipment_nodes.get("armor")
	}
	
	info["accessory"] = {
		"item": player_data.equipped_accessory,
		"visual_node": equipment_nodes.get("accessory")
	}
	
	return info

func cleanup():
	"""Clean up equipment manager resources"""
	# Remove all equipment visuals
	for slot in equipment_nodes:
		remove_equipment_visual(slot)
	
	# Clear caches
	loaded_models.clear()
	equipment_nodes.clear()
	attachment_points.clear()
	
	print("EquipmentManager cleaned up")

func _exit_tree():
	"""Clean up when node is removed"""
	cleanup()