class_name CompanionCoordinator
extends Node

# Companion Coordinator manages AI companion positioning and commands
# Integrates with lane-based movement system for tactical party positioning

signal companion_command_issued(companion_id: String, command: CompanionCommand)
signal formation_changed(formation_type: FormationType)
signal companion_position_updated(companion_id: String, lane: int, row: int)

var player_node: Node3D
var player_data: PlayerData
var active_companions: Dictionary = {}  # companion_id -> CompanionAI node
var companion_positions: Dictionary = {}  # companion_id -> {lane: int, row: int}
var current_formation: FormationType = FormationType.TRIANGLE

# Formation types for lane-based positioning
enum FormationType {
	TRIANGLE,    # Player front, companions behind in triangle
	LINE,        # All in same row, different lanes
	COLUMN,      # All in same lane, different rows
	SPREAD,      # Maximum spread across lanes and rows
	DEFENSIVE,   # Companions in front of player
	FOLLOW       # Companions follow player closely
}

# Companion command types
enum CompanionCommand {
	FOLLOW,      # Follow player in formation
	HOLD,        # Hold current position
	ATTACK,      # Focus on attacking enemies
	DEFEND,      # Focus on defending player
	RETREAT,     # Move to safer positions
	ABILITY,     # Use special abilities
	MOVE_TO      # Move to specific position
}

# Lane and row constants (matching player system)
const LANE_POSITIONS = [-3.0, 0.0, 3.0]  # Left, Center, Right
const ROW_POSITIONS = [-8.0, -5.0, -2.0, 1.0]  # Back to front

# Formation definitions
var formation_layouts: Dictionary = {}

func _ready():
	"""Initialize companion coordinator"""
	setup_formation_layouts()
	set_process(true)

func initialize(player: Node3D, data: PlayerData):
	"""Initialize with player references"""
	player_node = player
	player_data = data
	
	# Connect to player movement if available
	if player_node.has_signal("stats_changed"):
		player_node.stats_changed.connect(_on_player_stats_changed)
	
	# Load active companions from player data
	if player_data:
		load_active_companions()
	
	print("CompanionCoordinator initialized")

func setup_formation_layouts():
	"""Set up formation position layouts"""
	formation_layouts = {
		FormationType.TRIANGLE: {
			"description": "Triangle formation with player at front",
			"positions": [
				{"lane": 0, "row": 0},  # Left companion behind
				{"lane": 2, "row": 0}   # Right companion behind
			]
		},
		FormationType.LINE: {
			"description": "Line formation across lanes",
			"positions": [
				{"lane": 0, "row": 1},  # Left companion same row
				{"lane": 2, "row": 1}   # Right companion same row
			]
		},
		FormationType.COLUMN: {
			"description": "Column formation in same lane",
			"positions": [
				{"lane": 1, "row": 0},  # First companion behind
				{"lane": 1, "row": -1}  # Second companion further back
			]
		},
		FormationType.SPREAD: {
			"description": "Maximum spread formation",
			"positions": [
				{"lane": 0, "row": 2},  # Left companion forward
				{"lane": 2, "row": 0}   # Right companion back
			]
		},
		FormationType.DEFENSIVE: {
			"description": "Defensive formation with companions in front",
			"positions": [
				{"lane": 0, "row": 2},  # Left companion forward
				{"lane": 2, "row": 2}   # Right companion forward
			]
		},
		FormationType.FOLLOW: {
			"description": "Close follow formation",
			"positions": [
				{"lane": 0, "row": 1},  # Left companion close
				{"lane": 2, "row": 1}   # Right companion close
			]
		}
	}

func load_active_companions():
	"""Load active companions from player data"""
	if not player_data:
		return
	
	for companion_id in player_data.active_companions:
		# For now, we'll create placeholder companion nodes
		# In full implementation, these would be actual CompanionAI instances
		create_companion_placeholder(companion_id)
	
	# Update formation positions
	update_formation_positions()

func create_companion_placeholder(companion_id: String):
	"""Create a placeholder companion node for testing"""
	var companion_node = Node3D.new()
	companion_node.name = companion_id
	
	# Add visual representation
	var mesh_instance = MeshInstance3D.new()
	var capsule = CapsuleMesh.new()
	capsule.height = 1.5
	capsule.radius = 0.3
	mesh_instance.mesh = capsule
	
	# Color based on companion type
	var material = StandardMaterial3D.new()
	match companion_id:
		"tank_companion":
			material.albedo_color = Color.BLUE
		"healer_companion":
			material.albedo_color = Color.GREEN
		"dps_companion":
			material.albedo_color = Color.RED
		_:
			material.albedo_color = Color.YELLOW
	
	mesh_instance.material_override = material
	companion_node.add_child(mesh_instance)
	
	# Add to scene
	if player_node and player_node.get_parent():
		player_node.get_parent().add_child(companion_node)
	
	active_companions[companion_id] = companion_node
	companion_positions[companion_id] = {"lane": 1, "row": 1}
	
	print("Created companion placeholder: ", companion_id)

func _process(delta):
	"""Update companion positions and AI"""
	update_companion_positions(delta)
	process_companion_ai(delta)

func update_companion_positions(delta: float):
	"""Update companion positions based on formation and player position"""
	if not player_node:
		return
	
	var player_lane = player_node.get("current_lane")
	var player_row = player_node.get("current_row")
	
	if player_lane == null or player_row == null:
		return
	
	# Update each companion position
	var companion_index = 0
	for companion_id in active_companions:
		var companion_node = active_companions[companion_id]
		if not is_instance_valid(companion_node):
			continue
		
		var target_position = calculate_companion_target_position(companion_id, companion_index, player_lane, player_row)
		
		# Smooth movement to target position
		var current_pos = companion_node.global_position
		var target_pos = Vector3(target_position.x, current_pos.y, target_position.z)
		
		companion_node.global_position = current_pos.lerp(target_pos, 5.0 * delta)
		
		# Update stored position
		companion_positions[companion_id] = {
			"lane": get_lane_from_x(target_pos.x),
			"row": get_row_from_z(target_pos.z)
		}
		
		companion_index += 1

func calculate_companion_target_position(companion_id: String, index: int, player_lane: int, player_row: int) -> Vector3:
	"""Calculate target position for a companion based on formation"""
	var formation = formation_layouts.get(current_formation, {})
	var positions = formation.get("positions", [])
	
	if index >= positions.size():
		# Default fallback position
		return Vector3(LANE_POSITIONS[1], 0, ROW_POSITIONS[1])
	
	var formation_pos = positions[index]
	var target_lane = clamp(player_lane + formation_pos.lane - 1, 0, 2)
	var target_row = clamp(player_row + formation_pos.row, 0, 3)
	
	return Vector3(LANE_POSITIONS[target_lane], 0, ROW_POSITIONS[target_row])

func process_companion_ai(delta: float):
	"""Process companion AI behavior"""
	for companion_id in active_companions:
		var companion_node = active_companions[companion_id]
		if not is_instance_valid(companion_node):
			continue
		
		# Basic AI processing (placeholder)
		process_companion_behavior(companion_id, companion_node, delta)

func process_companion_behavior(companion_id: String, companion_node: Node3D, delta: float):
	"""Process individual companion behavior"""
	# This would contain the actual AI logic for companions
	# For now, just ensure they're following formation
	pass

func issue_command(command: CompanionCommand, target_companion: String = "", target_position: Vector2 = Vector2.ZERO):
	"""Issue a command to companions"""
	print("Issuing command: ", CompanionCommand.keys()[command])
	
	match command:
		CompanionCommand.FOLLOW:
			set_formation(FormationType.TRIANGLE)
		CompanionCommand.HOLD:
			# Companions hold current positions
			for companion_id in active_companions:
				print("Companion ", companion_id, " holding position")
		CompanionCommand.ATTACK:
			# Companions focus on attacking
			for companion_id in active_companions:
				print("Companion ", companion_id, " focusing on attack")
		CompanionCommand.DEFEND:
			set_formation(FormationType.DEFENSIVE)
		CompanionCommand.RETREAT:
			set_formation(FormationType.COLUMN)
		CompanionCommand.ABILITY:
			# Companions use special abilities
			for companion_id in active_companions:
				trigger_companion_ability(companion_id)
		CompanionCommand.MOVE_TO:
			if target_companion != "":
				move_companion_to_position(target_companion, target_position)
	
	companion_command_issued.emit(target_companion, command)

func set_formation(formation: FormationType):
	"""Set the current formation type"""
	current_formation = formation
	update_formation_positions()
	formation_changed.emit(formation)
	
	var formation_name = FormationType.keys()[formation]
	print("Formation changed to: ", formation_name)

func cycle_formation():
	"""Cycle to the next formation type"""
	var current_index = current_formation
	var next_index = (current_index + 1) % FormationType.size()
	var old_formation_name = FormationType.keys()[current_index]
	var new_formation_name = FormationType.keys()[next_index]
	
	set_formation(next_index as FormationType)
	
	print("Formation cycled: ", old_formation_name, " → ", new_formation_name)
	
	# Get formation description for user feedback
	var formation_data = formation_layouts.get(next_index, {})
	var description = formation_data.get("description", "")
	if description != "":
		print("  ", description)

func update_formation_positions():
	"""Update all companion positions based on current formation"""
	# Positions will be updated in the next _process call
	print("Updating formation positions for: ", FormationType.keys()[current_formation])

func move_companion_to_position(companion_id: String, position: Vector2):
	"""Move specific companion to a position"""
	if not active_companions.has(companion_id):
		print("Companion not found: ", companion_id)
		return
	
	var lane = clamp(int(position.x), 0, 2)
	var row = clamp(int(position.y), 0, 3)
	
	companion_positions[companion_id] = {"lane": lane, "row": row}
	companion_position_updated.emit(companion_id, lane, row)
	
	print("Moving companion ", companion_id, " to lane ", lane, " row ", row)

func trigger_companion_ability(companion_id: String):
	"""Trigger a companion's special ability"""
	print("Triggering ability for companion: ", companion_id)
	
	# This would integrate with the companion's ability system
	# For now, just create a visual effect
	create_companion_ability_effect(companion_id)

func create_companion_ability_effect(companion_id: String):
	"""Create visual effect for companion ability"""
	var companion_node = active_companions.get(companion_id)
	if not is_instance_valid(companion_node):
		return
	
	# Create ability effect particle
	var indicator = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.4
	indicator.mesh = sphere
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.CYAN
	material.emission_enabled = true
	material.emission = Color.CYAN * 0.8
	indicator.material_override = material
	
	indicator.position = companion_node.position + Vector3(0, 2, 0)
	companion_node.get_parent().add_child(indicator)
	
	# Animate effect
	var tween = create_tween()
	tween.parallel().tween_property(indicator, "scale", Vector3.ZERO, 0.8)
	tween.parallel().tween_property(indicator, "position:y", indicator.position.y + 3, 0.8)
	tween.tween_callback(indicator.queue_free)

func add_companion(companion_id: String):
	"""Add a new companion to the active party"""
	if companion_id in active_companions:
		print("Companion already active: ", companion_id)
		return
	
	if active_companions.size() >= 2:
		print("Maximum companions reached (2)")
		return
	
	create_companion_placeholder(companion_id)
	
	# Update player data
	if player_data and not companion_id in player_data.active_companions:
		player_data.active_companions.append(companion_id)
	
	update_formation_positions()
	print("Added companion: ", companion_id)

func remove_companion(companion_id: String):
	"""Remove a companion from the active party"""
	if not companion_id in active_companions:
		print("Companion not active: ", companion_id)
		return
	
	var companion_node = active_companions[companion_id]
	if is_instance_valid(companion_node):
		companion_node.queue_free()
	
	active_companions.erase(companion_id)
	companion_positions.erase(companion_id)
	
	# Update player data
	if player_data:
		player_data.active_companions.erase(companion_id)
	
	update_formation_positions()
	print("Removed companion: ", companion_id)

func get_companion_position(companion_id: String) -> Dictionary:
	"""Get current position of a companion"""
	return companion_positions.get(companion_id, {"lane": -1, "row": -1})

func get_companion_count() -> int:
	"""Get number of active companions"""
	return active_companions.size()

func get_active_companion_ids() -> Array[String]:
	"""Get list of active companion IDs"""
	var ids: Array[String] = []
	for companion_id in active_companions:
		ids.append(companion_id)
	return ids

func is_companion_active(companion_id: String) -> bool:
	"""Check if a companion is currently active"""
	return companion_id in active_companions

func get_formation_info() -> Dictionary:
	"""Get information about current formation"""
	var formation_name = FormationType.keys()[current_formation]
	var formation_data = formation_layouts.get(current_formation, {})
	
	return {
		"type": current_formation,
		"name": formation_name,
		"description": formation_data.get("description", ""),
		"companion_count": active_companions.size()
	}

func get_available_formations() -> Array[Dictionary]:
	"""Get list of available formations"""
	var formations: Array[Dictionary] = []
	
	for formation_type in FormationType.values():
		var formation_name = FormationType.keys()[formation_type]
		var formation_data = formation_layouts.get(formation_type, {})
		
		formations.append({
			"type": formation_type,
			"name": formation_name,
			"description": formation_data.get("description", "")
		})
	
	return formations

func get_lane_from_x(x_position: float) -> int:
	"""Convert X position to lane index"""
	var min_distance = 999.0
	var closest_lane = 1
	
	for i in range(LANE_POSITIONS.size()):
		var distance = abs(x_position - LANE_POSITIONS[i])
		if distance < min_distance:
			min_distance = distance
			closest_lane = i
	
	return closest_lane

func get_row_from_z(z_position: float) -> int:
	"""Convert Z position to row index"""
	var min_distance = 999.0
	var closest_row = 1
	
	for i in range(ROW_POSITIONS.size()):
		var distance = abs(z_position - ROW_POSITIONS[i])
		if distance < min_distance:
			min_distance = distance
			closest_row = i
	
	return closest_row

func _on_player_stats_changed():
	"""Handle player stats changes"""
	# Could adjust companion behavior based on player stats
	pass

func debug_companion_system():
	"""Debug information about companion system"""
	print("=== COMPANION SYSTEM DEBUG ===")
	print("Active companions: ", active_companions.size())
	for companion_id in active_companions:
		var pos = companion_positions.get(companion_id, {})
		print("  ", companion_id, ": Lane ", pos.get("lane", -1), " Row ", pos.get("row", -1))
	
	var formation_info = get_formation_info()
	print("Current formation: ", formation_info.name, " - ", formation_info.description)
	print("===============================")
