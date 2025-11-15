extends Node
class_name GameConstants

## GameConstants - Centralized configuration constants
## This class provides a single source of truth for all game configuration values
## Use these constants throughout the codebase instead of magic numbers

# ============================================================================
# LANE AND GRID CONFIGURATION
# ============================================================================

## Number of lanes in the game (horizontal)
const LANE_COUNT: int = 3

## X positions for the three lanes
const LANE_POSITIONS: Array[float] = [-3.0, 0.0, 3.0]

## Z positions for combat rows (front to back)
const ROW_POSITIONS: Array[float] = [-8.0, -5.0, -2.0, 1.0]

## Default player starting lane (middle)
const DEFAULT_PLAYER_LANE: int = 1

# ============================================================================
# SPAWNING CONFIGURATION
# ============================================================================

## Distance ahead of player where objects spawn
const SPAWN_DISTANCE: float = 45.0

## Minimum spawn distance (for harder difficulties)
const MIN_SPAWN_DISTANCE: float = 30.0

## Maximum spawn distance (for easier difficulties or specific views)
const MAX_SPAWN_DISTANCE: float = 60.0

## Base spawn interval (seconds between spawns)
const BASE_SPAWN_INTERVAL: float = 1.8

## Minimum spawn interval (fastest spawning)
const MIN_SPAWN_INTERVAL: float = 0.6

## Maximum spawn interval (slowest spawning)
const MAX_SPAWN_INTERVAL: float = 3.0

# ============================================================================
# DIFFICULTY CONFIGURATION
# ============================================================================

## How often difficulty increases (seconds)
const DIFFICULTY_INCREASE_INTERVAL: float = 7.0

## How much spawn interval decreases per difficulty increase
const SPAWN_INTERVAL_DECREASE: float = 0.08

## Maximum difficulty level
const MAX_DIFFICULTY: float = 10.0

## Initial difficulty multiplier
const INITIAL_DIFFICULTY: float = 1.0

# ============================================================================
# ENEMY SPAWNING
# ============================================================================

## Base interval between enemy encounters (seconds)
const BASE_ENEMY_SPAWN_INTERVAL: float = 12.0

## Minimum time between enemy encounters
const MIN_ENEMY_SPAWN_INTERVAL: float = 6.0

## Distance traveled before enemies can spawn
const ENEMY_SPAWN_DISTANCE_THRESHOLD: float = 150.0

## Maximum active enemies at once
const MAX_ACTIVE_ENEMIES: int = 3

# ============================================================================
# PLAYER CONFIGURATION
# ============================================================================

## Default player health
const DEFAULT_PLAYER_HEALTH: float = 100.0

## Player height for jump calculations
const PLAYER_HEIGHT: float = 1.0

## Player movement speed (base)
const BASE_MOVEMENT_SPEED: float = 10.0

## Lane switch duration (seconds)
const LANE_SWITCH_DURATION: float = 0.2

## Jump duration (seconds)
const JUMP_DURATION: float = 0.3

## Slide duration (seconds)
const SLIDE_DURATION: float = 0.4

## Slide cooldown (seconds)
const SLIDE_COOLDOWN: float = 0.08

# ============================================================================
# COMBAT CONFIGURATION
# ============================================================================

## Auto-attack interval (seconds)
const AUTO_ATTACK_INTERVAL: float = 1.0

## Auto-attack range (units)
const AUTO_ATTACK_RANGE: float = 5.0

## Number of active skill slots
const ACTIVE_SKILL_SLOTS: int = 4

## Boss stagger threshold (hits needed)
const BOSS_STAGGER_THRESHOLD: int = 3

## Break mode duration (seconds)
const BREAK_MODE_DURATION: float = 5.0

## Break mode damage multiplier
const BREAK_MODE_DAMAGE_MULTIPLIER: float = 2.0

## Dodge i-frame duration (seconds)
const DODGE_IFRAME_DURATION: float = 0.3

## Block damage reduction percentage
const BLOCK_DAMAGE_REDUCTION: float = 0.5

# ============================================================================
# SCORING CONFIGURATION
# ============================================================================

## Points per unit of distance traveled
const POINTS_PER_DISTANCE: int = 10

## Points per coin collected
const POINTS_PER_COIN: int = 50

## Points for health potion
const POINTS_HEALTH_POTION: int = 100

## Points for power-up collection
const POINTS_POWER_UP: int = 150

## Points for perfect dodge
const POINTS_PERFECT_DODGE: int = 10

## Streak multiplier increase per perfect dodge
const STREAK_MULTIPLIER_INCREMENT: float = 0.1

## Time before streak starts decaying (seconds)
const STREAK_DECAY_TIME: float = 3.0

# ============================================================================
# DAMAGE VALUES
# ============================================================================

## Damage from ground spikes
const DAMAGE_GROUND_SPIKES: float = 20.0

## Damage from overhead barriers
const DAMAGE_OVERHEAD_BARRIER: float = 15.0

## Damage from walls
const DAMAGE_WALL: float = 25.0

## Damage from basic enemy attack
const DAMAGE_BASIC_ENEMY: float = 15.0

## Damage from elite enemy attack
const DAMAGE_ELITE_ENEMY: float = 25.0

## Damage from boss attack
const DAMAGE_BOSS: float = 40.0

# ============================================================================
# COLLECTIBLES
# ============================================================================

## Coin value
const COIN_VALUE: int = 1

## Health potion heal amount
const HEALTH_POTION_HEAL: float = 30.0

## Shield power-up duration (seconds)
const SHIELD_DURATION: float = 5.0

## Speed boost duration (seconds)
const SPEED_BOOST_DURATION: float = 5.0

## Speed boost multiplier
const SPEED_BOOST_MULTIPLIER: float = 1.5

## Magnet power-up duration (seconds)
const MAGNET_DURATION: float = 8.0

## Magnet attraction range (units)
const MAGNET_RANGE: float = 10.0

# ============================================================================
# BIOME SYSTEM
# ============================================================================

## Distance thresholds for biome transitions
const BIOME_THRESHOLDS: Array[int] = [0, 500, 1200, 2500]

## Biome names
const BIOME_NAMES: Array[String] = [
	"Tutorial Valley",
	"Mystic City",
	"Industrial Wasteland",
	"Volcanic Depths"
]

# ============================================================================
# CAMERA CONFIGURATION
# ============================================================================

## Camera smoothness (higher = more responsive)
const CAMERA_SMOOTHNESS: float = 10.0

## Third person camera distance
const CAMERA_THIRD_PERSON_DISTANCE: float = 8.0

## Third person camera height
const CAMERA_THIRD_PERSON_HEIGHT: float = 6.0

## Third person camera angle (degrees)
const CAMERA_THIRD_PERSON_ANGLE: float = -35.0

## First person height offset
const CAMERA_FIRST_PERSON_HEIGHT: float = 1.6

## Top down camera height
const CAMERA_TOP_DOWN_HEIGHT: float = 20.0

## Side view camera distance
const CAMERA_SIDE_VIEW_DISTANCE: float = 15.0

# ============================================================================
# AUDIO CONFIGURATION
# ============================================================================

## Default music volume (0.0 to 1.0)
const DEFAULT_MUSIC_VOLUME: float = 0.5

## Default SFX volume (0.0 to 1.0)
const DEFAULT_SFX_VOLUME: float = 0.7

## Music volume change step
const VOLUME_CHANGE_STEP: float = 0.1

# ============================================================================
# UI CONFIGURATION
# ============================================================================

## Floating text duration (seconds)
const FLOATING_TEXT_DURATION: float = 1.0

## Floating text rise distance (pixels)
const FLOATING_TEXT_RISE: float = 50.0

## HUD update interval (seconds) - 0 for every frame
const HUD_UPDATE_INTERVAL: float = 0.0

# ============================================================================
# SKILL ACQUISITION
# ============================================================================

## Skill fragment drop rate (percentage)
const SKILL_FRAGMENT_DROP_RATE: float = 0.3

## Fragments needed for basic skill
const FRAGMENTS_BASIC_SKILL: int = 10

## Fragments needed for advanced skill
const FRAGMENTS_ADVANCED_SKILL: int = 30

## Fragments needed for ultimate skill
const FRAGMENTS_ULTIMATE_SKILL: int = 75

# ============================================================================
# SAVE SYSTEM
# ============================================================================

## Auto-save interval (seconds)
const AUTO_SAVE_INTERVAL: float = 30.0

## Save file path
const SAVE_FILE_PATH: String = "user://legends_of_aetherion_save.dat"

## Backup save file path
const BACKUP_SAVE_PATH: String = "user://legends_of_aetherion_save_backup.dat"

## Game mode progress file
const MODE_PROGRESS_PATH: String = "user://game_mode_progress.save"

# ============================================================================
# PHYSICS CONFIGURATION
# ============================================================================

## Gravity multiplier for "crunchy" feel
const GRAVITY_MULTIPLIER: float = 2.5

## Jump power
const JUMP_POWER: float = 8.0

## Player weight (affects movement)
const PLAYER_WEIGHT: float = 1.0

# ============================================================================
# MOBILE INPUT
# ============================================================================

## Swipe threshold (pixels)
const SWIPE_THRESHOLD: float = 50.0

## Minimum swipe distance (pixels)
const MIN_SWIPE_DISTANCE: float = 100.0

## Tap maximum duration (seconds)
const TAP_MAX_DURATION: float = 0.3

## Long press duration (seconds)
const LONG_PRESS_DURATION: float = 0.5

## Haptic feedback intensity (0.0 to 1.0)
const HAPTIC_INTENSITY: float = 0.7

# ============================================================================
# PARTICLE EFFECTS
# ============================================================================

## Particle lifetime (seconds)
const PARTICLE_LIFETIME: float = 1.0

## Particle amount for effects
const PARTICLE_AMOUNT: int = 20

## Jump effect particle count
const JUMP_PARTICLE_COUNT: int = 10

## Coin collect particle count
const COIN_PARTICLE_COUNT: int = 15

# ============================================================================
# COMPANION SYSTEM
# ============================================================================

## Maximum companions per party
const MAX_PARTY_SIZE: int = 4

## Maximum active companions in combat
const MAX_ACTIVE_COMPANIONS: int = 2

## Maximum support companions (bench)
const MAX_SUPPORT_COMPANIONS: int = 2

## Bond levels required for bonuses
const BOND_LEVEL_TIERS: Array[int] = [10, 25, 50, 75, 100]

# ============================================================================
# EQUIPMENT SYSTEM
# ============================================================================

## Equipment slots
enum EquipmentSlot {
	WEAPON,
	ARMOR,
	ACCESSORY,
	HELMET,
	BOOTS
}

## Rarity multipliers for stats
const RARITY_STAT_MULTIPLIERS: Dictionary = {
	"Common": 1.0,
	"Rare": 1.5,
	"Epic": 2.0,
	"Legendary": 3.0
}

# ============================================================================
# GAME MODE CONFIGURATION
# ============================================================================

## Story mode star thresholds (percentage of objectives completed)
const STAR_THRESHOLDS: Array[float] = [0.33, 0.66, 1.0]

## Challenge mode milestone distances
const CHALLENGE_MILESTONES: Array[int] = [100, 500, 1000, 2500, 5000]

## Timed mode rank thresholds (percentage of target score)
const RANK_THRESHOLDS: Dictionary = {
	"S": 1.5,
	"A": 1.25,
	"B": 1.0,
	"C": 0.75
}

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

## Get lane position by index
static func get_lane_position(lane_index: int) -> float:
	if lane_index < 0 or lane_index >= LANE_POSITIONS.size():
		push_warning("Invalid lane index: " + str(lane_index))
		return LANE_POSITIONS[DEFAULT_PLAYER_LANE]
	return LANE_POSITIONS[lane_index]

## Get row position by index
static func get_row_position(row_index: int) -> float:
	if row_index < 0 or row_index >= ROW_POSITIONS.size():
		push_warning("Invalid row index: " + str(row_index))
		return ROW_POSITIONS[0]
	return ROW_POSITIONS[row_index]

## Get biome name by distance
static func get_biome_name(distance: float) -> String:
	for i in range(BIOME_THRESHOLDS.size() - 1, -1, -1):
		if distance >= BIOME_THRESHOLDS[i]:
			return BIOME_NAMES[i] if i < BIOME_NAMES.size() else "Unknown"
	return BIOME_NAMES[0]

## Get biome index by distance
static func get_biome_index(distance: float) -> int:
	for i in range(BIOME_THRESHOLDS.size() - 1, -1, -1):
		if distance >= BIOME_THRESHOLDS[i]:
			return i
	return 0

## Calculate current spawn interval based on difficulty
static func calculate_spawn_interval(difficulty: float) -> float:
	var interval = BASE_SPAWN_INTERVAL - (difficulty * SPAWN_INTERVAL_DECREASE)
	return clamp(interval, MIN_SPAWN_INTERVAL, MAX_SPAWN_INTERVAL)

## Calculate streak multiplier
static func calculate_streak_multiplier(streak: int) -> float:
	return 1.0 + (streak * STREAK_MULTIPLIER_INCREMENT)

## Convert linear volume to decibels
static func linear_to_db(linear_volume: float) -> float:
	if linear_volume <= 0.0:
		return -80.0  # Essentially mute
	return 20.0 * log(linear_volume) / log(10.0)

## Convert decibels to linear volume
static func db_to_linear(db_volume: float) -> float:
	if db_volume <= -80.0:
		return 0.0
	return pow(10.0, db_volume / 20.0)

## Format time as MM:SS
static func format_time(seconds: float) -> String:
	var mins = int(seconds) / 60
	var secs = int(seconds) % 60
	return "%02d:%02d" % [mins, secs]

## Get damage value by obstacle type
static func get_obstacle_damage(obstacle_type: String) -> float:
	match obstacle_type:
		"ground_spikes":
			return DAMAGE_GROUND_SPIKES
		"overhead_barrier":
			return DAMAGE_OVERHEAD_BARRIER
		"wall":
			return DAMAGE_WALL
		_:
			return 10.0  # Default damage

## Validate lane index
static func is_valid_lane(lane_index: int) -> bool:
	return lane_index >= 0 and lane_index < LANE_COUNT

## Validate row index
static func is_valid_row(row_index: int) -> bool:
	return row_index >= 0 and row_index < ROW_POSITIONS.size()

## Clamp lane index to valid range
static func clamp_lane(lane_index: int) -> int:
	return clampi(lane_index, 0, LANE_COUNT - 1)

## Clamp row index to valid range
static func clamp_row(row_index: int) -> int:
	return clampi(row_index, 0, ROW_POSITIONS.size() - 1)
