extends Resource
class_name SpawnConfig

## Spawn pattern configuration for obstacles and collectibles
## Defines what spawns, when, and in what patterns

# ============================================================================
# Spawn Weights (Probability)
# ============================================================================

@export_group("Obstacle Weights")
## Ground spikes spawn weight
@export var ground_spikes_weight: float = 1.0

## Overhead barrier spawn weight
@export var overhead_barrier_weight: float = 1.0

## Wall obstacle spawn weight
@export var wall_weight: float = 0.8

@export_group("Collectible Weights")
## Coin spawn weight
@export var coin_weight: float = 3.0

## Health potion spawn weight
@export var health_potion_weight: float = 0.5

## Shield spawn weight
@export var shield_weight: float = 0.3

## Speed boost spawn weight
@export var speed_boost_weight: float = 0.4

## Magnet spawn weight
@export var magnet_weight: float = 0.4

# ============================================================================
# Pattern Definitions
# ============================================================================

@export_group("Spawn Patterns")
## Enable single obstacle patterns
@export var enable_single: bool = true

## Enable double obstacle patterns (blocks 2 lanes)
@export var enable_double: bool = true

## Enable triple obstacle patterns (forces specific action)
@export var enable_triple: bool = true

## Enable coin line patterns
@export var enable_coin_lines: bool = true

## Enable coin zigzag patterns
@export var enable_coin_zigzag: bool = true

## Enable mixed challenge patterns (obstacles + collectibles)
@export var enable_mixed: bool = true

## Enable wave patterns (multiple obstacles in sequence)
@export var enable_waves: bool = false

## Enable wall patterns (full lane blocks)
@export var enable_walls: bool = true

# ============================================================================
# Pattern Complexity
# ============================================================================

@export_group("Complexity")
## Minimum difficulty for double obstacles
@export var double_obstacle_min_difficulty: float = 1.5

## Minimum difficulty for triple obstacles
@export var triple_obstacle_min_difficulty: float = 2.5

## Minimum difficulty for wave patterns
@export var wave_min_difficulty: float = 3.0

## Maximum obstacles per pattern
@export var max_obstacles_per_pattern: int = 5

## Spacing between obstacles in a pattern (in units)
@export var obstacle_spacing: float = 3.0

# ============================================================================
# Collectible Patterns
# ============================================================================

@export_group("Collectible Patterns")
## Coins per line pattern
@export var coins_per_line: int = 5

## Coins per zigzag pattern
@export var coins_per_zigzag: int = 7

## Collectible cluster size
@export var collectible_cluster_size: int = 3

## Probability of collectible appearing with obstacle (0.0-1.0)
@export var collectible_with_obstacle_chance: float = 0.6

# ============================================================================
## Special Patterns
# ============================================================================

@export_group("Special Patterns")
## Enable bonus sections (safe zones with lots of coins)
@export var enable_bonus_sections: bool = true

## Bonus section spawn chance (per spawn opportunity)
@export var bonus_section_chance: float = 0.05

## Enable challenge sections (intense obstacle sequences)
@export var enable_challenge_sections: bool = true

## Challenge section spawn chance
@export var challenge_section_chance: float = 0.08

## Enable power-up zones (clustered power-ups)
@export var enable_powerup_zones: bool = true

# ============================================================================
# Helper Methods
# ============================================================================

func get_random_obstacle_type() -> int:
	"""Get a random obstacle type based on weights"""
	var total_weight = ground_spikes_weight + overhead_barrier_weight + wall_weight
	var rand = randf() * total_weight

	if rand < ground_spikes_weight:
		return ObstacleTypes.HazardType.GROUND_SPIKES
	elif rand < ground_spikes_weight + overhead_barrier_weight:
		return ObstacleTypes.HazardType.OVERHEAD_BARRIER
	else:
		return ObstacleTypes.HazardType.WALL_CENTER

func get_random_collectible_type() -> int:
	"""Get a random collectible type based on weights"""
	var total_weight = coin_weight + health_potion_weight + shield_weight + speed_boost_weight + magnet_weight
	var rand = randf() * total_weight

	if rand < coin_weight:
		return Collectibles.CollectibleType.COIN
	elif rand < coin_weight + health_potion_weight:
		return Collectibles.CollectibleType.HEALTH_POTION
	elif rand < coin_weight + health_potion_weight + shield_weight:
		return Collectibles.CollectibleType.SHIELD
	elif rand < coin_weight + health_potion_weight + shield_weight + speed_boost_weight:
		return Collectibles.CollectibleType.SPEED_BOOST
	else:
		return Collectibles.CollectibleType.MAGNET

func get_available_patterns(difficulty: float) -> Array[String]:
	"""Get list of patterns available at current difficulty"""
	var patterns: Array[String] = []

	if enable_single:
		patterns.append("single_obstacle")

	if enable_coin_lines:
		patterns.append("coin_line")

	if enable_double and difficulty >= double_obstacle_min_difficulty:
		patterns.append("double_obstacle")

	if enable_coin_zigzag:
		patterns.append("coin_zigzag")

	if enable_triple and difficulty >= triple_obstacle_min_difficulty:
		patterns.append("triple_obstacle")

	if enable_mixed:
		patterns.append("mixed_challenge")

	if enable_waves and difficulty >= wave_min_difficulty:
		patterns.append("wave_pattern")

	if enable_walls:
		patterns.append("wall_pattern")

	# Special patterns based on chance
	if enable_bonus_sections and randf() < bonus_section_chance:
		patterns.append("bonus_section")

	if enable_challenge_sections and randf() < challenge_section_chance and difficulty >= 2.0:
		patterns.append("challenge_section")

	return patterns

func should_spawn_collectible_with_obstacle() -> bool:
	"""Determine if collectible should spawn with obstacle"""
	return randf() < collectible_with_obstacle_chance

# ============================================================================
# Preset Configurations
# ============================================================================

static func create_easy_preset() -> SpawnConfig:
	"""Easy spawn configuration - lots of coins, few obstacles"""
	var config = SpawnConfig.new()
	config.ground_spikes_weight = 0.8
	config.overhead_barrier_weight = 0.6
	config.wall_weight = 0.3
	config.coin_weight = 5.0
	config.health_potion_weight = 1.0
	config.enable_triple = false
	config.enable_waves = false
	config.collectible_with_obstacle_chance = 0.8
	return config

static func create_normal_preset() -> SpawnConfig:
	"""Normal spawn configuration"""
	return SpawnConfig.new()  # Use defaults

static func create_hard_preset() -> SpawnConfig:
	"""Hard spawn configuration - more obstacles, fewer coins"""
	var config = SpawnConfig.new()
	config.ground_spikes_weight = 1.5
	config.overhead_barrier_weight = 1.5
	config.wall_weight = 1.2
	config.coin_weight = 2.0
	config.health_potion_weight = 0.3
	config.shield_weight = 0.2
	config.double_obstacle_min_difficulty = 1.0
	config.triple_obstacle_min_difficulty = 1.5
	config.wave_min_difficulty = 2.0
	config.enable_waves = true
	config.collectible_with_obstacle_chance = 0.4
	return config

static func create_coin_collector_preset() -> SpawnConfig:
	"""Configuration optimized for coin collecting"""
	var config = SpawnConfig.new()
	config.coin_weight = 10.0
	config.ground_spikes_weight = 0.5
	config.overhead_barrier_weight = 0.5
	config.wall_weight = 0.3
	config.enable_coin_lines = true
	config.enable_coin_zigzag = true
	config.coins_per_line = 8
	config.coins_per_zigzag = 10
	config.collectible_with_obstacle_chance = 0.9
	config.bonus_section_chance = 0.15
	return config

static func create_survival_preset() -> SpawnConfig:
	"""Configuration for survival mode - intense obstacles"""
	var config = SpawnConfig.new()
	config.ground_spikes_weight = 2.0
	config.overhead_barrier_weight = 2.0
	config.wall_weight = 1.5
	config.coin_weight = 1.0
	config.health_potion_weight = 0.8
	config.shield_weight = 0.5
	config.double_obstacle_min_difficulty = 0.5
	config.triple_obstacle_min_difficulty = 1.0
	config.wave_min_difficulty = 1.5
	config.enable_waves = true
	config.enable_challenge_sections = true
	config.challenge_section_chance = 0.15
	config.collectible_with_obstacle_chance = 0.3
	return config

static func create_platformer_preset() -> SpawnConfig:
	"""Configuration for platformer-style gameplay"""
	var config = SpawnConfig.new()
	config.ground_spikes_weight = 2.0
	config.overhead_barrier_weight = 0.3
	config.wall_weight = 0.5
	config.coin_weight = 4.0
	config.enable_walls = false
	config.enable_coin_lines = true
	config.coins_per_line = 6
	return config

static func create_obstacle_course_preset() -> SpawnConfig:
	"""Configuration for obstacle course style"""
	var config = SpawnConfig.new()
	config.ground_spikes_weight = 1.5
	config.overhead_barrier_weight = 1.5
	config.wall_weight = 1.0
	config.enable_single = false
	config.enable_double = true
	config.enable_triple = true
	config.enable_waves = true
	config.double_obstacle_min_difficulty = 0.5
	config.triple_obstacle_min_difficulty = 1.0
	config.max_obstacles_per_pattern = 7
	return config
