extends Node3D
class_name ConfigurableGameManager

## Highly configurable game manager for endless runner
## Supports multiple gameplay modes, difficulty presets, and view configurations

# ============================================================================
# Signals
# ============================================================================

signal game_started
signal game_over(final_score: int)
signal score_changed(new_score: int)
signal coins_changed(new_coins: int)
signal difficulty_changed(new_difficulty: float)

# ============================================================================
# Configuration
# ============================================================================

@export var game_config: GameConfig
@export var character_config: CharacterConfig
@export var spawn_config: SpawnConfig

@export_group("Nodes")
@export var player: ConfigurablePlayer
@export var camera_controller: CameraController
@export var ground_system: GroundSystem

# ============================================================================
# Game State
# ============================================================================

var is_playing: bool = false
var score: int = 0
var coins: int = 0
var distance: float = 0.0
var high_score: int = 0
var current_difficulty: float = 1.0

# Timers
var spawn_timer: float = 0.0
var difficulty_timer: float = 0.0

# View integration
var view_adapter: ViewAdapter

# ============================================================================
# Initialization
# ============================================================================

func _ready():
	add_to_group("game_manager")

	# Create default configs if not set
	if not game_config:
		game_config = GameConfig.create_normal_preset()

	if not character_config:
		character_config = CharacterConfig.create_balanced()

	if not spawn_config:
		spawn_config = SpawnConfig.create_normal_preset()

	# Setup systems
	setup_camera()
	setup_view_adapter()
	setup_player()
	setup_ground()
	setup_lighting()

	print("=== ConfigurableGameManager Ready ===")
	print("Game Config: Difficulty ", game_config.initial_difficulty)
	print("Character: ", character_config.character_name)
	print("Camera Mode: ", CameraController.ViewMode.keys()[camera_controller.view_mode] if camera_controller else "NONE")

# ============================================================================
# Setup Methods
# ============================================================================

func setup_camera():
	"""Setup camera controller"""
	if not camera_controller:
		camera_controller = CameraController.new()
		camera_controller.name = "CameraController"
		add_child(camera_controller)

	# Set target to player if available
	if player:
		camera_controller.set_target(player)

func setup_view_adapter():
	"""Setup view adapter"""
	view_adapter = ViewAdapter.new(camera_controller)
	add_child(view_adapter)
	view_adapter.name = "ViewAdapter"

func setup_player():
	"""Setup player with configurations"""
	if not player:
		# Try to find player in scene
		player = get_node_or_null("Player")

	if not player:
		# Create new player
		player = ConfigurablePlayer.new()
		player.name = "Player"
		add_child(player)

	# Apply configurations
	player.character_config = character_config
	player.view_adapter = view_adapter
	player.camera_controller = camera_controller

	# Connect signals
	if not player.player_died.is_connected(_on_player_died):
		player.player_died.connect(_on_player_died)
	if not player.health_changed.is_connected(_on_player_health_changed):
		player.health_changed.connect(_on_player_health_changed)

	# Set camera target
	if camera_controller:
		camera_controller.set_target(player)

func setup_ground():
	"""Setup ground system"""
	if not ground_system:
		ground_system = GroundSystem.new()
		ground_system.name = "GroundSystem"
		add_child(ground_system)

func setup_lighting():
	"""Setup scene lighting"""
	var light = get_node_or_null("DirectionalLight3D")
	if not light:
		light = DirectionalLight3D.new()
		light.name = "DirectionalLight3D"
		light.position = Vector3(0, 10, 0)
		light.rotation_degrees = Vector3(-45, 30, 0)
		light.light_energy = 1.2
		light.shadow_enabled = true
		add_child(light)

	var env = get_node_or_null("WorldEnvironment")
	if not env:
		env = WorldEnvironment.new()
		env.name = "WorldEnvironment"
		var environment = Environment.new()
		environment.background_mode = Environment.BG_COLOR
		environment.background_color = Color(0.4, 0.6, 0.8)
		environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		environment.ambient_light_color = Color(0.8, 0.8, 0.9)
		environment.ambient_light_energy = 0.6
		env.environment = environment
		add_child(env)

# ============================================================================
# Game Loop
# ============================================================================

func start_game():
	"""Start a new game"""
	print("Starting game...")

	# Reset state
	is_playing = true
	score = 0
	coins = 0
	distance = 0.0
	current_difficulty = game_config.initial_difficulty
	spawn_timer = 0.0
	difficulty_timer = 0.0

	# Reset player
	if player:
		player.reset_to_spawn_position()

	# Clear existing spawned objects
	clear_all_spawned_objects()

	# Emit signals
	game_started.emit()
	score_changed.emit(score)
	coins_changed.emit(coins)

func _process(delta):
	if not is_playing:
		# Check for start input
		if Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("ui_accept"):
			start_game()
		return

	# Update timers
	spawn_timer += delta
	difficulty_timer += delta
	distance += 10.0 * delta * game_config.movement_speed_multiplier

	# Update difficulty
	if difficulty_timer >= game_config.difficulty_increase_interval:
		increase_difficulty()
		difficulty_timer = 0.0

	# Update score based on distance
	var new_score = int(distance * game_config.points_per_distance)
	if player:
		new_score = int(new_score * player.get_score_multiplier())

	if new_score > score:
		score = new_score
		score_changed.emit(score)

	# Spawn patterns
	var spawn_interval = game_config.get_current_spawn_interval(current_difficulty)
	if view_adapter:
		spawn_interval *= view_adapter.get_difficulty_multiplier()

	if spawn_timer >= spawn_interval:
		spawn_pattern()
		spawn_timer = 0.0

# ============================================================================
# Difficulty System
# ============================================================================

func increase_difficulty():
	"""Increase game difficulty"""
	current_difficulty = min(game_config.max_difficulty,
		current_difficulty + game_config.difficulty_increase_amount)

	difficulty_changed.emit(current_difficulty)
	print("Difficulty increased to: ", current_difficulty)

# ============================================================================
# Spawning System
# ============================================================================

func spawn_pattern():
	"""Spawn obstacles and collectibles based on configuration"""
	var available_patterns = spawn_config.get_available_patterns(current_difficulty)

	if available_patterns.is_empty():
		return

	var pattern = available_patterns[randi() % available_patterns.size()]

	match pattern:
		"single_obstacle":
			spawn_single_obstacle()
		"double_obstacle":
			spawn_double_obstacle()
		"triple_obstacle":
			spawn_triple_obstacle()
		"coin_line":
			spawn_coin_line()
		"coin_zigzag":
			spawn_coin_zigzag()
		"mixed_challenge":
			spawn_mixed_challenge()
		"wave_pattern":
			spawn_wave_pattern()
		"wall_pattern":
			spawn_wall_pattern()
		"bonus_section":
			spawn_bonus_section()
		"challenge_section":
			spawn_challenge_section()

func spawn_single_obstacle():
	"""Spawn single obstacle"""
	var lane = randi() % 3
	var obstacle_type = spawn_config.get_random_obstacle_type()
	var obstacle = create_obstacle(obstacle_type)
	if obstacle and view_adapter:
		obstacle.position = view_adapter.get_spawn_position(lane)
		add_child(obstacle)
		setup_obstacle(obstacle)

func spawn_double_obstacle():
	"""Spawn obstacles in two lanes"""
	var clear_lane = randi() % 3
	for i in range(3):
		if i != clear_lane:
			var obstacle_type = spawn_config.get_random_obstacle_type()
			var obstacle = create_obstacle(obstacle_type)
			if obstacle and view_adapter:
				obstacle.position = view_adapter.get_spawn_position(i)
				add_child(obstacle)
				setup_obstacle(obstacle)

func spawn_triple_obstacle():
	"""Spawn different obstacles in all lanes"""
	var types = [
		ObstacleTypes.HazardType.GROUND_SPIKES,
		ObstacleTypes.HazardType.OVERHEAD_BARRIER,
		ObstacleTypes.HazardType.WALL_CENTER
	]
	types.shuffle()

	for i in range(3):
		var obstacle = create_obstacle(types[i])
		if obstacle and view_adapter:
			obstacle.position = view_adapter.get_spawn_position(i)
			add_child(obstacle)
			setup_obstacle(obstacle)

func spawn_coin_line():
	"""Spawn line of coins"""
	var lane = randi() % 3
	for i in range(spawn_config.coins_per_line):
		var coin = Collectibles.create_coin()
		if coin and view_adapter:
			var pos = view_adapter.get_spawn_position(lane)
			pos.z += i * 3.0
			coin.position = pos
			add_child(coin)
			setup_collectible(coin)

func spawn_coin_zigzag():
	"""Spawn coins in zigzag pattern"""
	var lanes = [0, 1, 2, 1, 0, 1, 2]
	for i in range(min(spawn_config.coins_per_zigzag, lanes.size())):
		var coin = Collectibles.create_coin()
		if coin and view_adapter:
			var pos = view_adapter.get_spawn_position(lanes[i])
			pos.z += i * 2.5
			coin.position = pos
			add_child(coin)
			setup_collectible(coin)

func spawn_mixed_challenge():
	"""Spawn mix of obstacles and collectibles"""
	var obstacle_lane = randi() % 3
	var obstacle = create_obstacle(spawn_config.get_random_obstacle_type())
	if obstacle and view_adapter:
		obstacle.position = view_adapter.get_spawn_position(obstacle_lane)
		add_child(obstacle)
		setup_obstacle(obstacle)

	if spawn_config.should_spawn_collectible_with_obstacle():
		for i in range(3):
			if i != obstacle_lane:
				var coin = Collectibles.create_coin()
				if coin and view_adapter:
					var pos = view_adapter.get_spawn_position(i)
					pos.z += randf_range(-2, 2)
					coin.position = pos
					add_child(coin)
					setup_collectible(coin)

func spawn_wave_pattern():
	"""Spawn wave of obstacles"""
	for i in range(3):
		var obstacle = create_obstacle(spawn_config.get_random_obstacle_type())
		if obstacle and view_adapter:
			var pos = view_adapter.get_spawn_position(i)
			pos.z -= i * spawn_config.obstacle_spacing
			obstacle.position = pos
			add_child(obstacle)
			setup_obstacle(obstacle)

func spawn_wall_pattern():
	"""Spawn wall obstacle"""
	var lane = randi() % 3
	var obstacle = ObstacleTypes.create_wall(ObstacleTypes.HazardType.WALL_CENTER)
	if obstacle and view_adapter:
		obstacle.position = view_adapter.get_spawn_position(lane)
		add_child(obstacle)
		setup_obstacle(obstacle)

func spawn_bonus_section():
	"""Spawn bonus section with lots of coins"""
	print("Bonus section!")
	for lane in range(3):
		for i in range(5):
			var coin = Collectibles.create_coin()
			if coin and view_adapter:
				var pos = view_adapter.get_spawn_position(lane)
				pos.z += i * 2.0
				coin.position = pos
				add_child(coin)
				setup_collectible(coin)

func spawn_challenge_section():
	"""Spawn challenging obstacle sequence"""
	print("Challenge section!")
	for i in range(5):
		var lanes_blocked = [randi() % 3, (randi() % 3 + 1) % 3]
		for lane in lanes_blocked:
			var obstacle = create_obstacle(spawn_config.get_random_obstacle_type())
			if obstacle and view_adapter:
				var pos = view_adapter.get_spawn_position(lane)
				pos.z -= i * spawn_config.obstacle_spacing
				obstacle.position = pos
				add_child(obstacle)
				setup_obstacle(obstacle)

# ============================================================================
# Object Creation
# ============================================================================

func create_obstacle(type: int) -> Area3D:
	"""Create obstacle of specified type"""
	match type:
		ObstacleTypes.HazardType.GROUND_SPIKES:
			return ObstacleTypes.create_ground_spikes()
		ObstacleTypes.HazardType.OVERHEAD_BARRIER:
			return ObstacleTypes.create_overhead_barrier()
		_:
			return ObstacleTypes.create_wall(type)

func setup_obstacle(obstacle: Area3D):
	"""Setup obstacle collision detection"""
	if player and player.player_area:
		obstacle.area_entered.connect(_on_obstacle_hit.bind(obstacle))

func setup_collectible(collectible: Area3D):
	"""Setup collectible collision detection"""
	if player and player.player_area:
		collectible.area_entered.connect(_on_collectible_collected.bind(collectible))

# ============================================================================
# Collision Handlers
# ============================================================================

func _on_obstacle_hit(player_area: Area3D, obstacle: Area3D):
	"""Handle obstacle collision"""
	if not is_playing or not player:
		return

	# Check if player can break obstacles
	if player.can_break_obstacles():
		print("Obstacle destroyed!")
		var effect = ParticleEffects.create_obstacle_destroy_effect(
			obstacle.global_position,
			Color(0.8, 0.4, 0.1)
		)
		add_child(effect)
		obstacle.queue_free()
		score += 50
		score_changed.emit(score)
		return

	# Check if player has shield
	if player.has_power_up("shield"):
		print("Shield blocked!")
		obstacle.queue_free()
		return

	# Apply damage
	var damage = ObstacleTypes.get_damage(obstacle)
	player.take_damage(damage)
	obstacle.queue_free()

func _on_collectible_collected(player_area: Area3D, collectible: Area3D):
	"""Handle collectible collection"""
	if not is_playing or not player:
		return

	var type = Collectibles.get_collectible_type(collectible)

	match type:
		Collectibles.CollectibleType.COIN:
			var value = Collectibles.get_value(collectible)
			var score_bonus = Collectibles.get_score_bonus(collectible)

			coins += value * int(player.get_coin_multiplier())
			score += score_bonus * int(player.get_score_multiplier())

			coins_changed.emit(coins)
			score_changed.emit(score)

			var effect = ParticleEffects.create_coin_collect_effect(collectible.global_position)
			add_child(effect)

		Collectibles.CollectibleType.HEALTH_POTION:
			player.heal(Collectibles.get_heal_amount(collectible))
			score += Collectibles.get_score_bonus(collectible)
			score_changed.emit(score)

			var effect = ParticleEffects.create_powerup_collect_effect(collectible.global_position, Color(1, 0.2, 0.2))
			add_child(effect)

		Collectibles.CollectibleType.SHIELD:
			player.activate_power_up("shield", Collectibles.get_duration(collectible))
			score += Collectibles.get_score_bonus(collectible)
			score_changed.emit(score)

			var effect = ParticleEffects.create_powerup_collect_effect(collectible.global_position, Color(0, 0.8, 0.8))
			add_child(effect)

		Collectibles.CollectibleType.SPEED_BOOST:
			player.activate_power_up("speed_boost", Collectibles.get_duration(collectible))
			score += Collectibles.get_score_bonus(collectible)
			score_changed.emit(score)

			var effect = ParticleEffects.create_powerup_collect_effect(collectible.global_position, Color(0.2, 0.6, 1.0))
			add_child(effect)

		Collectibles.CollectibleType.MAGNET:
			player.activate_power_up("magnet", Collectibles.get_duration(collectible))
			score += Collectibles.get_score_bonus(collectible)
			score_changed.emit(score)

			var effect = ParticleEffects.create_powerup_collect_effect(collectible.global_position, Color(0.8, 0.2, 0.8))
			add_child(effect)

	collectible.queue_free()

# ============================================================================
# Event Handlers
# ============================================================================

func _on_player_died():
	"""Handle player death"""
	print("Game Over! Final Score: ", score)
	is_playing = false

	if score > high_score:
		high_score = score
		print("New high score!")

	game_over.emit(score)

func _on_player_health_changed(current: float, maximum: float):
	"""Handle player health changes"""
	# Could trigger UI updates here
	pass

# ============================================================================
# Utility Methods
# ============================================================================

func clear_all_spawned_objects():
	"""Remove all obstacles and collectibles"""
	var objects = get_tree().get_nodes_in_group("obstacles")
	objects += get_tree().get_nodes_in_group("collectibles")

	for obj in objects:
		if is_instance_valid(obj):
			obj.queue_free()

func get_score() -> int:
	return score

func get_coins() -> int:
	return coins

func get_high_score() -> int:
	return high_score

func get_current_difficulty() -> float:
	return current_difficulty

# ============================================================================
# Configuration Presets
# ============================================================================

func apply_preset(preset_name: String):
	"""Apply a named preset configuration"""
	match preset_name.to_lower():
		"easy":
			game_config = GameConfig.create_easy_preset()
			spawn_config = SpawnConfig.create_easy_preset()
		"normal":
			game_config = GameConfig.create_normal_preset()
			spawn_config = SpawnConfig.create_normal_preset()
		"hard":
			game_config = GameConfig.create_hard_preset()
			spawn_config = SpawnConfig.create_hard_preset()
		"survival":
			spawn_config = SpawnConfig.create_survival_preset()
		"coin_collector":
			spawn_config = SpawnConfig.create_coin_collector_preset()

	print("Applied preset: ", preset_name)

func set_character_preset(preset_name: String):
	"""Set character preset"""
	character_config = CharacterConfig.get_preset_by_name(preset_name)

	if player:
		player.character_config = character_config
		player.reset_to_spawn_position()

	print("Character changed to: ", character_config.character_name)

func set_camera_mode(mode: CameraController.ViewMode):
	"""Set camera view mode"""
	if camera_controller:
		camera_controller.set_view_mode(mode)
