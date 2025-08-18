extends Node3D

@onready var enhanced_obstacle_scene = preload("res://scenes/EnhancedObstacle3D.tscn")
@onready var player = $Player
@onready var ui = $UI
@onready var score_label = $UI/ScoreLabel
@onready var streak_label = $UI/StreakLabel
@onready var coins_label = $UI/CoinsLabel
@onready var xp_label = $UI/XPLabel
@onready var game_over_label = $UI/GameOverLabel
@onready var restart_label = $UI/RestartLabel
@onready var instructions_label = $UI/InstructionsLabel

# Enemy system
var enemy_spawner: EnemySpawner

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

func _ready():
	add_to_group("game_manager")
	game_over_label.visible = false
	restart_label.visible = false
	
	# Initialize combat grid
	setup_combat_grid()
	
	# Set up enemy spawner
	setup_enemy_spawner()
	
	# Set up background music
	setup_background_music()
	
	# Connect to player signals
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.connect("player_died", _on_player_died)
		print("Connected to player death signal")
	else:
		print("Warning: Player not found for signal connections")
	
	# Set up touch zone indicators for mobile combat
	setup_touch_zone_indicators()
	
	# Add combat feedback test in debug mode
	if OS.is_debug_build():
		var feedback_test = preload("res://test_combat_feedback.gd").new()
		feedback_test.name = "CombatFeedbackTest"
		add_child(feedback_test)
		print("✅ Combat feedback test system added (F1-F8 for tests)")
		
		# Add mobile combat test
		var mobile_combat_test = preload("res://test_mobile_combat.gd").new()
		mobile_combat_test.name = "MobileCombatTest"
		add_child(mobile_combat_test)
		print("✅ Mobile combat test system added (F9-F12 for tests)")
	
	update_ui()

func setup_background_music():
	print("🎵 Setting up background music...")
	
	# Create AudioStreamPlayer for background music
	background_music_player = AudioStreamPlayer.new()
	background_music_player.name = "BackgroundMusicPlayer"
	
	# Create AudioStreamPlayer for sound effects
	sound_effects_player = AudioStreamPlayer.new()
	sound_effects_player.name = "SoundEffectsPlayer"
	sound_effects_player.volume_db = linear_to_db(sfx_volume)
	
	# Load a random music file from available chiptunes
	var music_files = [
		"res://audio/chiptunes awesomeness.mp3",
		"res://audio/chiptunes awesomeness 2.mp3", 
	]
	
	# Randomly select a music file
	var selected_music = music_files[randi() % music_files.size()]
	print("🎵 Randomly selected music: ", selected_music)
	
	var music_stream = load(selected_music)
	if music_stream:
		print("🎵 Music stream loaded successfully")
		background_music_player.stream = music_stream
		background_music_player.volume_db = linear_to_db(music_volume)
		background_music_player.autoplay = false
		
		# In Godot 4, set loop on the stream itself
		if music_stream is AudioStreamMP3:
			music_stream.loop = true
			print("🎵 Set MP3 loop to true")
		elif music_stream is AudioStreamOggVorbis:
			music_stream.loop = true
			print("🎵 Set OGG loop to true")
		# For other stream types, they may not support looping
		
		# Add to scene tree first
		add_child(background_music_player)
		add_child(sound_effects_player)
		print("🎵 Audio players added to scene tree")
		
		# Connect finished signal for manual looping fallback
		background_music_player.finished.connect(_on_music_finished)
		
		# Start playing immediately
		background_music_player.play()
		print("🎵 Background music started playing: ", selected_music.get_file())
		print("🎵 Music volume: ", music_volume, " (", background_music_player.volume_db, " dB)")
		print("🎮 Music controls: M = toggle, +/- = volume, N = next track")
		
		# Verify it's actually playing
		await get_tree().process_frame
		if background_music_player.playing:
			print("✅ Music is confirmed playing!")
		else:
			print("❌ Music failed to start playing")
	else:
		print("❌ Warning: Could not load selected music file: ", selected_music)
		# Still add sound effects player
		add_child(sound_effects_player)

# Available music files for random selection
var available_music_files = [
	"res://audio/chiptunes awesomeness.mp3",
	"res://audio/chiptunes awesomeness 2.mp3"
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
	
	# Handle combat system testing
	handle_combat_testing()
	
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
	
	# Spawn enemy encounters only (removed regular hazards)
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

func spawn_enemy_encounter():
	# Use new enemy spawner system for direct encounters
	if enemy_spawner:
		var formation_id = choose_enemy_formation()
		var spawn_position = Vector3(0, 0, -SPAWN_DISTANCE)
		
		if enemy_spawner.start_encounter(formation_id, spawn_position):
			print("Started enemy encounter: ", formation_id)
		else:
			# Fallback - just spawn a simple obstacle
			var obstacle = enhanced_obstacle_scene.instantiate()
			var lane = randi() % 3
			obstacle.position = Vector3(LANE_POSITIONS[lane], 1.0, -SPAWN_DISTANCE)
			add_child(obstacle)
			print("Spawned simple obstacle as fallback for: ", formation_id)
	else:
		# Fallback - spawn simple obstacle
		var formation_id = choose_enemy_formation()
		var obstacle = enhanced_obstacle_scene.instantiate()
		var lane = randi() % 3
		obstacle.position = Vector3(LANE_POSITIONS[lane], 1.0, -SPAWN_DISTANCE)
		add_child(obstacle)
		print("Spawned simple obstacle for: ", formation_id)

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

func setup_enemy_spawner():
	# Initialize enemy spawner system
	enemy_spawner = EnemySpawner.new()
	enemy_spawner.name = "EnemySpawner"
	add_child(enemy_spawner)
	
	# Connect enemy spawner signals
	enemy_spawner.encounter_started.connect(_on_encounter_started)
	enemy_spawner.encounter_completed.connect(_on_encounter_completed)
	enemy_spawner.enemy_defeated.connect(_on_enemy_defeated)
	
	print("Enemy spawner system initialized")
	print("🗡️ Enemy attack system ready - use number keys 1-9 to test!")

func setup_touch_zone_indicators():
	"""Set up touch zone indicators for mobile combat"""
	# Only create touch zones on mobile platforms or when testing
	if OS.has_feature("mobile") or OS.is_debug_build():
		var touch_zone_indicator = preload("res://scripts/TouchZoneIndicator.gd").new()
		touch_zone_indicator.name = "TouchZoneIndicator"
		
		# Add to UI layer
		var ui_layer = $UI
		if ui_layer:
			ui_layer.add_child(touch_zone_indicator)
			print("✅ Touch zone indicators created for mobile combat")
		else:
			print("❌ Warning: UI layer not found for touch zone indicators")
	else:
		print("Touch zone indicators skipped - not on mobile platform")

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

# Enemy spawner signal handlers

func _on_encounter_started(encounter_type: String):
	"""Handle enemy encounter started"""
	print("GameManager3D: Enemy encounter started - ", encounter_type)
	# Pause runner mode during encounters
	game_running = false
	current_mode = GameMode.COMBAT

func _on_encounter_completed(encounter_type: String, success: bool):
	"""Handle enemy encounter completed"""
	print("GameManager3D: Enemy encounter completed - ", encounter_type, " Success: ", success)
	
	if success:
		# Award bonus points for successful encounter
		score += 200 * streak_multiplier
		xp += 50
		print("Encounter victory bonus awarded!")
	else:
		# Player failed the encounter
		var player = get_tree().get_first_node_in_group("player")
		if player:
			player.take_damage(50.0)
	
	# Resume runner mode
	game_running = true
	current_mode = GameMode.RUNNER

func _on_enemy_defeated(enemy: EnemyAI):
	"""Handle individual enemy defeated"""
	print("GameManager3D: Enemy defeated - ", enemy.get_enemy_type())
	
	# Award points based on enemy type
	var bonus_points = 0
	match enemy.get_enemy_type():
		EnemyAttackSystem.EnemyType.BASIC_MELEE:
			bonus_points = 25
		EnemyAttackSystem.EnemyType.RANGED_ARCHER:
			bonus_points = 30
		EnemyAttackSystem.EnemyType.HEAVY_BRUISER:
			bonus_points = 40
		EnemyAttackSystem.EnemyType.AGILE_ROGUE:
			bonus_points = 35
		EnemyAttackSystem.EnemyType.MAGE_CASTER:
			bonus_points = 45
		EnemyAttackSystem.EnemyType.BOSS_TIER_1:
			bonus_points = 200
		EnemyAttackSystem.EnemyType.BOSS_TIER_2:
			bonus_points = 400
		EnemyAttackSystem.EnemyType.BOSS_FINAL:
			bonus_points = 1000
	
	score += bonus_points * streak_multiplier
	print("Enemy defeat bonus: ", bonus_points, " points")

func perfect_dodge():
	perfect_dodge_streak += 1
	streak_multiplier = 1.0 + (perfect_dodge_streak * 0.1)
	streak_decay_timer = 0.0
	
	# Award bonus points
	var bonus_points = 10 * streak_multiplier
	score += bonus_points
	
	print("Perfect dodge! Streak: ", perfect_dodge_streak, " Multiplier: x", "%.1f" % streak_multiplier)

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
		instructions_label.text = "A/D or ←→: Switch lanes | W/S: Move forward/back\nSpace: Jump/Block | Shift: Slide\n\nCOMBAT SYSTEM TEST:\nEnter: Start combat test | Z/X/N: Dodge left/right/back | Space: Block\n\nENEMY ATTACK SYSTEM TEST:\n1: Single Goblin | 2: City Guard | 3: Balanced Squad | 4: Boss Tier 1\n5: Basic Melee | 6: Ranged Archer | 7: Mage Caster | 8: Boss\n9: Direct Attack Test | 0: Simple Enemy Attack Test\n\nPerfect dodges build streak multiplier!\n\nM: Toggle music | +/-: Volume"

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

func handle_combat_testing():
	"""Handle combat system testing inputs"""
	# Test combat system with number keys
	if Input.is_action_just_pressed("ui_accept"):  # Enter key
		test_combat_scenario()
	
	# Test enemy attack patterns with number keys
	if Input.is_physical_key_pressed(KEY_1):
		test_enemy_encounter("single_goblin")
	elif Input.is_physical_key_pressed(KEY_2):
		test_enemy_encounter("city_guard")
	elif Input.is_physical_key_pressed(KEY_3):
		test_enemy_encounter("balanced_squad")
	elif Input.is_physical_key_pressed(KEY_4):
		test_enemy_encounter("boss_encounter_1")
	elif Input.is_physical_key_pressed(KEY_5):
		test_specific_enemy("basic_melee")
	elif Input.is_physical_key_pressed(KEY_6):
		test_specific_enemy("ranged_archer")
	elif Input.is_physical_key_pressed(KEY_7):
		test_specific_enemy("mage_caster")
	elif Input.is_physical_key_pressed(KEY_8):
		test_specific_enemy("boss_tier1")
	elif Input.is_physical_key_pressed(KEY_9):
		test_direct_attack_registration()
	elif Input.is_physical_key_pressed(KEY_0):
		test_simple_enemy_attack()

func test_combat_scenario():
	"""Test a complete combat scenario"""
	var player = get_tree().get_first_node_in_group("rpg_player")
	if not player:
		print("No RPG player found for combat testing")
		return
	
	print("=== TESTING COMBAT SCENARIO ===")
	
	# Register a test attack that requires a backward dodge
	if player.has_method("register_incoming_attack"):
		player.register_incoming_attack("test_frontal_attack", 2.0, 30.0, "frontal", "backward")
		print("Registered frontal attack - dodge backward in 2 seconds!")
	
	# Wait and register a side attack
	await get_tree().create_timer(3.0).timeout
	if player.has_method("register_incoming_attack"):
		player.register_incoming_attack("test_side_attack", 1.5, 25.0, "side_left", "right")
		print("Registered left side attack - dodge right in 1.5 seconds!")
	
	print("Combat scenario complete. Use Z/X/N to dodge, Space to block.")

func test_enemy_encounter(formation_id: String):
	"""Test a specific enemy encounter formation"""
	if enemy_spawner:
		print("=== TESTING ENEMY ENCOUNTER: ", formation_id, " ===")
		var spawn_position = Vector3(0, 0, -10)  # Closer for testing
		
		if enemy_spawner.start_encounter(formation_id, spawn_position):
			print("Successfully started encounter: ", formation_id)
		else:
			print("Failed to start encounter: ", formation_id)
	else:
		print("Enemy spawner not available for testing")

func test_specific_enemy(enemy_type: String):
	"""Test spawning a specific enemy type"""
	if enemy_spawner:
		print("=== TESTING ENEMY TYPE: ", enemy_type, " ===")
		var spawn_position = Vector3(0, 0, -8)  # Close for testing
		
		var enemy = enemy_spawner.spawn_enemy(enemy_type, spawn_position)
		if enemy:
			print("Successfully spawned enemy: ", enemy_type)
			
			# Test attack pattern after a delay
			await get_tree().create_timer(2.0).timeout
			if enemy.is_alive() and enemy.attack_system:
				# First try to force immediate attack
				enemy.force_immediate_attack()
				
				# Also try specific pattern
				var patterns = enemy.attack_system.get_available_patterns_for_enemy_type(enemy.get_enemy_type())
				if patterns.size() > 0:
					await get_tree().create_timer(1.0).timeout
					enemy.force_attack_pattern(patterns[0])
					print("Forced attack pattern: ", patterns[0])
		else:
			print("Failed to spawn enemy: ", enemy_type)
	else:
		print("Enemy spawner not available for testing")

func test_direct_attack_registration():
	"""Test direct attack registration with combat controller"""
	var player = get_tree().get_first_node_in_group("rpg_player")
	if player:
		var combat_controller = player.get_node_or_null("CombatController")
		if combat_controller:
			print("=== TESTING DIRECT ATTACK REGISTRATION ===")
			combat_controller.register_incoming_attack("test_direct", 2.0, 25.0, "frontal", CombatController.DodgeDirection.BACKWARD)
			print("Registered direct attack - dodge backward in 2 seconds!")
		else:
			print("No CombatController found on player")
	else:
		print("No player found for testing")

func test_simple_enemy_attack():
	"""Test creating a simple enemy and making it attack immediately"""
	print("=== TESTING SIMPLE ENEMY ATTACK ===")
	
	# First verify player has combat system
	var player = get_tree().get_first_node_in_group("rpg_player")
	if not player:
		print("ERROR: No player found!")
		return
	
	if not player.has_method("register_incoming_attack"):
		print("ERROR: Player doesn't have register_incoming_attack method!")
		return
	
	print("Player found with combat system")
	
	# Create a basic melee enemy directly
	var enemy = BasicMeleeEnemy.new()
	enemy.name = "TestEnemy"
	enemy.global_position = Vector3(0, 0, -5)
	
	# Add to scene
	add_child(enemy)
	
	# Wait a moment for initialization
	await get_tree().create_timer(1.0).timeout
	
	# Check if enemy initialized properly
	if not enemy.attack_system:
		print("ERROR: Enemy has no attack system!")
		enemy.queue_free()
		return
	
	print("Enemy attack system found")
	
	# Check if attack system found player
	if not enemy.attack_system.player:
		print("ERROR: Enemy attack system didn't find player!")
		enemy.queue_free()
		return
	
	print("Enemy attack system connected to player")
	
	# Force an immediate attack
	print("Forcing enemy to attack...")
	enemy.force_immediate_attack()
	
	# Clean up after test
	await get_tree().create_timer(5.0).timeout
	if is_instance_valid(enemy):
		enemy.queue_free()

func test_enemy_system_integration():
	"""Test that the enemy attack system can integrate with player combat system"""
	print("=== TESTING ENEMY SYSTEM INTEGRATION ===")
	
	# Check if player exists and has combat system
	var player = get_tree().get_first_node_in_group("rpg_player")
	if player:
		print("✓ Player found")
		if player.has_method("register_incoming_attack"):
			print("✓ Player has register_incoming_attack method")
		else:
			print("✗ Player missing register_incoming_attack method")
			return
	else:
		print("✗ No player found")
		return
	
	# Test creating an EnemyAttackSystem
	var test_attack_system = EnemyAttackSystem.new()
	test_attack_system.name = "TestAttackSystem"
	add_child(test_attack_system)
	
	# Wait for initialization
	await get_tree().create_timer(0.1).timeout
	
	if test_attack_system.player:
		print("✓ EnemyAttackSystem found player")
		
		# Test direct attack registration with player
		print("🗡️ Testing direct attack registration...")
		player.register_incoming_attack("integration_test", 2.0, 25.0, "frontal", "backward")
		print("✓ Direct attack registered - player should see telegraph in 2 seconds")
		
		# Test EnemyAttackSystem attack registration
		print("🗡️ Testing EnemyAttackSystem attack registration...")
		var test_attack = EnemyAttackSystem.AttackData.new("enemy_test", 1.5, 20.0, EnemyAttackSystem.AttackType.FRONTAL, CombatController.DodgeDirection.BACKWARD)
		test_attack_system.telegraph_attack(test_attack)
		print("✓ EnemyAttackSystem attack telegraphed")
		
		# Test full enemy creation and attack
		print("🗡️ Testing full enemy attack...")
		var test_enemy = BasicMeleeEnemy.new()
		test_enemy.name = "IntegrationTestEnemy"
		test_enemy.global_position = Vector3(0, 0, -3)
		add_child(test_enemy)
		
		# Wait for enemy initialization
		await get_tree().create_timer(0.2).timeout
		
		# Force enemy to attack
		print("Calling force_immediate_attack on enemy...")
		test_enemy.force_immediate_attack()
		print("✓ Full enemy attack initiated")
		
		# Clean up enemy
		test_enemy.queue_free()
	else:
		print("✗ EnemyAttackSystem failed to find player")
	
	# Clean up
	test_attack_system.queue_free()
	print("=== INTEGRATION TEST COMPLETE ===")
