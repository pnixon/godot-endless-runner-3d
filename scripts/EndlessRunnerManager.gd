extends Node3D
class_name EndlessRunnerManager

# Main game manager for the endless runner
# Handles spawning, scoring, difficulty, and game flow

# Signals
signal game_started
signal game_over
signal score_changed(new_score: int)
signal coins_changed(new_coins: int)

# Node references
@onready var player: CharacterBody3D
@onready var ui_layer: CanvasLayer
@onready var ground_system: GroundSystem
@onready var camera: Camera3D

# Game state
var is_playing = false
var score = 0
var coins = 0
var distance = 0.0
var high_score = 0

# Power-up states
var has_shield = false
var shield_timer = 0.0
var has_speed_boost = false
var speed_boost_timer = 0.0
var has_magnet = false
var magnet_timer = 0.0

# Spawning system
const LANE_POSITIONS = [-3.0, 0.0, 3.0]
const SPAWN_DISTANCE = -40.0
const MIN_SPAWN_INTERVAL = 0.6
const MAX_SPAWN_INTERVAL = 2.5

var spawn_timer = 0.0
var current_spawn_interval = MAX_SPAWN_INTERVAL

# Difficulty progression
var difficulty_timer = 0.0
const DIFFICULTY_INCREASE_INTERVAL = 10.0
var current_difficulty = 1.0

# Spawn patterns
enum SpawnPattern {
	SINGLE_OBSTACLE,
	DOUBLE_OBSTACLE,
	TRIPLE_OBSTACLE,
	COIN_LINE,
	COIN_ZIGZAG,
	MIXED_CHALLENGE,
}

func _ready():
	setup_game()
	start_game()

func setup_game():
	"""Initialize the game systems"""
	print("=== Setting up Endless Runner ===")

	# Create ground system if it doesn't exist
	if not ground_system:
		ground_system = GroundSystem.new()
		ground_system.name = "GroundSystem"
		add_child(ground_system)
		print("✓ Ground system created")

	# Find or create player
	player = get_node_or_null("Player")
	if not player:
		print("Warning: Player not found, game may not function correctly")
	else:
		print("✓ Player found")
		# Connect player signals
		if player.has_signal("player_died"):
			player.player_died.connect(_on_player_died)

	# Setup camera
	setup_camera()

	# Setup lighting
	setup_lighting()

	print("=== Setup Complete ===")

func setup_camera():
	"""Setup the game camera"""
	camera = get_node_or_null("Camera3D")
	if not camera:
		camera = Camera3D.new()
		camera.name = "Camera3D"
		add_child(camera)

	# Position camera for good view of the action
	camera.position = Vector3(0, 8, 6)
	camera.rotation_degrees = Vector3(-35, 0, 0)
	camera.fov = 70.0

	print("✓ Camera configured")

func setup_lighting():
	"""Setup game lighting"""
	# Add directional light if it doesn't exist
	var light = get_node_or_null("DirectionalLight3D")
	if not light:
		light = DirectionalLight3D.new()
		light.name = "DirectionalLight3D"
		light.position = Vector3(0, 10, 0)
		light.rotation_degrees = Vector3(-45, 30, 0)
		light.light_energy = 1.2
		light.shadow_enabled = true
		add_child(light)
		print("✓ Lighting created")

func start_game():
	"""Start a new game"""
	print("Starting new game!")
	is_playing = true
	score = 0
	coins = 0
	distance = 0.0
	current_difficulty = 1.0
	current_spawn_interval = MAX_SPAWN_INTERVAL

	# Reset power-ups
	has_shield = false
	has_speed_boost = false
	has_magnet = false

	# Reset player
	if player:
		player.reset_position()

	# Clear existing obstacles and collectibles
	clear_all_spawned_objects()

	# Emit signals
	game_started.emit()
	score_changed.emit(score)
	coins_changed.emit(coins)

func _process(delta):
	if not is_playing:
		# Check for restart input
		if Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("ui_accept"):
			start_game()
		return

	# Update timers
	spawn_timer += delta
	difficulty_timer += delta
	distance += 10.0 * delta

	# Update power-up timers
	update_power_ups(delta)

	# Increase difficulty over time
	if difficulty_timer >= DIFFICULTY_INCREASE_INTERVAL:
		increase_difficulty()
		difficulty_timer = 0.0

	# Spawn obstacles and collectibles
	if spawn_timer >= current_spawn_interval:
		spawn_pattern()
		spawn_timer = 0.0

	# Update score based on distance
	var new_score = int(distance * 10)
	if new_score > score:
		score = new_score
		score_changed.emit(score)

func update_power_ups(delta: float):
	"""Update active power-up timers"""
	if has_shield:
		shield_timer -= delta
		if shield_timer <= 0:
			has_shield = false
			print("Shield expired")

	if has_speed_boost:
		speed_boost_timer -= delta
		if speed_boost_timer <= 0:
			has_speed_boost = false
			print("Speed boost expired")

	if has_magnet:
		magnet_timer -= delta
		if magnet_timer <= 0:
			has_magnet = false
			print("Magnet expired")
		else:
			# Attract nearby coins
			attract_coins()

func attract_coins():
	"""Magnet effect - attract coins to player"""
	if not player:
		return

	var collectibles = get_tree().get_nodes_in_group("collectibles")
	for collectible in collectibles:
		if collectible is Area3D:
			var type = Collectibles.get_collectible_type(collectible)
			if type == Collectibles.CollectibleType.COIN:
				# Move coin towards player
				var direction = (player.global_position - collectible.global_position).normalized()
				collectible.global_position += direction * 20.0 * get_process_delta_time()

func increase_difficulty():
	"""Gradually increase game difficulty"""
	current_difficulty += 0.2
	current_spawn_interval = max(MIN_SPAWN_INTERVAL, MAX_SPAWN_INTERVAL - (current_difficulty * 0.15))

	print("Difficulty increased! Level: ", current_difficulty, " Spawn interval: ", current_spawn_interval)

func spawn_pattern():
	"""Spawn a pattern of obstacles and collectibles"""
	var pattern = choose_pattern()

	match pattern:
		SpawnPattern.SINGLE_OBSTACLE:
			spawn_single_obstacle()
		SpawnPattern.DOUBLE_OBSTACLE:
			spawn_double_obstacle()
		SpawnPattern.TRIPLE_OBSTACLE:
			spawn_triple_obstacle()
		SpawnPattern.COIN_LINE:
			spawn_coin_line()
		SpawnPattern.COIN_ZIGZAG:
			spawn_coin_zigzag()
		SpawnPattern.MIXED_CHALLENGE:
			spawn_mixed_challenge()

func choose_pattern() -> SpawnPattern:
	"""Choose a spawn pattern based on difficulty"""
	var rand_value = randf()

	if current_difficulty < 2.0:
		# Easy patterns
		if rand_value < 0.4:
			return SpawnPattern.SINGLE_OBSTACLE
		elif rand_value < 0.7:
			return SpawnPattern.COIN_LINE
		else:
			return SpawnPattern.DOUBLE_OBSTACLE
	elif current_difficulty < 4.0:
		# Medium patterns
		if rand_value < 0.3:
			return SpawnPattern.DOUBLE_OBSTACLE
		elif rand_value < 0.5:
			return SpawnPattern.COIN_ZIGZAG
		elif rand_value < 0.7:
			return SpawnPattern.TRIPLE_OBSTACLE
		else:
			return SpawnPattern.MIXED_CHALLENGE
	else:
		# Hard patterns
		if rand_value < 0.4:
			return SpawnPattern.TRIPLE_OBSTACLE
		elif rand_value < 0.6:
			return SpawnPattern.MIXED_CHALLENGE
		else:
			return SpawnPattern.DOUBLE_OBSTACLE

func spawn_single_obstacle():
	"""Spawn a single obstacle in a random lane"""
	var lane = randi() % 3
	var obstacle = create_random_obstacle()
	obstacle.position = Vector3(LANE_POSITIONS[lane], 0, SPAWN_DISTANCE)
	add_child(obstacle)

func spawn_double_obstacle():
	"""Spawn obstacles in two lanes, leaving one clear"""
	var clear_lane = randi() % 3
	for i in range(3):
		if i != clear_lane:
			var obstacle = create_random_obstacle()
			obstacle.position = Vector3(LANE_POSITIONS[i], 0, SPAWN_DISTANCE)
			add_child(obstacle)

func spawn_triple_obstacle():
	"""Spawn different types of obstacles in all lanes"""
	# One lane has jumpable obstacle, one has slideable, one has wall
	var obstacle_types = [
		ObstacleTypes.HazardType.GROUND_SPIKES,
		ObstacleTypes.HazardType.OVERHEAD_BARRIER,
		ObstacleTypes.HazardType.WALL_CENTER
	]
	obstacle_types.shuffle()

	for i in range(3):
		var obstacle = create_specific_obstacle(obstacle_types[i])
		obstacle.position = Vector3(LANE_POSITIONS[i], 0, SPAWN_DISTANCE)
		add_child(obstacle)

func spawn_coin_line():
	"""Spawn a line of coins"""
	var lane = randi() % 3
	for i in range(5):
		var coin = Collectibles.create_coin()
		coin.position = Vector3(LANE_POSITIONS[lane], 0, SPAWN_DISTANCE + i * 3)
		add_child(coin)
		setup_collectible(coin)

func spawn_coin_zigzag():
	"""Spawn coins in a zigzag pattern"""
	var lanes = [0, 1, 2, 1, 0]
	for i in range(5):
		var coin = Collectibles.create_coin()
		coin.position = Vector3(LANE_POSITIONS[lanes[i]], 0, SPAWN_DISTANCE + i * 3)
		add_child(coin)
		setup_collectible(coin)

func spawn_mixed_challenge():
	"""Spawn a mix of obstacles and collectibles"""
	# Spawn obstacle in one lane
	var obstacle_lane = randi() % 3
	var obstacle = create_random_obstacle()
	obstacle.position = Vector3(LANE_POSITIONS[obstacle_lane], 0, SPAWN_DISTANCE)
	add_child(obstacle)

	# Spawn coins in other lanes
	for i in range(3):
		if i != obstacle_lane:
			var coin = Collectibles.create_coin()
			coin.position = Vector3(LANE_POSITIONS[i], 0, SPAWN_DISTANCE + randf_range(-2, 2))
			add_child(coin)
			setup_collectible(coin)

	# Occasionally add a power-up
	if randf() < 0.2:
		var powerup = create_random_powerup()
		var lane = (obstacle_lane + 1) % 3  # Different lane from obstacle
		powerup.position = Vector3(LANE_POSITIONS[lane], 0, SPAWN_DISTANCE - 5)
		add_child(powerup)
		setup_collectible(powerup)

func create_random_obstacle() -> Area3D:
	"""Create a random type of obstacle"""
	var obstacle_types = [
		ObstacleTypes.HazardType.GROUND_SPIKES,
		ObstacleTypes.HazardType.OVERHEAD_BARRIER,
		ObstacleTypes.HazardType.WALL_CENTER,
	]

	var type = obstacle_types[randi() % obstacle_types.size()]
	return create_specific_obstacle(type)

func create_specific_obstacle(type: ObstacleTypes.HazardType) -> Area3D:
	"""Create a specific type of obstacle"""
	var obstacle: Area3D

	match type:
		ObstacleTypes.HazardType.GROUND_SPIKES:
			obstacle = ObstacleTypes.create_ground_spikes()
		ObstacleTypes.HazardType.OVERHEAD_BARRIER:
			obstacle = ObstacleTypes.create_overhead_barrier()
		_:
			obstacle = ObstacleTypes.create_wall(type)

	setup_obstacle(obstacle)
	return obstacle

func setup_obstacle(obstacle: Area3D):
	"""Setup obstacle with collision detection"""
	obstacle.area_entered.connect(_on_obstacle_hit.bind(obstacle))

func create_random_powerup() -> Area3D:
	"""Create a random power-up"""
	var powerup_types = [
		Collectibles.CollectibleType.HEALTH_POTION,
		Collectibles.CollectibleType.SHIELD,
		Collectibles.CollectibleType.SPEED_BOOST,
		Collectibles.CollectibleType.MAGNET,
	]

	var type = powerup_types[randi() % powerup_types.size()]

	match type:
		Collectibles.CollectibleType.HEALTH_POTION:
			return Collectibles.create_health_potion()
		Collectibles.CollectibleType.SHIELD:
			return Collectibles.create_shield()
		Collectibles.CollectibleType.SPEED_BOOST:
			return Collectibles.create_speed_boost()
		Collectibles.CollectibleType.MAGNET:
			return Collectibles.create_magnet()
		_:
			return Collectibles.create_coin()

func setup_collectible(collectible: Area3D):
	"""Setup collectible with collection detection"""
	collectible.area_entered.connect(_on_collectible_collected.bind(collectible))

func _on_obstacle_hit(player_area: Area3D, obstacle: Area3D):
	"""Handle when player hits an obstacle"""
	if not is_playing or not player:
		return

	# Check if shield is active
	if has_shield:
		print("Shield absorbed damage!")
		obstacle.queue_free()
		return

	# Apply damage to player
	var damage = ObstacleTypes.get_damage(obstacle)
	if player.has_method("take_damage"):
		player.take_damage(damage)
		print("Player hit obstacle! Damage: ", damage)

	# Remove obstacle
	obstacle.queue_free()

func _on_collectible_collected(player_area: Area3D, collectible: Area3D):
	"""Handle when player collects an item"""
	if not is_playing:
		return

	var type = Collectibles.get_collectible_type(collectible)

	match type:
		Collectibles.CollectibleType.COIN:
			coins += Collectibles.get_value(collectible)
			score += Collectibles.get_score_bonus(collectible)
			coins_changed.emit(coins)
			score_changed.emit(score)
			print("Collected coin! Total: ", coins)

		Collectibles.CollectibleType.HEALTH_POTION:
			if player.has_method("heal"):
				player.heal(Collectibles.get_heal_amount(collectible))
			score += Collectibles.get_score_bonus(collectible)
			score_changed.emit(score)
			print("Collected health potion!")

		Collectibles.CollectibleType.SHIELD:
			has_shield = true
			shield_timer = Collectibles.get_duration(collectible)
			score += Collectibles.get_score_bonus(collectible)
			score_changed.emit(score)
			print("Shield activated for ", shield_timer, " seconds!")

		Collectibles.CollectibleType.SPEED_BOOST:
			has_speed_boost = true
			speed_boost_timer = Collectibles.get_duration(collectible)
			score += Collectibles.get_score_bonus(collectible)
			score_changed.emit(score)
			print("Speed boost activated!")

		Collectibles.CollectibleType.MAGNET:
			has_magnet = true
			magnet_timer = Collectibles.get_duration(collectible)
			score += Collectibles.get_score_bonus(collectible)
			score_changed.emit(score)
			print("Coin magnet activated!")

	# Remove collectible
	collectible.queue_free()

func _on_player_died():
	"""Handle player death"""
	print("Player died! Final score: ", score)
	is_playing = false

	# Update high score
	if score > high_score:
		high_score = score
		print("New high score: ", high_score)

	game_over.emit()

func clear_all_spawned_objects():
	"""Remove all obstacles and collectibles"""
	var objects = get_tree().get_nodes_in_group("obstacles")
	objects += get_tree().get_nodes_in_group("collectibles")

	for obj in objects:
		if is_instance_valid(obj):
			obj.queue_free()

	print("Cleared ", objects.size(), " spawned objects")

func get_score() -> int:
	return score

func get_coins() -> int:
	return coins

func get_high_score() -> int:
	return high_score
