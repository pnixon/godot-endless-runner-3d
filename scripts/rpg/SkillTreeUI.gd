class_name SkillTreeUI
extends Control

# Skill Tree UI provides interface for viewing and allocating skill points
# Displays Warrior, Mage, and Rogue progression paths with visual skill trees

signal skill_point_allocated(skill_tree: String)
signal ability_selected(ability_id: String)
signal skill_tree_changed(tree_name: String)

var player_data: PlayerData
var level_up_system: LevelUpSystem
var current_skill_tree: String = "warrior"

# UI Components
var skill_tree_tabs: TabContainer
var warrior_tree: Control
var mage_tree: Control
var rogue_tree: Control
var skill_points_label: Label
var close_button: Button

# Skill tree layouts
var skill_nodes: Dictionary = {}  # tree_name -> Array[SkillNode]
var connection_lines: Dictionary = {}  # tree_name -> Array[Line2D]

# Visual settings
const SKILL_NODE_SIZE = Vector2(80, 80)
const SKILL_NODE_SPACING = Vector2(120, 100)
const TREE_PADDING = Vector2(50, 50)

# Colors
const COLOR_AVAILABLE = Color.GREEN
const COLOR_UNLOCKED = Color.GOLD
const COLOR_LOCKED = Color.GRAY
const COLOR_MAXED = Color.CYAN

func _ready():
	"""Initialize skill tree UI"""
	setup_ui_structure()
	hide()  # Start hidden

func initialize(data: PlayerData, level_system: LevelUpSystem):
	"""Initialize with player data and level system"""
	player_data = data
	level_up_system = level_system
	
	# Connect signals
	if level_up_system:
		level_up_system.skill_point_allocated.connect(_on_skill_point_allocated)
		level_up_system.ability_unlocked.connect(_on_ability_unlocked)
	
	if player_data and player_data.stats:
		player_data.stats.stats_changed.connect(_on_stats_changed)
	
	# Build skill trees
	build_skill_trees()
	update_skill_tree_display()
	
	print("SkillTreeUI initialized")

func setup_ui_structure():
	"""Set up the basic UI structure"""
	# Main container
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Background panel
	var background = Panel.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = Color(0, 0, 0, 0.8)  # Semi-transparent background
	add_child(background)
	
	# Main content container
	var main_container = VBoxContainer.new()
	main_container.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	main_container.custom_minimum_size = Vector2(800, 600)
	add_child(main_container)
	
	# Header
	var header = HBoxContainer.new()
	main_container.add_child(header)
	
	var title_label = Label.new()
	title_label.text = "Skill Trees"
	title_label.add_theme_font_size_override("font_size", 24)
	header.add_child(title_label)
	
	header.add_child(VSeparator.new())
	
	skill_points_label = Label.new()
	skill_points_label.text = "Skill Points: 0"
	skill_points_label.add_theme_font_size_override("font_size", 18)
	header.add_child(skill_points_label)
	
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	
	close_button = Button.new()
	close_button.text = "Close"
	close_button.pressed.connect(_on_close_pressed)
	header.add_child(close_button)
	
	# Tab container for skill trees
	skill_tree_tabs = TabContainer.new()
	skill_tree_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_container.add_child(skill_tree_tabs)
	
	# Create skill tree tabs
	warrior_tree = create_skill_tree_tab("Warrior")
	mage_tree = create_skill_tree_tab("Mage")
	rogue_tree = create_skill_tree_tab("Rogue")
	
	skill_tree_tabs.add_child(warrior_tree)
	skill_tree_tabs.add_child(mage_tree)
	skill_tree_tabs.add_child(rogue_tree)
	
	# Connect tab change signal
	skill_tree_tabs.tab_changed.connect(_on_tab_changed)

func create_skill_tree_tab(tree_name: String) -> Control:
	"""Create a skill tree tab"""
	var tab = Control.new()
	tab.name = tree_name
	
	# Scroll container for the skill tree
	var scroll = ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tab.add_child(scroll)
	
	# Container for skill nodes
	var container = Control.new()
	container.custom_minimum_size = Vector2(1000, 800)  # Large enough for skill tree
	scroll.add_child(container)
	
	return tab

func build_skill_trees():
	"""Build all skill trees with nodes and connections"""
	build_warrior_tree()
	build_mage_tree()
	build_rogue_tree()

func build_warrior_tree():
	"""Build the warrior skill tree"""
	var tree_name = "warrior"
	var container = get_skill_tree_container(tree_name)
	
	if not container:
		return
	
	# Clear existing nodes
	clear_skill_tree(tree_name)
	
	# Define warrior skill tree layout
	var skill_layout = [
		{"id": "warrior_charge", "pos": Vector2(2, 0), "tier": 1},
		{"id": "warrior_shield", "pos": Vector2(1, 1), "tier": 3},
		{"id": "warrior_taunt", "pos": Vector2(3, 1), "tier": 3},
		{"id": "warrior_berserker", "pos": Vector2(2, 2), "tier": 5},
		{"id": "warrior_whirlwind", "pos": Vector2(2, 3), "tier": 10}
	]
	
	# Create skill nodes
	var nodes = []
	for skill_info in skill_layout:
		var node = create_skill_node(skill_info.id, tree_name, skill_info.tier)
		var pos = TREE_PADDING + skill_info.pos * SKILL_NODE_SPACING
		node.position = pos
		container.add_child(node)
		nodes.append(node)
	
	skill_nodes[tree_name] = nodes
	
	# Create connections
	create_skill_connections(tree_name, [
		[0, 1],  # charge -> shield
		[0, 2],  # charge -> taunt
		[1, 3],  # shield -> berserker
		[2, 3],  # taunt -> berserker
		[3, 4]   # berserker -> whirlwind
	])

func build_mage_tree():
	"""Build the mage skill tree"""
	var tree_name = "mage"
	var container = get_skill_tree_container(tree_name)
	
	if not container:
		return
	
	clear_skill_tree(tree_name)
	
	var skill_layout = [
		{"id": "mage_fireball", "pos": Vector2(1, 0), "tier": 1},
		{"id": "mage_heal", "pos": Vector2(3, 0), "tier": 1},
		{"id": "mage_lightning", "pos": Vector2(2, 1), "tier": 5},
		{"id": "mage_shield", "pos": Vector2(1, 2), "tier": 7},
		{"id": "mage_meteor", "pos": Vector2(2, 3), "tier": 10}
	]
	
	var nodes = []
	for skill_info in skill_layout:
		var node = create_skill_node(skill_info.id, tree_name, skill_info.tier)
		var pos = TREE_PADDING + skill_info.pos * SKILL_NODE_SPACING
		node.position = pos
		container.add_child(node)
		nodes.append(node)
	
	skill_nodes[tree_name] = nodes
	
	create_skill_connections(tree_name, [
		[0, 2],  # fireball -> lightning
		[1, 2],  # heal -> lightning
		[2, 3],  # lightning -> shield
		[2, 4],  # lightning -> meteor
		[3, 4]   # shield -> meteor
	])

func build_rogue_tree():
	"""Build the rogue skill tree"""
	var tree_name = "rogue"
	var container = get_skill_tree_container(tree_name)
	
	if not container:
		return
	
	clear_skill_tree(tree_name)
	
	var skill_layout = [
		{"id": "rogue_dash", "pos": Vector2(2, 0), "tier": 1},
		{"id": "rogue_stealth", "pos": Vector2(1, 1), "tier": 3},
		{"id": "rogue_poison", "pos": Vector2(3, 1), "tier": 5},
		{"id": "rogue_backstab", "pos": Vector2(2, 2), "tier": 7},
		{"id": "rogue_assassinate", "pos": Vector2(2, 3), "tier": 10}
	]
	
	var nodes = []
	for skill_info in skill_layout:
		var node = create_skill_node(skill_info.id, tree_name, skill_info.tier)
		var pos = TREE_PADDING + skill_info.pos * SKILL_NODE_SPACING
		node.position = pos
		container.add_child(node)
		nodes.append(node)
	
	skill_nodes[tree_name] = nodes
	
	create_skill_connections(tree_name, [
		[0, 1],  # dash -> stealth
		[0, 2],  # dash -> poison
		[1, 3],  # stealth -> backstab
		[2, 3],  # poison -> backstab
		[3, 4]   # backstab -> assassinate
	])

func create_skill_node(ability_id: String, tree_name: String, tier: int) -> Control:
	"""Create a skill node for an ability"""
	var node = Control.new()
	node.custom_minimum_size = SKILL_NODE_SIZE
	node.name = ability_id
	
	# Background button
	var button = Button.new()
	button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	button.flat = true
	button.pressed.connect(_on_skill_node_pressed.bind(ability_id, tree_name))
	node.add_child(button)
	
	# Skill icon (placeholder)
	var icon = ColorRect.new()
	icon.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	icon.size = Vector2(60, 60)
	icon.color = COLOR_LOCKED
	node.add_child(icon)
	
	# Skill name label
	var name_label = Label.new()
	name_label.text = get_ability_display_name(ability_id)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	name_label.position.y -= 20
	name_label.add_theme_font_size_override("font_size", 12)
	node.add_child(name_label)
	
	# Tier requirement label
	var tier_label = Label.new()
	tier_label.text = "Tier " + str(tier)
	tier_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tier_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	tier_label.position.y += 5
	tier_label.add_theme_font_size_override("font_size", 10)
	tier_label.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	node.add_child(tier_label)
	
	return node

func create_skill_connections(tree_name: String, connections: Array):
	"""Create visual connections between skill nodes"""
	var container = get_skill_tree_container(tree_name)
	if not container or not skill_nodes.has(tree_name):
		return
	
	var nodes = skill_nodes[tree_name]
	var lines = []
	
	for connection in connections:
		var from_idx = connection[0]
		var to_idx = connection[1]
		
		if from_idx >= nodes.size() or to_idx >= nodes.size():
			continue
		
		var from_node = nodes[from_idx]
		var to_node = nodes[to_idx]
		
		var line = Line2D.new()
		line.width = 3.0
		line.default_color = Color.DARK_GRAY
		
		# Calculate line points
		var from_pos = from_node.position + SKILL_NODE_SIZE * 0.5
		var to_pos = to_node.position + SKILL_NODE_SIZE * 0.5
		
		line.add_point(from_pos)
		line.add_point(to_pos)
		
		container.add_child(line)
		lines.append(line)
	
	connection_lines[tree_name] = lines

func get_skill_tree_container(tree_name: String) -> Control:
	"""Get the container for a skill tree"""
	var tab_index = -1
	match tree_name:
		"warrior": tab_index = 0
		"mage": tab_index = 1
		"rogue": tab_index = 2
	
	if tab_index >= 0 and tab_index < skill_tree_tabs.get_child_count():
		var tab = skill_tree_tabs.get_child(tab_index)
		var scroll = tab.get_child(0) as ScrollContainer
		if scroll:
			return scroll.get_child(0)
	
	return null

func clear_skill_tree(tree_name: String):
	"""Clear existing skill tree nodes and connections"""
	if skill_nodes.has(tree_name):
		for node in skill_nodes[tree_name]:
			if is_instance_valid(node):
				node.queue_free()
		skill_nodes.erase(tree_name)
	
	if connection_lines.has(tree_name):
		for line in connection_lines[tree_name]:
			if is_instance_valid(line):
				line.queue_free()
		connection_lines.erase(tree_name)

func update_skill_tree_display():
	"""Update the visual state of all skill trees"""
	if not player_data or not player_data.stats:
		return
	
	# Update skill points label
	skill_points_label.text = "Skill Points: " + str(player_data.stats.available_skill_points)
	
	# Update each skill tree
	update_tree_display("warrior")
	update_tree_display("mage")
	update_tree_display("rogue")

func update_tree_display(tree_name: String):
	"""Update visual state of a specific skill tree"""
	if not skill_nodes.has(tree_name):
		return
	
	var nodes = skill_nodes[tree_name]
	var current_points = get_skill_tree_points(tree_name)
	var unlocked_abilities = get_unlocked_abilities(tree_name)
	
	for node in nodes:
		var ability_id = node.name
		var tier = get_ability_tier(ability_id)
		var is_unlocked = ability_id in unlocked_abilities
		var can_unlock = current_points >= tier and not is_unlocked and player_data.stats.available_skill_points > 0
		
		# Update node color
		var icon = node.get_child(1) as ColorRect  # Icon is second child
		if is_unlocked:
			icon.color = COLOR_UNLOCKED
		elif can_unlock:
			icon.color = COLOR_AVAILABLE
		else:
			icon.color = COLOR_LOCKED
		
		# Update button state
		var button = node.get_child(0) as Button
		button.disabled = not can_unlock

func get_ability_display_name(ability_id: String) -> String:
	"""Get display name for ability"""
	# This would normally come from ability definitions
	match ability_id:
		"warrior_charge": return "Charge"
		"warrior_shield": return "Shield Bash"
		"warrior_berserker": return "Berserker"
		"warrior_taunt": return "Taunt"
		"warrior_whirlwind": return "Whirlwind"
		"mage_fireball": return "Fireball"
		"mage_heal": return "Heal"
		"mage_lightning": return "Lightning"
		"mage_shield": return "Mana Shield"
		"mage_meteor": return "Meteor"
		"rogue_dash": return "Dash"
		"rogue_stealth": return "Stealth"
		"rogue_poison": return "Poison"
		"rogue_backstab": return "Backstab"
		"rogue_assassinate": return "Assassinate"
		_: return ability_id

func get_ability_tier(ability_id: String) -> int:
	"""Get tier requirement for ability"""
	# This would normally come from ability definitions
	match ability_id:
		"warrior_charge", "mage_fireball", "mage_heal", "rogue_dash": return 1
		"warrior_shield", "warrior_taunt", "rogue_stealth": return 3
		"warrior_berserker", "mage_lightning", "rogue_poison": return 5
		"mage_shield", "rogue_backstab": return 7
		"warrior_whirlwind", "mage_meteor", "rogue_assassinate": return 10
		_: return 1

func get_skill_tree_points(tree_name: String) -> int:
	"""Get current points in skill tree"""
	if not player_data or not player_data.stats:
		return 0
	
	match tree_name:
		"warrior": return player_data.stats.warrior_points
		"mage": return player_data.stats.mage_points
		"rogue": return player_data.stats.rogue_points
		_: return 0

func get_unlocked_abilities(tree_name: String) -> Array[String]:
	"""Get unlocked abilities for skill tree"""
	if not player_data:
		return []
	
	match tree_name:
		"warrior": return player_data.unlocked_warrior_abilities
		"mage": return player_data.unlocked_mage_abilities
		"rogue": return player_data.unlocked_rogue_abilities
		_: return []

func show_skill_tree():
	"""Show the skill tree UI"""
	update_skill_tree_display()
	show()
	print("Skill tree UI opened")

func hide_skill_tree():
	"""Hide the skill tree UI"""
	hide()
	print("Skill tree UI closed")

func _on_skill_node_pressed(ability_id: String, tree_name: String):
	"""Handle skill node button press"""
	if not level_up_system:
		return
	
	# Try to allocate skill point
	var success = level_up_system.allocate_skill_point(tree_name)
	if success:
		print("Allocated skill point to ", tree_name, " for ability ", ability_id)
		skill_point_allocated.emit(tree_name)
		update_skill_tree_display()
	else:
		print("Failed to allocate skill point to ", tree_name)

func _on_tab_changed(tab_index: int):
	"""Handle skill tree tab change"""
	match tab_index:
		0: current_skill_tree = "warrior"
		1: current_skill_tree = "mage"
		2: current_skill_tree = "rogue"
	
	skill_tree_changed.emit(current_skill_tree)
	print("Switched to ", current_skill_tree, " skill tree")

func _on_close_pressed():
	"""Handle close button press"""
	hide_skill_tree()

func _on_skill_point_allocated(skill_tree: String):
	"""Handle skill point allocation"""
	update_skill_tree_display()

func _on_ability_unlocked(ability_id: String, skill_tree: String):
	"""Handle ability unlock"""
	update_skill_tree_display()
	print("Ability unlocked in UI: ", ability_id)

func _on_stats_changed():
	"""Handle player stats change"""
	update_skill_tree_display()

func _input(event):
	"""Handle input events"""
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_K and visible:
			hide_skill_tree()
		elif event.keycode == KEY_K and not visible:
			show_skill_tree()