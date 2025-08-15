class_name CombatGrid
extends Node2D

# Enemy states
enum EnemyState {
	IDLE,
	MOVING,
	PREPARING_ATTACK,
	ATTACKING,
	COOLDOWN
}

# Row constants - 4 rows for both running and combat
const GRID_COLS = 3  # Lanes: 0, 1, 2 (left, center, right)
const GRID_ROWS = 4  # Rows: 0 (front), 1, 2, 3 (back)
const ROW_HEIGHT = 100  # Vertical spacing between rows
const LANE_WIDTH = 128   # Horizontal spacing between lanes
const BASE_Y = 400       # Base Y position for front row

# Grid data
var grid_tiles: Array[Array] = []
var actors: Dictionary = {}  # actor_id -> Actor data
var current_beat = 0
var beat_timer = 0.0
const BEAT_DURATION = 0.5  # 0.5 seconds per beat

# Combat state
var player_actor_id = "player"
var combat_active = false

func _ready():
	print("CombatGrid _ready() called")
	initialize_grid()
	
	# No visual grid - just logical positioning
	visible = true  # Always visible for actor management

func initialize_grid():
	# Initialize 3x4 grid with empty tiles
	grid_tiles = []
	for col in range(GRID_COLS):
		var column = []
		for row in range(GRID_ROWS):
			column.append(create_empty_tile())
		grid_tiles.append(column)
	
	print("Initialized ", GRID_COLS, "x", GRID_ROWS, " row system")

func create_empty_tile() -> Dictionary:
	return {
		"occupied": false,
		"actor_id": "",
		"zone_effect": null,
		"highlighted": false
	}

func get_row_world_position(col: int, row: int) -> Vector2:
	# Convert grid coordinates to world position
	var x = 384 + (col * LANE_WIDTH)  # Lane positions: 384, 512, 640
	var y = BASE_Y - (row * ROW_HEIGHT)  # Rows get higher Y (closer to top) as row increases
	return Vector2(x, y)

func get_row_from_world_position(world_pos: Vector2) -> Vector2i:
	# Convert world position to grid coordinates
	var col = round((world_pos.x - 384) / LANE_WIDTH)
	var row = round((BASE_Y - world_pos.y) / ROW_HEIGHT)
	
	# Clamp to valid bounds
	col = clamp(col, 0, GRID_COLS - 1)
	row = clamp(row, 0, GRID_ROWS - 1)
	
	return Vector2i(col, row)

func is_valid_cell(col: int, row: int) -> bool:
	return col >= 0 and col < GRID_COLS and row >= 0 and row < GRID_ROWS

func is_cell_occupied(col: int, row: int) -> bool:
	if not is_valid_cell(col, row):
		return true  # Out of bounds counts as occupied
	return grid_tiles[col][row]["occupied"]

func place_actor(actor_id: String, col: int, row: int, actor_data: Dictionary) -> bool:
	if not is_valid_cell(col, row) or is_cell_occupied(col, row):
		print("Cannot place actor ", actor_id, " at (", col, ",", row, ") - invalid or occupied")
		return false
	
	# Mark cell as occupied
	grid_tiles[col][row]["occupied"] = true
	grid_tiles[col][row]["actor_id"] = actor_id
	
	# Store actor data
	actor_data["position"] = Vector2i(col, row)
	actor_data["world_position"] = get_row_world_position(col, row)
	actors[actor_id] = actor_data
	
	# Create visual sprite for the actor
	create_actor_sprite(actor_id, actor_data)
	
	print("Placed actor ", actor_id, " at row (", col, ",", row, ") world pos: ", actor_data["world_position"])
	return true

func create_actor_sprite(actor_id: String, actor_data: Dictionary):
	var sprite = Sprite2D.new()
	sprite.name = "ActorSprite_" + actor_id
	
	# Create colored rectangle based on actor type
	var sprite_texture = ImageTexture.new()
	var sprite_image = Image.create(60, 60, false, Image.FORMAT_RGB8)
	
	var color: Color
	match actor_data["type"]:
		"player":
			color = Color.BLUE
		"enemy":
			# Different colors for different enemy types
			match actor_data["name"]:
				"Goblin":
					color = Color.GREEN
				"Slime":
					color = Color.LIME
				"City Guard":
					color = Color.GRAY
				"Street Thug":
					color = Color.DARK_GRAY
				"Bandit":
					color = Color.BROWN
				_:
					color = Color.RED  # Default enemy color
		_:
			color = Color.WHITE
	
	sprite_image.fill(color)
	sprite_texture.set_image(sprite_image)
	sprite.texture = sprite_texture
	sprite.position = actor_data["world_position"]
	sprite.z_index = 10
	
	# Store sprite reference in actor data
	actor_data["sprite"] = sprite
	
	add_child(sprite)
	
	# Create HP bar above the sprite
	create_hp_bar(actor_id, actor_data, sprite)
	
	print("Created sprite for ", actor_id, " at ", sprite.position)

func create_hp_bar(actor_id: String, actor_data: Dictionary, parent_sprite: Sprite2D):
	# Create HP bar background
	var hp_bg = Sprite2D.new()
	hp_bg.name = "HPBar_BG_" + actor_id
	var bg_texture = ImageTexture.new()
	var bg_image = Image.create(50, 6, false, Image.FORMAT_RGB8)
	bg_image.fill(Color.BLACK)
	bg_texture.set_image(bg_image)
	hp_bg.texture = bg_texture
	hp_bg.position = Vector2(0, -40)  # Above the actor sprite
	hp_bg.z_index = 11
	parent_sprite.add_child(hp_bg)
	
	# Create HP bar foreground
	var hp_fg = Sprite2D.new()
	hp_fg.name = "HPBar_FG_" + actor_id
	var fg_texture = ImageTexture.new()
	var fg_image = Image.create(48, 4, false, Image.FORMAT_RGB8)
	
	# Color based on actor type
	var hp_color = Color.GREEN if actor_data["type"] == "player" else Color.RED
	fg_image.fill(hp_color)
	fg_texture.set_image(fg_image)
	hp_fg.texture = fg_texture
	hp_fg.position = Vector2(0, -40)  # Same position as background
	hp_fg.z_index = 12
	parent_sprite.add_child(hp_fg)
	
	# Store HP bar references
	actor_data["hp_bg"] = hp_bg
	actor_data["hp_fg"] = hp_fg
	
	# Update HP bar to current health
	update_hp_bar(actor_id)

func update_hp_bar(actor_id: String):
	if not actors.has(actor_id):
		return
	
	var actor = actors[actor_id]
	if not actor.has("hp_fg") or not actor["hp_fg"]:
		return
	
	var hp_ratio = float(actor["hp"]) / float(actor["max_hp"])
	var new_width = int(48 * hp_ratio)
	
	# Update HP bar width
	var fg_texture = ImageTexture.new()
	var fg_image = Image.create(max(1, new_width), 4, false, Image.FORMAT_RGB8)
	
	# Color based on health percentage
	var hp_color: Color
	if hp_ratio > 0.6:
		hp_color = Color.GREEN
	elif hp_ratio > 0.3:
		hp_color = Color.YELLOW
	else:
		hp_color = Color.RED
	
	fg_image.fill(hp_color)
	fg_texture.set_image(fg_image)
	actor["hp_fg"].texture = fg_texture

func move_actor(actor_id: String, new_col: int, new_row: int) -> bool:
	if not actors.has(actor_id):
		print("Actor ", actor_id, " not found")
		return false
	
	var actor = actors[actor_id]
	var old_pos = actor["position"]
	
	if not is_valid_cell(new_col, new_row) or is_cell_occupied(new_col, new_row):
		print("Cannot move actor ", actor_id, " to (", new_col, ",", new_row, ") - invalid or occupied")
		return false
	
	# Clear old cell
	grid_tiles[old_pos.x][old_pos.y]["occupied"] = false
	grid_tiles[old_pos.x][old_pos.y]["actor_id"] = ""
	
	# Occupy new cell
	grid_tiles[new_col][new_row]["occupied"] = true
	grid_tiles[new_col][new_row]["actor_id"] = actor_id
	
	# Update actor data
	actor["position"] = Vector2i(new_col, new_row)
	actor["world_position"] = get_row_world_position(new_col, new_row)
	
	# Move the visual sprite (only for enemies, not player)
	if actor.has("sprite") and actor["sprite"]:
		actor["sprite"].position = actor["world_position"]
	elif actor_id == player_actor_id:
		# Move the existing player node
		var existing_player = get_tree().get_first_node_in_group("player")
		if existing_player:
			existing_player.position = actor["world_position"]
	
	print("Moved actor ", actor_id, " from (", old_pos.x, ",", old_pos.y, ") to (", new_col, ",", new_row, ")")
	return true

func remove_actor(actor_id: String):
	if not actors.has(actor_id):
		return
	
	var actor = actors[actor_id]
	var pos = actor["position"]
	
	# Clear grid cell
	grid_tiles[pos.x][pos.y]["occupied"] = false
	grid_tiles[pos.x][pos.y]["actor_id"] = ""
	
	# Clean up enemy warning effects
	if actor["type"] == "enemy":
		clear_enemy_warning(actor_id)
	
	# Remove visual sprite
	if actor.has("sprite") and actor["sprite"]:
		actor["sprite"].queue_free()
	
	# Remove from actors dictionary
	actors.erase(actor_id)
	
	print("Removed actor ", actor_id, " from grid")

func start_combat(player_lane: int, formation_id: String):
	print("=== STARTING COMBAT ===")
	print("Player lane: ", player_lane, " Formation: ", formation_id)
	
	combat_active = true
	current_beat = 0
	beat_timer = 0.0
	
	# Clear any existing actors
	actors.clear()
	initialize_grid()
	
	# Don't create a new player sprite - use the existing player position
	# Just track the existing player in our grid system
	var existing_player = get_tree().get_first_node_in_group("player")
	if existing_player:
		# Position the existing player at the front row of their lane
		var player_world_pos = get_row_world_position(player_lane, 0)
		existing_player.position = player_world_pos
		
		# Track player in our grid system without creating a sprite
		var player_data = {
			"name": "Player",
			"type": "player",
			"hp": 100,
			"max_hp": 100,
			"power": 10,
			"agility": 10,
			"resolve": 10,
			"focus": 10,
			"sprite": null  # Don't create a new sprite, use existing player
		}
		
		# Mark grid cell as occupied
		grid_tiles[player_lane][0]["occupied"] = true
		grid_tiles[player_lane][0]["actor_id"] = player_actor_id
		
		# Store actor data
		player_data["position"] = Vector2i(player_lane, 0)
		player_data["world_position"] = player_world_pos
		actors[player_actor_id] = player_data
		
		print("Using existing player at combat position: ", player_world_pos)
	
	# Spawn enemies based on formation
	spawn_formation(formation_id)
	
	print("Combat started with ", actors.size(), " actors")
	print("=== COMBAT ACTIVE ===")

func spawn_formation(formation_id: String):
	# Spawn enemies based on formation ID - enemies stay in back rows (2-3) but can switch lanes
	match formation_id:
		"single_goblin":
			spawn_enemy("goblin_1", "Goblin", 1, 3, {"hp": 30, "power": 8, "attack_pattern": "single_target"})
		
		"weak_slime":
			spawn_enemy("slime_1", "Slime", 1, 2, {"hp": 20, "power": 5, "attack_pattern": "column_attack"})
		
		"city_guard":
			spawn_enemy("guard_1", "City Guard", 1, 3, {"hp": 50, "power": 12, "attack_pattern": "row_attack"})
		
		"street_thug":
			spawn_enemy("thug_1", "Street Thug", 0, 2, {"hp": 35, "power": 10, "attack_pattern": "single_target"})
			spawn_enemy("thug_2", "Street Thug", 2, 2, {"hp": 35, "power": 10, "attack_pattern": "single_target"})
		
		"dual_bandits":
			spawn_enemy("bandit_1", "Bandit", 0, 3, {"hp": 40, "power": 11, "attack_pattern": "diagonal_attack"})
			spawn_enemy("bandit_2", "Bandit", 2, 3, {"hp": 40, "power": 11, "attack_pattern": "diagonal_attack"})
		
		_:  # Default fallback
			spawn_enemy("goblin_1", "Goblin", 1, 3, {"hp": 30, "power": 8, "attack_pattern": "single_target"})

func spawn_enemy(enemy_id: String, enemy_name: String, col: int, row: int, stats: Dictionary):
	var enemy_data = {
		"name": enemy_name,
		"type": "enemy",
		"hp": stats.get("hp", 30),
		"max_hp": stats.get("hp", 30),
		"power": stats.get("power", 8),
		"attack_pattern": stats.get("attack_pattern", "single_target"),
		"agility": 5,
		"resolve": 5,
		"focus": 5,
		"intent": "",
		"cooldowns": {},
		"min_row": 2,  # Enemies stay in back rows (2-3)
		"max_row": 3,
		# State machine variables
		"state": EnemyState.IDLE,
		"state_timer": 0.0,
		"prepare_duration": 0.8,  # 0.8 seconds to prepare attack
		"attack_duration": 0.2,   # 0.2 seconds attack animation
		"cooldown_duration": 1.0  # 1.0 seconds cooldown after attack
	}
	
	if place_actor(enemy_id, col, row, enemy_data):
		print("Spawned ", enemy_name, " at (", col, ",", row, ") with attack pattern: ", enemy_data["attack_pattern"])
	else:
		print("Failed to spawn ", enemy_name, " at (", col, ",", row, ")")

func end_combat():
	print("=== ENDING COMBAT ===")
	combat_active = false
	
	# Clean up all actor sprites and warning effects
	for actor_id in actors.keys():
		var actor = actors[actor_id]
		
		# Clean up enemy warning effects
		if actor["type"] == "enemy":
			clear_enemy_warning(actor_id)
		
		# Clean up sprites
		if actor.has("sprite") and actor["sprite"]:
			actor["sprite"].queue_free()
	
	# Clear all actors
	actors.clear()
	initialize_grid()
	
	print("Combat ended")

func _process(delta):
	if not combat_active:
		return
	
	# Handle beat timing
	beat_timer += delta
	if beat_timer >= BEAT_DURATION:
		advance_beat()
		beat_timer = 0.0
	
	# Handle enemy state timers
	for actor_id in actors.keys():
		var actor = actors[actor_id]
		if actor["type"] == "enemy":
			update_enemy_state(actor_id, delta)

func update_enemy_state(enemy_id: String, delta: float):
	if not actors.has(enemy_id):
		return
	
	var enemy = actors[enemy_id]
	
	# Update state timer
	if enemy["state_timer"] > 0.0:
		enemy["state_timer"] -= delta
		
		# Check for state transitions
		if enemy["state_timer"] <= 0.0:
			match enemy["state"]:
				EnemyState.PREPARING_ATTACK:
					# Preparation finished - execute attack
					enemy["state"] = EnemyState.ATTACKING
					enemy["state_timer"] = enemy["attack_duration"]
					execute_enemy_attack(enemy_id)
				
				EnemyState.ATTACKING:
					# Attack finished - enter cooldown
					enemy["state"] = EnemyState.COOLDOWN
					enemy["state_timer"] = enemy["cooldown_duration"]
					clear_enemy_warning(enemy_id)
					print("Enemy ", enemy["name"], " enters cooldown")
				
				EnemyState.COOLDOWN:
					# Cooldown finished - return to idle
					enemy["state"] = EnemyState.IDLE
					enemy["state_timer"] = 0.0
					print("Enemy ", enemy["name"], " ready for action")

func execute_enemy_attack(enemy_id: String):
	if not actors.has(enemy_id):
		return
	
	var enemy = actors[enemy_id]
	print("Enemy ", enemy["name"], " executes ", enemy["attack_pattern"], " attack!")
	
	# Clear warning effects and show attack effects
	clear_enemy_warning(enemy_id)
	
	# Execute the actual attack
	enemy_attack_player(enemy_id)

func advance_beat():
	current_beat += 1
	print("=== BEAT ", current_beat, " ===")
	
	# Process all actor intents
	process_actor_intents()
	
	# Check win/loss conditions
	check_combat_end()

func process_actor_intents():
	# For now, just print what each actor would do
	for actor_id in actors.keys():
		var actor = actors[actor_id]
		print("Actor ", actor["name"], " at (", actor["position"].x, ",", actor["position"].y, ") - HP: ", actor["hp"])
		
		if actor["type"] == "enemy":
			# Simple AI: move toward player or attack if adjacent
			process_enemy_intent(actor_id)

func process_enemy_intent(enemy_id: String):
	var enemy = actors[enemy_id]
	var enemy_pos = enemy["position"]
	
	# Find player position
	if not actors.has(player_actor_id):
		return
	
	var player_pos = actors[player_actor_id]["position"]
	
	# State machine logic
	match enemy["state"]:
		EnemyState.IDLE:
			# Check if enemy can attack player
			if can_enemy_attack_player(enemy_id):
				# Start preparing to attack
				enemy["state"] = EnemyState.PREPARING_ATTACK
				enemy["state_timer"] = enemy["prepare_duration"]
				start_enemy_prepare_attack(enemy_id)
				print("Enemy ", enemy["name"], " starts preparing attack!")
			else:
				# Try to move to attack position
				enemy_try_move_to_attack_position(enemy_id)
		
		EnemyState.MOVING:
			# Movement is handled elsewhere, just check if we can attack
			if can_enemy_attack_player(enemy_id):
				enemy["state"] = EnemyState.PREPARING_ATTACK
				enemy["state_timer"] = enemy["prepare_duration"]
				start_enemy_prepare_attack(enemy_id)
				print("Enemy ", enemy["name"], " stops moving and prepares attack!")
			else:
				enemy["state"] = EnemyState.IDLE
		
		EnemyState.PREPARING_ATTACK:
			# Preparation is handled in _process with timer
			# This state just ensures enemy doesn't do anything else
			pass
		
		EnemyState.ATTACKING:
			# Attack is handled in _process with timer
			pass
		
		EnemyState.COOLDOWN:
			# Cooldown is handled in _process with timer
			pass

func enemy_try_move_to_attack_position(enemy_id: String):
	var enemy = actors[enemy_id]
	var enemy_pos = enemy["position"]
	var player_pos = actors[player_actor_id]["position"]
	
	# Try to move to a better position (only lane switching, stay in back rows)
	var move_options = []
	
	# Check left/right lane movement (stay in same row)
	var side_cells = [
		Vector2i(enemy_pos.x - 1, enemy_pos.y),  # Left lane
		Vector2i(enemy_pos.x + 1, enemy_pos.y)   # Right lane
	]
	
	for cell in side_cells:
		if is_valid_cell(cell.x, cell.y) and not is_cell_occupied(cell.x, cell.y):
			# Check if this position would allow attacking the player
			if would_enemy_attack_from_position(enemy_id, cell):
				move_options.append({"cell": cell, "priority": 10})  # High priority for attack positions
			else:
				move_options.append({"cell": cell, "priority": 1})   # Low priority for other moves
	
	# Move to best available option
	if move_options.size() > 0:
		move_options.sort_custom(func(a, b): return a["priority"] > b["priority"])
		var best_move = move_options[0]["cell"]
		if move_actor(enemy_id, best_move.x, best_move.y):
			enemy["state"] = EnemyState.MOVING
			print("Enemy ", enemy["name"], " moved to lane ", best_move.x)

func start_enemy_prepare_attack(enemy_id: String):
	if not actors.has(enemy_id):
		return
	
	var enemy = actors[enemy_id]
	print("Enemy ", enemy["name"], " preparing ", enemy["attack_pattern"], " attack for ", enemy["prepare_duration"], " seconds!")
	
	# Start all warning effects
	start_enemy_blink(enemy_id)
	show_attack_pattern_preview(enemy_id)
	create_warning_icon(enemy_id)

func show_enemy_attack_warning(enemy_id: String):
	if not actors.has(enemy_id):
		return
	
	var enemy = actors[enemy_id]
	var enemy_sprite = enemy.get("sprite")
	
	if not enemy_sprite:
		return
	
	# Start blinking effect
	start_enemy_blink(enemy_id)
	
	# Show attack pattern preview (dimmed)
	show_attack_pattern_preview(enemy_id)
	
	# Add warning icon above enemy
	create_warning_icon(enemy_id)

func start_enemy_blink(enemy_id: String):
	if not actors.has(enemy_id):
		return
	
	var enemy = actors[enemy_id]
	var enemy_sprite = enemy.get("sprite")
	
	if not enemy_sprite:
		return
	
	# Stop any existing blink tween first
	if enemy.has("blink_tween") and enemy["blink_tween"]:
		enemy["blink_tween"].kill()
	
	# Create finite blinking tween (not infinite loop)
	var blink_tween = create_tween()
	
	# Blink 3 times over 0.5 seconds (matches warning duration)
	for i in range(3):
		blink_tween.tween_property(enemy_sprite, "modulate", Color.RED, 0.08)
		blink_tween.tween_property(enemy_sprite, "modulate", Color.WHITE, 0.08)
	
	# Store the tween so we can stop it later
	enemy["blink_tween"] = blink_tween

func clear_enemy_warning(enemy_id: String):
	if not actors.has(enemy_id):
		return
	
	var enemy = actors[enemy_id]
	
	# Stop blinking
	if enemy.has("blink_tween") and enemy["blink_tween"]:
		enemy["blink_tween"].kill()
		enemy.erase("blink_tween")
	
	# Reset sprite color
	var enemy_sprite = enemy.get("sprite")
	if enemy_sprite:
		enemy_sprite.modulate = Color.WHITE
	
	# Remove warning icon
	if enemy.has("warning_icon") and enemy["warning_icon"]:
		enemy["warning_icon"].queue_free()
		enemy.erase("warning_icon")
	
	# Clear attack pattern preview
	clear_attack_pattern_preview(enemy_id)

func create_warning_icon(enemy_id: String):
	if not actors.has(enemy_id):
		return
	
	var enemy = actors[enemy_id]
	var enemy_sprite = enemy.get("sprite")
	
	if not enemy_sprite:
		return
	
	# Remove existing warning icon first to prevent duplication
	if enemy.has("warning_icon") and enemy["warning_icon"]:
		enemy["warning_icon"].queue_free()
	
	# Create warning exclamation mark
	var warning_icon = Sprite2D.new()
	warning_icon.name = "WarningIcon_" + enemy_id
	
	# Create warning texture (red exclamation mark)
	var warning_texture = ImageTexture.new()
	var warning_image = Image.create(20, 30, false, Image.FORMAT_RGB8)
	warning_image.fill(Color.TRANSPARENT)
	
	# Draw a simple exclamation mark (red rectangle + dot)
	for y in range(5, 20):  # Vertical line
		for x in range(8, 12):
			warning_image.set_pixel(x, y, Color.RED)
	
	for y in range(22, 26):  # Dot
		for x in range(8, 12):
			warning_image.set_pixel(x, y, Color.RED)
	
	warning_texture.set_image(warning_image)
	warning_icon.texture = warning_texture
	warning_icon.position = Vector2(0, -50)  # Above the enemy
	warning_icon.z_index = 15  # Above everything
	
	enemy_sprite.add_child(warning_icon)
	enemy["warning_icon"] = warning_icon
	
	# Make the warning icon pulse for 0.5 seconds (finite, not infinite)
	var pulse_tween = create_tween()
	# Pulse 2 times over 0.5 seconds
	for i in range(2):
		pulse_tween.tween_property(warning_icon, "scale", Vector2(1.5, 1.5), 0.125)
		pulse_tween.tween_property(warning_icon, "scale", Vector2(1.0, 1.0), 0.125)

func show_attack_pattern_preview(enemy_id: String):
	if not actors.has(enemy_id):
		return
	
	var enemy = actors[enemy_id]
	var enemy_pos = enemy["position"]
	
	# Create visual indicators for attack pattern (dimmed preview)
	var attack_cells = []
	
	match enemy["attack_pattern"]:
		"single_target":
			# Attack straight forward in same lane
			for row in range(enemy_pos.y):
				attack_cells.append(Vector2i(enemy_pos.x, row))
		
		"column_attack":
			# Attack entire column
			for row in range(GRID_ROWS):
				if row != enemy_pos.y:  # Don't highlight enemy's own position
					attack_cells.append(Vector2i(enemy_pos.x, row))
		
		"row_attack":
			# Attack entire row
			for col in range(GRID_COLS):
				if col != enemy_pos.x:  # Don't highlight enemy's own position
					attack_cells.append(Vector2i(col, enemy_pos.y))
		
		"diagonal_attack":
			# Attack diagonal cells
			var diagonals = [
				Vector2i(enemy_pos.x - 1, enemy_pos.y - 1),
				Vector2i(enemy_pos.x + 1, enemy_pos.y - 1),
				Vector2i(enemy_pos.x - 1, enemy_pos.y + 1),
				Vector2i(enemy_pos.x + 1, enemy_pos.y + 1)
			]
			for cell in diagonals:
				if is_valid_cell(cell.x, cell.y):
					attack_cells.append(cell)
	
	# Create temporary preview indicators (dimmed)
	var preview_indicators = []
	for cell in attack_cells:
		var indicator = create_preview_indicator(cell)
		preview_indicators.append(indicator)
	
	# Store preview indicators so we can clear them
	enemy["preview_indicators"] = preview_indicators

func create_preview_indicator(cell_pos: Vector2i) -> Sprite2D:
	var indicator = Sprite2D.new()
	indicator.name = "PreviewIndicator_" + str(cell_pos.x) + "_" + str(cell_pos.y)
	
	# Create dimmed orange warning indicator
	var indicator_texture = ImageTexture.new()
	var indicator_image = Image.create(60, 60, false, Image.FORMAT_RGB8)
	indicator_image.fill(Color(1.0, 0.5, 0.0, 0.3))  # Semi-transparent orange
	indicator_texture.set_image(indicator_image)
	indicator.texture = indicator_texture
	indicator.position = get_row_world_position(cell_pos.x, cell_pos.y)
	indicator.z_index = 4  # Below actors but above background
	
	add_child(indicator)
	return indicator

func clear_attack_pattern_preview(enemy_id: String):
	if not actors.has(enemy_id):
		return
	
	var enemy = actors[enemy_id]
	
	# Clear preview indicators
	if enemy.has("preview_indicators"):
		for indicator in enemy["preview_indicators"]:
			if indicator:
				indicator.queue_free()
		enemy.erase("preview_indicators")

func attack_actor(attacker_id: String, target_id: String, damage_override: int = -1):
	if not actors.has(attacker_id) or not actors.has(target_id):
		return
	
	var attacker = actors[attacker_id]
	var target = actors[target_id]
	
	var damage = damage_override if damage_override > 0 else attacker["power"]
	target["hp"] -= damage
	
	print("Attack: ", attacker["name"], " deals ", damage, " damage to ", target["name"])
	print("Target HP: ", target["hp"], "/", target["max_hp"])
	
	# Update HP bar
	update_hp_bar(target_id)
	
	if target["hp"] <= 0:
		print("Actor ", target["name"], " defeated!")
		remove_actor(target_id)

func can_enemy_attack_player(enemy_id: String) -> bool:
	if not actors.has(enemy_id) or not actors.has(player_actor_id):
		return false
	
	var enemy = actors[enemy_id]
	var enemy_pos = enemy["position"]
	var player_pos = actors[player_actor_id]["position"]
	
	match enemy["attack_pattern"]:
		"single_target":
			# Can attack if player is directly in front (same lane, any row in front)
			return enemy_pos.x == player_pos.x and player_pos.y < enemy_pos.y
		
		"column_attack":
			# Can attack entire column (same lane, all rows)
			return enemy_pos.x == player_pos.x
		
		"row_attack":
			# Can attack entire row (same row, all lanes)
			return enemy_pos.y == player_pos.y
		
		"diagonal_attack":
			# Can attack diagonally adjacent cells
			var dx = abs(enemy_pos.x - player_pos.x)
			var dy = abs(enemy_pos.y - player_pos.y)
			return dx == 1 and dy == 1
		
		_:
			return false

func would_enemy_attack_from_position(enemy_id: String, test_pos: Vector2i) -> bool:
	if not actors.has(enemy_id) or not actors.has(player_actor_id):
		return false
	
	var enemy = actors[enemy_id]
	var player_pos = actors[player_actor_id]["position"]
	
	match enemy["attack_pattern"]:
		"single_target":
			return test_pos.x == player_pos.x and player_pos.y < test_pos.y
		"column_attack":
			return test_pos.x == player_pos.x
		"row_attack":
			return test_pos.y == player_pos.y
		"diagonal_attack":
			var dx = abs(test_pos.x - player_pos.x)
			var dy = abs(test_pos.y - player_pos.y)
			return dx == 1 and dy == 1
		_:
			return false

func enemy_attack_player(enemy_id: String):
	if not actors.has(enemy_id) or not actors.has(player_actor_id):
		return
	
	var enemy = actors[enemy_id]
	
	# Show attack pattern visually
	show_attack_pattern(enemy_id)
	
	# Deal damage to the actual player node
	var existing_player = get_tree().get_first_node_in_group("player")
	if existing_player and existing_player.has_method("take_damage"):
		var damage = enemy["power"]
		existing_player.take_damage(damage)
		print("Enemy ", enemy["name"], " deals ", damage, " damage to player!")
		
		# Check if player died
		if existing_player.current_health <= 0:
			print("Player defeated in combat!")
			remove_actor(player_actor_id)

func show_attack_pattern(enemy_id: String):
	if not actors.has(enemy_id):
		return
	
	var enemy = actors[enemy_id]
	var enemy_pos = enemy["position"]
	
	# Create visual indicators for attack pattern
	var attack_cells = []
	
	match enemy["attack_pattern"]:
		"single_target":
			# Attack straight forward in same lane
			for row in range(enemy_pos.y):
				attack_cells.append(Vector2i(enemy_pos.x, row))
		
		"column_attack":
			# Attack entire column
			for row in range(GRID_ROWS):
				if row != enemy_pos.y:  # Don't highlight enemy's own position
					attack_cells.append(Vector2i(enemy_pos.x, row))
		
		"row_attack":
			# Attack entire row
			for col in range(GRID_COLS):
				if col != enemy_pos.x:  # Don't highlight enemy's own position
					attack_cells.append(Vector2i(col, enemy_pos.y))
		
		"diagonal_attack":
			# Attack diagonal cells
			var diagonals = [
				Vector2i(enemy_pos.x - 1, enemy_pos.y - 1),
				Vector2i(enemy_pos.x + 1, enemy_pos.y - 1),
				Vector2i(enemy_pos.x - 1, enemy_pos.y + 1),
				Vector2i(enemy_pos.x + 1, enemy_pos.y + 1)
			]
			for cell in diagonals:
				if is_valid_cell(cell.x, cell.y):
					attack_cells.append(cell)
	
	# Create temporary attack indicators
	for cell in attack_cells:
		create_attack_indicator(cell)

func create_attack_indicator(cell_pos: Vector2i):
	var indicator = Sprite2D.new()
	indicator.name = "AttackIndicator_" + str(cell_pos.x) + "_" + str(cell_pos.y)
	
	# Create red warning indicator
	var indicator_texture = ImageTexture.new()
	var indicator_image = Image.create(60, 60, false, Image.FORMAT_RGB8)
	indicator_image.fill(Color(1.0, 0.0, 0.0, 0.5))  # Semi-transparent red
	indicator_texture.set_image(indicator_image)
	indicator.texture = indicator_texture
	indicator.position = get_row_world_position(cell_pos.x, cell_pos.y)
	indicator.z_index = 5  # Above other elements but below actors
	
	add_child(indicator)
	
	# Remove indicator after a short time
	var timer = Timer.new()
	timer.wait_time = 1.0
	timer.one_shot = true
	timer.timeout.connect(func(): 
		if indicator:
			indicator.queue_free()
		timer.queue_free()
	)
	add_child(timer)
	timer.start()

func check_combat_end():
	# Check if player is dead
	if not actors.has(player_actor_id):
		print("Player defeated! Game Over!")
		get_tree().call_group("game_manager", "combat_lost")
		end_combat()
		return
	
	# Check if all enemies are dead
	var enemies_alive = 0
	for actor_id in actors.keys():
		if actors[actor_id]["type"] == "enemy":
			enemies_alive += 1
	
	if enemies_alive == 0:
		print("All enemies defeated! Victory!")
		get_tree().call_group("game_manager", "combat_won")
		end_combat()
		return
	
	# Combat continues
	print("Combat continues - ", enemies_alive, " enemies remaining")

# Input handling for combat
func handle_combat_input():
	if not combat_active or not actors.has(player_actor_id):
		return
	
	var player_pos = actors[player_actor_id]["position"]
	
	# Movement with A/D (left/right), W/S (forward/back)
	if Input.is_action_just_pressed("move_left"):
		move_actor(player_actor_id, player_pos.x - 1, player_pos.y)
	elif Input.is_action_just_pressed("move_right"):
		move_actor(player_actor_id, player_pos.x + 1, player_pos.y)
	elif Input.is_action_just_pressed("move_forward"):  # W - move forward (toward enemies)
		move_actor(player_actor_id, player_pos.x, player_pos.y + 1)
	elif Input.is_action_just_pressed("move_backward"):  # S - move backward (away from enemies)
		move_actor(player_actor_id, player_pos.x, player_pos.y - 1)
	elif Input.is_action_just_pressed("attack"):  # E - attack adjacent enemies
		player_attack()

# Player attack system with close-range and long-range options
func player_attack():
	if not actors.has(player_actor_id):
		return
	
	var player_pos = actors[player_actor_id]["position"]
	
	# For now, let's implement both attack types and let player choose
	# Later we can add weapon switching
	
	# Check for close-range attack (sword) - adjacent cells only
	if Input.is_action_pressed("slide"):  # Hold Shift for close-range
		player_close_attack(player_pos)
	else:
		# Default to long-range attack (magic/bow)
		player_long_attack(player_pos)

func player_close_attack(player_pos: Vector2i):
	print("Player uses close-range attack (sword)!")
	
	var adjacent_cells = [
		Vector2i(player_pos.x - 1, player_pos.y),  # Left
		Vector2i(player_pos.x + 1, player_pos.y),  # Right
		Vector2i(player_pos.x, player_pos.y - 1),  # Backward
		Vector2i(player_pos.x, player_pos.y + 1)   # Forward
	]
	
	var enemies_attacked = []
	
	# Check each adjacent cell for enemies
	for cell in adjacent_cells:
		if is_valid_cell(cell.x, cell.y) and is_cell_occupied(cell.x, cell.y):
			var enemy_id = grid_tiles[cell.x][cell.y]["actor_id"]
			if actors.has(enemy_id) and actors[enemy_id]["type"] == "enemy":
				enemies_attacked.append(enemy_id)
	
	if enemies_attacked.size() > 0:
		# Attack all adjacent enemies with high damage
		for enemy_id in enemies_attacked:
			attack_actor(player_actor_id, enemy_id, 15)  # Higher damage for close range
		print("Sword attack hit ", enemies_attacked.size(), " enemies!")
	else:
		print("No enemies in sword range!")

func player_long_attack(player_pos: Vector2i):
	print("Player uses long-range attack (magic)!")
	
	# Long-range can attack in straight lines (like a cross pattern)
	var target_cells = []
	
	# Attack forward in same lane
	for row in range(player_pos.y + 1, GRID_ROWS):
		target_cells.append(Vector2i(player_pos.x, row))
	
	# Attack left and right in same row
	for col in range(GRID_COLS):
		if col != player_pos.x:
			target_cells.append(Vector2i(col, player_pos.y))
	
	var enemies_attacked = []
	
	# Check target cells for enemies
	for cell in target_cells:
		if is_valid_cell(cell.x, cell.y) and is_cell_occupied(cell.x, cell.y):
			var enemy_id = grid_tiles[cell.x][cell.y]["actor_id"]
			if actors.has(enemy_id) and actors[enemy_id]["type"] == "enemy":
				enemies_attacked.append(enemy_id)
	
	if enemies_attacked.size() > 0:
		# Attack all enemies in range with moderate damage
		for enemy_id in enemies_attacked:
			attack_actor(player_actor_id, enemy_id, 10)  # Moderate damage for long range
		print("Magic attack hit ", enemies_attacked.size(), " enemies!")
		
		# Show magic attack pattern
		show_player_attack_pattern(target_cells)
	else:
		print("No enemies in magic range!")

func show_player_attack_pattern(target_cells: Array):
	# Create temporary blue indicators for player attack
	for cell in target_cells:
		var indicator = Sprite2D.new()
		indicator.name = "PlayerAttackIndicator_" + str(cell.x) + "_" + str(cell.y)
		
		var indicator_texture = ImageTexture.new()
		var indicator_image = Image.create(60, 60, false, Image.FORMAT_RGB8)
		indicator_image.fill(Color(0.0, 0.5, 1.0, 0.7))  # Semi-transparent blue
		indicator_texture.set_image(indicator_image)
		indicator.texture = indicator_texture
		indicator.position = get_row_world_position(cell.x, cell.y)
		indicator.z_index = 6  # Above attack indicators
		
		add_child(indicator)
		
		# Remove indicator after a short time
		var timer = Timer.new()
		timer.wait_time = 0.5
		timer.one_shot = true
		timer.timeout.connect(func(): 
			if indicator:
				indicator.queue_free()
			timer.queue_free()
		)
		add_child(timer)
		timer.start()

func _input(event):
	if combat_active:
		handle_combat_input()
