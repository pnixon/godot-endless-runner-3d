extends Node

@onready var enhanced_obstacle_scene = preload("res://EnhancedObstacle.tscn")
@onready var player = $Player
@onready var ui = $UI
@onready var score_label = $UI/ScoreLabel
@onready var streak_label = $UI/StreakLabel
@onready var coins_label = $UI/CoinsLabel
@onready var xp_label = $UI/XPLabel
@onready var game_over_label = $UI/GameOverLabel
@onready var restart_label = $UI/RestartLabel
@onready var instructions_label = $UI/InstructionsLabel

# Audio system
var background_music_player: AudioStreamPlayer
var sound_effects_player: AudioStreamPlayer
var music_volume = 0.5  # Adjust volume (0.0 to 1.0)
var sfx_volume = 0.7

# Game state
var score = 0
var coins = 0
var xp = 0
var game_running = true

# Game mode
enum GameMode { RUNNER, COMBAT }
var current_mode = GameMode.RUNNER

# Spawning system
var obstacle_spawn_timer = 0.0
var base_spawn_interval = 1.8
var current_spawn_interval = base_spawn_interval
var difficulty_timer = 0.0
var distance_traveled = 0.0

# Enemy spawning system
var enemy_spawn_timer = 0.0
var base_enemy_spawn_interval = 12.0  # Base time between enemy encounters (seconds)
var min_enemy_spawn_interval = 6.0    # Minimum time between encounters
var enemy_spawn_distance_threshold = 150.0  # Minimum distance before first enemy
var last_enemy_spawn_distance = 0.0

# Combat system
var combat_timer = 0.0
var combat_spawn_interval = 15.0  # Spawn enemy every 15 seconds initially
var combat_grid: CombatGrid
var player_lane_at_encounter = 1  # Track player lane when combat starts

# Streak system
var perfect_dodge_streak = 0
var streak_multiplier = 1.0
var streak_decay_timer = 0.0
const STREAK_DECAY_TIME = 3.0

# Biome system
var current_biome = 0
var biome_distance = 0.0
const BIOME_LENGTH = 500.0  # Distance before switching biomes

# Hazard spawn weights by biome - regular obstacles and pickups only
var biome_hazard_weights = [
	# Biome 0: Tutorial - balanced hazards with more pickups and health potions
	{"ground_spikes": 0.4, "overhead_barrier": 0.3, "coin": 0.15, "xp": 0.05, "health_potion": 0.1},
	# Biome 1: City - more challenging hazards, fewer health potions
	{"ground_spikes": 0.4, "overhead_barrier": 0.35, "coin": 0.15, "xp": 0.05, "health_potion": 0.05},
	# Biome 2: Industrial - hardest hazards, rare health potions
	{"ground_spikes": 0.5, "overhead_barrier": 0.37, "coin": 0.08, "xp": 0.02, "health_potion": 0.03}
]

func _ready():
	add_to_group("game_manager")
	game_over_label.visible = false
	restart_label.visible = false
	
	# Initialize combat grid
	setup_combat_grid()
	
	# Set up background music
	setup_background_music()
	
	# Connect to player signals
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.connect("player_died", _on_player_died)
		print("Connected to player death signal")
	else:
		print("Warning: Player not found for signal connections")
	
	update_ui()

func setup_background_music():
	# Create AudioStreamPlayer for background music
	background_music_player = AudioStreamPlayer.new()
	background_music_player.name = "BackgroundMusicPlayer"
	
	# Create AudioStreamPlayer for sound effects
	sound_effects_player = AudioStreamPlayer.new()
	sound_effects_player.name = "SoundEffectsPlayer"
	sound_effects_player.volume_db = linear_to_db(sfx_volume)
	
	# Load the music file
	var music_stream = load("res://background_music.mp3")
	if music_stream:
		background_music_player.stream = music_stream
		background_music_player.volume_db = linear_to_db(music_volume)
		background_music_player.autoplay = false
		background_music_player.loop = true  # Loop the music
		
		# Add to scene tree
		add_child(background_music_player)
		add_child(sound_effects_player)
		
		# Start playing
		background_music_player.play()
		print("Background music loaded and playing: background_music.mp3")
		print("Music controls: M = toggle, +/- = volume")
	else:
		print("Warning: Could not load background_music.mp3")
		# Still add sound effects player
		add_child(sound_effects_player)

func set_music_volume(volume: float):
	# Set music volume (0.0 to 1.0)
	music_volume = clamp(volume, 0.0, 1.0)
	if background_music_player:
		background_music_player.volume_db = linear_to_db(music_volume)

func toggle_music():
	# Toggle music on/off
	if background_music_player:
		if background_music_player.playing:
			background_music_player.stop()
			print("Music stopped")
		else:
			background_music_player.play()
			print("Music started")

func play_sound_effect(frequency: float, duration: float = 0.1):
	# Generate a simple tone for sound effects
	if not sound_effects_player:
		return
	
	# Create a simple sine wave tone
	var sample_rate = 44100
	var samples = int(sample_rate * duration)
	var audio_stream = AudioStreamGenerator.new()
	audio_stream.mix_rate = sample_rate
	audio_stream.buffer_length = duration
	
	# Note: This is a simplified approach. For better sound effects,
	# you'd want to load actual audio files or use more sophisticated generation
	print("Playing sound effect at ", frequency, "Hz")

func play_pickup_sound():
	# High pitched sound for pickups
	play_sound_effect(800.0, 0.15)

func play_damage_sound():
	# Low pitched sound for damage
	play_sound_effect(200.0, 0.3)

func play_heal_sound():
	# Pleasant sound for healing
	play_sound_effect(600.0, 0.2)

func _on_player_died():
	print("Player died - Game Over!")
	game_over()

func setup_combat_grid():
	# Create and add combat grid to the scene
	combat_grid = preload("res://CombatGrid.gd").new()
	combat_grid.name = "CombatGrid"
	add_child(combat_grid)
	print("Combat grid initialized")

func _process(delta):
	if game_running and current_mode == GameMode.RUNNER:
		# Update score and distance
		var distance_delta = 200 * delta  # Base speed
		score += distance_delta * streak_multiplier
		distance_traveled += distance_delta
		biome_distance += distance_delta
		
		# Check for biome transition
		if biome_distance >= BIOME_LENGTH:
			advance_biome()
		
		# Update difficulty over time
		difficulty_timer += delta
		current_spawn_interval = max(0.8, base_spawn_interval - (difficulty_timer * 0.02))
		
		# Update combat spawn rate
		combat_timer += delta
		combat_spawn_interval = max(8.0, 15.0 - (difficulty_timer * 0.1))
		
		# Spawn hazards
		obstacle_spawn_timer += delta
		if obstacle_spawn_timer >= current_spawn_interval:
			spawn_hazard()
			obstacle_spawn_timer = 0.0
		
		# Spawn enemies at regular intervals
		enemy_spawn_timer += delta
		var current_enemy_interval = max(min_enemy_spawn_interval, base_enemy_spawn_interval - (difficulty_timer * 0.05))
		
		# Check if enough time has passed AND enough distance traveled since last enemy
		if enemy_spawn_timer >= current_enemy_interval and distance_traveled >= enemy_spawn_distance_threshold and (distance_traveled - last_enemy_spawn_distance) >= 100.0:
			spawn_enemy_encounter()
			enemy_spawn_timer = 0.0
			last_enemy_spawn_distance = distance_traveled
		
		# Handle streak decay
		if perfect_dodge_streak > 0:
			streak_decay_timer += delta
			if streak_decay_timer >= STREAK_DECAY_TIME:
				perfect_dodge_streak = max(0, perfect_dodge_streak - 1)
				update_streak_multiplier()
				streak_decay_timer = 0.0
	
	# Always update UI
	update_ui()
	
	# Handle restart
	if not game_running and (Input.is_action_just_pressed("move_left") or Input.is_action_just_pressed("move_right")):
		restart_game()

func spawn_hazard():
	var obstacle = enhanced_obstacle_scene.instantiate()
	
	# Choose random lane
	var lane = randi() % 3
	
	# Choose hazard type based on current biome (no more enemy markers)
	var hazard_type = choose_hazard_type()
	var hazard_data
	
	match hazard_type:
		"ground_spikes":
			hazard_data = HazardData.create_ground_spikes(lane)
		"overhead_barrier":
			hazard_data = HazardData.create_overhead_barrier(lane)
		"coin":
			hazard_data = HazardData.create_coin_pickup(lane)
		"xp":
			hazard_data = HazardData.create_xp_pickup(lane)
		"health_potion":
			hazard_data = HazardData.create_health_potion(lane)
		_:
			# Fallback to ground spikes
			hazard_data = HazardData.create_ground_spikes(lane)
	
	obstacle.setup_hazard(hazard_data)
	add_child(obstacle)

func choose_hazard_type() -> String:
	var weights = biome_hazard_weights[min(current_biome, biome_hazard_weights.size() - 1)]
	var total_weight = 0.0
	
	for weight in weights.values():
		total_weight += weight
	
	var random_value = randf() * total_weight
	var current_weight = 0.0
	
	for hazard_type in weights.keys():
		current_weight += weights[hazard_type]
		if random_value <= current_weight:
			return hazard_type
	
	return "ground_spikes"  # Fallback

func choose_enemy_formation() -> String:
	# Choose enemy formation based on biome and difficulty
	var formations = []
	
	match current_biome:
		0:  # Tutorial biome - simple enemies
			formations = ["single_goblin", "weak_slime"]
		1:  # City biome - moderate enemies
			formations = ["city_guard", "street_thug", "dual_bandits"]
		2:  # Industrial biome - harder enemies
			formations = ["factory_bot", "steam_golem", "gear_squad"]
		_:  # Fallback
			formations = ["single_goblin"]
	
	return formations[randi() % formations.size()]

func advance_biome():
	current_biome += 1
	biome_distance = 0.0
	
	# Update background for new biome
	get_tree().call_group("background", "change_biome", current_biome)
	
	print("Advanced to biome: ", current_biome)

func perfect_dodge():
	perfect_dodge_streak += 1
	streak_decay_timer = 0.0
	update_streak_multiplier()
	
	# Visual feedback
	show_feedback_text("PERFECT!", Color.GREEN)

func update_streak_multiplier():
	streak_multiplier = 1.0 + (perfect_dodge_streak * 0.1)

func player_hit(hazard_type: String):
	perfect_dodge_streak = 0
	streak_multiplier = 1.0
	
	print("Player hit by: ", hazard_type, " - streak reset but player survives!")
	
	# Show feedback that streak was lost
	show_feedback_text("STREAK LOST!", Color.RED)

func spawn_enemy_encounter():
	print("=== ENEMY ENCOUNTER TRIGGERED ===")
	print("Distance: ", distance_traveled, " | Time since last: ", enemy_spawn_timer)
	
	# Get player's current lane
	var player = get_tree().get_first_node_in_group("player")
	var player_lane = 1  # Default to center
	if player and player.has_method("get_current_lane"):
		player_lane = player.get_current_lane()
	
	# Choose formation based on current biome and difficulty
	var formation_id = choose_enemy_formation()
	
	print("Starting combat with formation: ", formation_id, " in player lane: ", player_lane)
	
	# Start combat encounter
	start_combat(formation_id, player_lane)

func collect_pickup(pickup_type: String, value: int):
	match pickup_type:
		"coin":
			coins += value
			show_feedback_text("+" + str(value) + " COINS", Color.YELLOW)
		"xp":
			xp += value
			show_feedback_text("+" + str(value) + " XP", Color.CYAN)

func start_combat(formation_id: String, player_lane: int):
	print("=== STARTING COMBAT ===")
	print("Formation: ", formation_id, " Player lane: ", player_lane)
	
	# Store player lane for combat positioning
	player_lane_at_encounter = player_lane
	
	# Transition to combat mode
	current_mode = GameMode.COMBAT
	
	# Pause runner elements
	if player:
		player.set_process(false)  # Pause player runner movement
	
	# Start combat grid
	if combat_grid:
		combat_grid.start_combat(player_lane_at_encounter, formation_id)
	
	print("Combat mode activated")

func combat_won():
	print("=== COMBAT VICTORY ===")
	
	# Award victory bonus
	var victory_bonus = 50 + (current_biome * 25)
	xp += victory_bonus
	show_feedback_text("VICTORY! +" + str(victory_bonus) + " XP", Color.GOLD)
	
	# Return to runner mode
	end_combat()

func combat_lost():
	print("=== COMBAT DEFEAT ===")
	
	# Combat defeat should be handled by the combat system dealing damage to player
	# The player will die naturally when health reaches 0
	# Just end combat and return to runner mode
	end_combat()
	
	print("Combat lost - returning to runner mode")

func end_combat():
	print("=== RETURNING TO RUNNER ===")
	
	# Change game mode back
	current_mode = GameMode.RUNNER
	
	# Resume runner elements
	if player:
		player.set_process(true)  # Resume player runner movement
	
	# End combat grid
	if combat_grid:
		combat_grid.end_combat()
	
	print("Runner mode resumed")

func show_feedback_text(text: String, color: Color):
	# Create floating text effect
	var label = Label.new()
	label.text = text
	label.modulate = color
	label.position = Vector2(player.position.x - 30, player.position.y - 60)
	add_child(label)
	
	# Animate the text
	var tween = create_tween()
	tween.parallel().tween_property(label, "position:y", label.position.y - 50, 1.0)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 1.0)
	tween.tween_callback(label.queue_free)

func update_ui():
	score_label.text = "Score: " + str(int(score))
	coins_label.text = "Coins: " + str(coins)
	xp_label.text = "XP: " + str(xp)
	
	if perfect_dodge_streak > 0:
		streak_label.text = "Streak: " + str(perfect_dodge_streak) + " (x" + str("%.1f" % streak_multiplier) + ")"
		streak_label.modulate = Color.GREEN
	else:
		streak_label.text = "Streak: 0"
		streak_label.modulate = Color.WHITE
	
	# Add mode indicator
	if instructions_label:
		var mode_text = "RUNNER" if current_mode == GameMode.RUNNER else "COMBAT"
		var controls = "A/D: Lanes | W/S: Rows | Space: Jump | Shift: Duck"
		if current_mode == GameMode.COMBAT:
			controls += " | E: Magic Attack | Shift+E: Sword Attack"
		instructions_label.text = "Mode: " + mode_text + " | " + controls

func game_over():
	game_running = false
	current_mode = GameMode.RUNNER  # Reset to runner mode
	
	# End any active combat
	if combat_grid:
		combat_grid.end_combat()
	
	game_over_label.visible = true
	restart_label.visible = true

func restart_game():
	# Remove all obstacles and their sprites
	cleanup_all_obstacles()
	
	# Reset game state
	score = 0
	coins = 0
	xp = 0
	perfect_dodge_streak = 0
	streak_multiplier = 1.0
	game_running = true
	current_mode = GameMode.RUNNER
	obstacle_spawn_timer = 0.0
	current_spawn_interval = base_spawn_interval
	difficulty_timer = 0.0
	distance_traveled = 0.0
	current_biome = 0
	biome_distance = 0.0
	combat_timer = 0.0
	player_lane_at_encounter = 1
	
	# Reset combat grid
	if combat_grid:
		combat_grid.end_combat()
	
	# Reset player
	player.reset_position()
	player.set_process(true)  # Ensure player processing is enabled
	
	# Hide game over UI
	game_over_label.visible = false
	restart_label.visible = false
	
	update_ui()

func cleanup_all_obstacles():
	# Clean up all EnhancedObstacle nodes and their associated sprites
	for child in get_children():
		if child.name.begins_with("EnhancedObstacle"):
			# Call cleanup method if it exists
			if child.has_method("cleanup"):
				child.cleanup()
			child.queue_free()
	
	# Also clean up any orphaned hazard sprites
	for child in get_children():
		if child.name.begins_with("HazardSprite_") or child.name == "EnemyAura":
			child.queue_free()

func _exit_tree():
	# Ensure all obstacles are cleaned up when game exits
	cleanup_all_obstacles()
