extends Resource
class_name GameConfig

## Game-wide configuration settings
## Controls difficulty, spawning, and gameplay parameters

# ============================================================================
# Difficulty Settings
# ============================================================================

@export_group("Difficulty")
## Starting difficulty level (1.0 = normal)
@export var initial_difficulty: float = 1.0

## How often difficulty increases (in seconds)
@export var difficulty_increase_interval: float = 10.0

## Amount to increase difficulty each interval
@export var difficulty_increase_amount: float = 0.2

## Maximum difficulty level
@export var max_difficulty: float = 10.0

# ============================================================================
# Spawning Settings
# ============================================================================

@export_group("Spawning")
## Maximum time between spawns at start (seconds)
@export var max_spawn_interval: float = 2.5

## Minimum time between spawns (seconds)
@export var min_spawn_interval: float = 0.6

## Distance ahead of player to spawn objects
@export var spawn_distance: float = 40.0

## Enable obstacle spawning
@export var spawn_obstacles: bool = true

## Enable collectible spawning
@export var spawn_collectibles: bool = true

## Probability of spawning a power-up (0.0 - 1.0)
@export var powerup_spawn_chance: float = 0.15

# ============================================================================
# Scoring Settings
# ============================================================================

@export_group("Scoring")
## Points per distance unit traveled
@export var points_per_distance: float = 10.0

## Coin base value in points
@export var coin_points: int = 50

## Health potion points
@export var health_potion_points: int = 100

## Power-up collection points
@export var powerup_points: int = 150

## Enable combo multipliers
@export var enable_combos: bool = true

## Combo decay time (seconds without collecting)
@export var combo_decay_time: float = 3.0

# ============================================================================
# Physics Settings
# ============================================================================

@export_group("Physics")
## Gravity multiplier (higher = less floaty)
@export var gravity_multiplier: float = 2.5

## Movement speed multiplier
@export var movement_speed_multiplier: float = 1.0

## Enable realistic physics
@export var realistic_physics: bool = true

# ============================================================================
# Visual Settings
# ============================================================================

@export_group("Visual")
## Enable particle effects
@export var enable_particles: bool = true

## Enable screen shake
@export var enable_screen_shake: bool = true

## Enable power-up visual effects
@export var enable_powerup_visuals: bool = true

## UI scale factor
@export var ui_scale: float = 1.0

# ============================================================================
# Audio Settings (placeholder for future)
# ============================================================================

@export_group("Audio")
## Master volume (0.0 - 1.0)
@export var master_volume: float = 0.7

## Music volume (0.0 - 1.0)
@export var music_volume: float = 0.5

## SFX volume (0.0 - 1.0)
@export var sfx_volume: float = 0.7

# ============================================================================
# Helper Methods
# ============================================================================

func get_current_spawn_interval(difficulty: float) -> float:
	"""Calculate spawn interval based on current difficulty"""
	var interval = max_spawn_interval - (difficulty * 0.15)
	return clamp(interval, min_spawn_interval, max_spawn_interval)

func get_difficulty_scale(current_difficulty: float) -> float:
	"""Get normalized difficulty scale (0.0 - 1.0)"""
	return clamp(current_difficulty / max_difficulty, 0.0, 1.0)

func should_spawn_powerup() -> bool:
	"""Randomly determine if a power-up should spawn"""
	return randf() < powerup_spawn_chance

# ============================================================================
# Preset Configurations
# ============================================================================

static func create_easy_preset() -> GameConfig:
	"""Create an easy difficulty preset"""
	var config = GameConfig.new()
	config.initial_difficulty = 0.5
	config.difficulty_increase_interval = 15.0
	config.difficulty_increase_amount = 0.1
	config.max_spawn_interval = 3.0
	config.min_spawn_interval = 1.0
	config.powerup_spawn_chance = 0.25
	return config

static func create_normal_preset() -> GameConfig:
	"""Create a normal difficulty preset"""
	var config = GameConfig.new()
	# Uses default values
	return config

static func create_hard_preset() -> GameConfig:
	"""Create a hard difficulty preset"""
	var config = GameConfig.new()
	config.initial_difficulty = 1.5
	config.difficulty_increase_interval = 8.0
	config.difficulty_increase_amount = 0.3
	config.max_spawn_interval = 2.0
	config.min_spawn_interval = 0.4
	config.powerup_spawn_chance = 0.1
	return config

static func create_endless_preset() -> GameConfig:
	"""Create an endless mode preset (no max difficulty)"""
	var config = GameConfig.new()
	config.max_difficulty = 999.0
	config.difficulty_increase_amount = 0.15
	return config
