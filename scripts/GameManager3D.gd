extends Node3D

@onready var enhanced_obstacle_scene = preload("res://EnhancedObstacle3D.tscn")
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

# Input tracking
var _n_key_was_pressed = false

# Game mode
enum GameMode { RUNNER, COMBAT }
var current_mode = GameMode.RUNNER

# Spawning system - CRUNCHY SETTINGS
var obstacle_spawn_timer = 0.0
var base_spawn_interval = 1.8  # Faster spawning for intense action
var current_spawn_interval = base_spawn_interval
var difficulty_timer = 0.0
var distance_traveled = 0.0

# 3D Spawning positions
const SPAWN_DISTANCE = 45.0  # Closer spawn distance for more intense action
const LANE_POSITIONS = [-3.0, 0.0, 3.0]  # X positions for lanes
const ROW_POSITIONS = [-8.0, -5.0, -2.0, 1.0]  # Z positions for rows

# Enemy spawning system - MORE FREQUENT
var enemy_spawn_timer = 0.0
var base_enemy_spawn_interval = 12.0  # More frequent enemy encounters
var min_enemy_spawn_interval = 6.0    # Minimum time between encounters
var enemy_spawn_distance_threshold = 150.0  # Closer distance threshold
var last_enemy_spawn_distance = 0.0

# Combat system
var combat_timer = 0.0
var combat_spawn_interval = 20.0  # Spawn enemy every 20 seconds initially
var combat_grid: CombatGrid
var player_lane_at_encounter = 1  # Track player lane when combat starts

# Streak system
var perfect_dodge_streak = 0
var streak_multiplier = 1.0
var streak_decay_timer = 0.0
const STREAK_DECAY_TIME = 3.0

# Biome system
var current_biome = 0
var biome_distance_thresholds = [0, 500, 1200]  # Distance to change biomes
var biome_names = ["Tutorial Valley", "Mystic City", "Industrial Wasteland"]

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
	
	# Load a random music file from available chiptunes
	var music_files = [
		"res://chiptunes awesomeness.mp3",
		"res://chiptunes awesomeness 2.mp3", 
	]
	
	# Randomly select a music file
	var selected_music = music_files[randi() % music_files.size()]
	print("🎵 Randomly selected music: ", selected_music)
	
	var music_stream = load(selected_music)
	if music_stream:
		background_music_player.stream = music_stream
		background_music_player.volume_db = linear_to_db(music_volume)
		background_music_player.autoplay = false
		
		# In Godot 4, set loop on the stream itself
		if music_stream is AudioStreamMP3:
			music_stream.loop = true
		elif music_stream is AudioStreamOggVorbis:
			music_stream.loop = true
		# For other stream types, they may not support looping
		
		# Add to scene tree
		add_child(background_music_player)
		add_child(sound_effects_player)
		
		# Connect finished signal for manual looping fallback
		background_music_player.finished.connect(_on_music_finished)
		
		# Start playing
		background_music_player.play()
		print("🎵 Background music loaded and playing: ", selected_music.get_file())
		print("🎮 Music controls: M = toggle, +/- = volume, N = next track")
	else:
		print("❌ Warning: Could not load selected music file")
		# Still add sound effects player
		add_child(sound_effects_player)

# Available music files for random selection
var available_music_files = [
	"res://chiptunes awesomeness.mp3",
	"res://chiptunes awesomeness 2.mp3"
]
var current_music_index = 0

func change_music():
	"""Change to a different random music track"""
	if not background_music_player:
		return
	
	# Select a different track (not the current one)
	var new_index = randi() % available_music_files.size()
	while new_index == current_music_index and available_music_files.size() > 1:
		new_index = randi() % available_music_files.size()
	
	current_music_index = new_index
	var selected_music = available_music_files[current_music_index]
	
	print("🎵 Changing music to: ", selected_music.get_file())
	
	var music_stream = load(selected_music)
	if music_stream:
		background_music_player.stop()
		background_music_player.stream = music_stream
		
		# Set loop property
		if music_stream is AudioStreamMP3:
			music_stream.loop = true
		elif music_stream is AudioStreamOggVorbis:
			music_stream.loop = true
		
		background_music_player.play()
		print("🎵 Now playing: ", selected_music.get_file())

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

func _on_music_finished():
	# Manual looping fallback if stream doesn't support native looping
	if background_music_player and game_running:
		background_music_player.play()
		print("Music looped manually")

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

func _process(delta):
	if not game_running:
		return
	
	# Update timers
	obstacle_spawn_timer += delta
	enemy_spawn_timer += delta
	difficulty_timer += delta
	streak_decay_timer += delta
	
	# Update distance traveled (simulated forward movement)
	distance_traveled += 10.0 * delta  # 10 units per second
	
	# Update biome based on distance
	update_biome()
	
	# Increase difficulty over time - FASTER RAMP UP
	if difficulty_timer >= 7.0:  # Every 7 seconds (was 10)
		current_spawn_interval = max(0.6, current_spawn_interval - 0.08)  # Faster decrease, lower minimum
		difficulty_timer = 0.0
		print("CRUNCHY difficulty increased! Spawn interval: ", current_spawn_interval)
	
	# Spawn regular hazards
	if obstacle_spawn_timer >= current_spawn_interval:
		spawn_hazard()
		obstacle_spawn_timer = 0.0
	
	# Spawn enemy encounters
	if enemy_spawn_timer >= base_enemy_spawn_interval and distance_traveled >= enemy_spawn_distance_threshold:
		if distance_traveled - last_enemy_spawn_distance >= enemy_spawn_distance_threshold:
			spawn_enemy_encounter()
			enemy_spawn_timer = 0.0
			last_enemy_spawn_distance = distance_traveled
	
	# Decay streak if no recent perfect dodges
	if streak_decay_timer >= STREAK_DECAY_TIME and perfect_dodge_streak > 0:
		perfect_dodge_streak = max(0, perfect_dodge_streak - 1)
		streak_multiplier = 1.0 + (perfect_dodge_streak * 0.1)
		streak_decay_timer = 0.0
		print("Streak decayed to: ", perfect_dodge_streak)
	
	# Always update UI
	update_ui()
	
	# Handle music controls (work even when game is paused)
	if Input.is_physical_key_pressed(KEY_N) and not _n_key_was_pressed:
		change_music()
		_n_key_was_pressed = true
	elif not Input.is_physical_key_pressed(KEY_N):
		_n_key_was_pressed = false
	
	# Handle restart
	if not game_running and (Input.is_action_just_pressed("move_left") or Input.is_action_just_pressed("move_right")):
		restart_game()

func spawn_hazard():
	var obstacle = enhanced_obstacle_scene.instantiate()
	
	# Choose random lane and row
	var lane = randi() % 3
	var row = randi() % 4
	
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
	
	# Set 3D position based on hazard type
	var y_position = 1.0  # Default position
	
	match hazard_type:
		"ground_spikes":
			y_position = 0.2  # Ground level - spikes stick up from ground
		"overhead_barrier":
			y_position = 2.5  # Head level - player needs to duck
		"coin", "xp", "health_potion":
			y_position = 1.5  # Chest level for pickups
		_:
			y_position = 1.0  # Default
	
	obstacle.position = Vector3(LANE_POSITIONS[lane], y_position, -SPAWN_DISTANCE)
	print("Spawned ", hazard_type, " at Y position: ", y_position)
	
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

func spawn_enemy_encounter():
	# Create enemy marker for combat encounter
	var obstacle = enhanced_obstacle_scene.instantiate()
	
	# Choose random lane for enemy encounter
	var lane = randi() % 3
	var formation_id = choose_enemy_formation()
	
	var hazard_data = HazardData.create_enemy_marker(lane, formation_id)
	
	# Set 3D position
	obstacle.position = Vector3(LANE_POSITIONS[lane], 1.0, -SPAWN_DISTANCE)
	
	obstacle.setup_hazard(hazard_data)
	add_child(obstacle)
	
	print("Spawned enemy encounter: ", formation_id, " in lane ", lane)

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

func update_biome():
	var new_biome = current_biome
	
	for i in range(biome_distance_thresholds.size() - 1, -1, -1):
		if distance_traveled >= biome_distance_thresholds[i]:
			new_biome = i
			break
	
	if new_biome != current_biome:
		current_biome = new_biome
		print("Entered biome ", current_biome, ": ", biome_names[current_biome])
		
		# Adjust enemy spawn rate based on biome
		base_enemy_spawn_interval = max(min_enemy_spawn_interval, 15.0 - (current_biome * 3.0))

func setup_combat_grid():
	# Initialize combat system
	combat_grid = CombatGrid.new()
	combat_grid.name = "CombatGrid"
	add_child(combat_grid)
	
	# Connect combat signals
	combat_grid.connect("combat_ended", _on_combat_ended)
	combat_grid.connect("player_won", _on_player_won_combat)
	combat_grid.connect("player_lost", _on_player_lost_combat)

func start_combat(formation_id: String, encounter_lane: int):
	print("Starting combat with formation: ", formation_id)
	current_mode = GameMode.COMBAT
	player_lane_at_encounter = encounter_lane
	
	# Pause runner mode
	game_running = false
	
	# Start combat (fix parameter order: player_lane first, then formation_id)
	combat_grid.start_combat(player_lane_at_encounter, formation_id)

func _on_combat_ended():
	print("Combat ended, returning to runner mode")
	current_mode = GameMode.RUNNER
	game_running = true

func _on_player_won_combat():
	print("Player won combat!")
	# Award bonus points
	score += 100 * streak_multiplier
	xp += 25

func _on_player_lost_combat():
	print("Player lost combat!")
	# Player takes damage or other penalty
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.take_damage(30.0)

func perfect_dodge():
	perfect_dodge_streak += 1
	streak_multiplier = 1.0 + (perfect_dodge_streak * 0.1)
	streak_decay_timer = 0.0
	
	# Award bonus points
	var bonus_points = 10 * streak_multiplier
	score += bonus_points
	
	print("Perfect dodge! Streak: ", perfect_dodge_streak, " Multiplier: x", "%.1f" % streak_multiplier)

func player_hit(hazard_type: String):
	print("Player hit by: ", hazard_type)
	
	# Reset streak
	perfect_dodge_streak = 0
	streak_multiplier = 1.0
	
	# Award small points for hitting obstacles (they still made progress)
	score += 1

func collect_pickup(pickup_type: String, value: int):
	match pickup_type:
		"coin":
			coins += value
			score += value * streak_multiplier
			print("Collected coin! Total: ", coins)
		"xp":
			xp += value
			score += (value * 2) * streak_multiplier
			print("Collected XP! Total: ", xp)
		"health_potion":
			# Health potion healing is handled in player script
			score += (value * 3) * streak_multiplier
			print("Collected health potion!")

func create_floating_text(text: String, position: Vector3, color: Color = Color.WHITE):
	# Create floating damage/score text
	var label = Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	label.position = Vector2(position.x, position.y)  # Convert 3D to screen space
	ui.add_child(label)
	
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
	if current_mode == GameMode.COMBAT:
		instructions_label.text = "COMBAT MODE - Use tactical grid controls"
	else:
		instructions_label.text = "A/D or ←→: Switch lanes\nW or ↑: Jump (avoid ground hazards)\nS or ↓: Slide (avoid overhead hazards)\n\nPerfect dodges build streak multiplier!\n\nM: Toggle music | +/-: Volume"

func _on_player_died():
	print("Game Over! Final Score: ", score)
	game_running = false
	game_over_label.visible = true
	restart_label.visible = true

func restart_game():
	print("Restarting game...")
	
	# Reset game state
	score = 0
	coins = 0
	xp = 0
	distance_traveled = 0.0
	current_biome = 0
	perfect_dodge_streak = 0
	streak_multiplier = 1.0
	current_spawn_interval = base_spawn_interval
	
	# Reset timers
	obstacle_spawn_timer = 0.0
	enemy_spawn_timer = 0.0
	difficulty_timer = 0.0
	streak_decay_timer = 0.0
	last_enemy_spawn_distance = 0.0
	
	# Reset player
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.reset_position()
	
	# Clean up obstacles
	cleanup_all_obstacles()
	
	# Reset UI
	game_running = true
	current_mode = GameMode.RUNNER
	game_over_label.visible = false
	restart_label.visible = false
	
	update_ui()

func cleanup_all_obstacles():
	# Remove all obstacles from the scene
	var obstacles = get_tree().get_nodes_in_group("obstacles")
	for obstacle in obstacles:
		if is_instance_valid(obstacle):
			obstacle.queue_free()
	
	print("Cleaned up ", obstacles.size(), " obstacles")
