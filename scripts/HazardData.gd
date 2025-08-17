class_name HazardData
extends Resource

enum HazardType {
	NONE,
	GROUND_SPIKES,    # Player must hop over
	OVERHEAD_BARRIER, # Player must slide under
	PICKUP_COIN,      # Collect for points
	PICKUP_XP,        # Collect for experience
	ENEMY_MARKER,     # Triggers combat encounter
	HEALTH_POTION     # Restores health
}

@export var type: HazardType
@export var lane: int  # 0, 1, or 2
@export var telegraph_time: float = 1.0  # Warning time in seconds
@export var color: Color = Color.WHITE
@export var size: Vector2 = Vector2(48, 48)
@export var enemy_formation_id: String = ""  # For enemy markers

# Hazard factory methods
static func create_ground_spikes(target_lane: int) -> HazardData:
	var hazard = HazardData.new()
	hazard.type = HazardType.GROUND_SPIKES
	hazard.lane = target_lane
	hazard.color = Color.RED
	hazard.size = Vector2(48, 48)  # Made taller so they're more visible
	hazard.telegraph_time = 1.0
	return hazard

static func create_overhead_barrier(target_lane: int) -> HazardData:
	var hazard = HazardData.new()
	hazard.type = HazardType.OVERHEAD_BARRIER
	hazard.lane = target_lane
	hazard.color = Color.ORANGE
	hazard.size = Vector2(48, 32)
	hazard.telegraph_time = 1.2
	return hazard

static func create_coin_pickup(target_lane: int) -> HazardData:
	var hazard = HazardData.new()
	hazard.type = HazardType.PICKUP_COIN
	hazard.lane = target_lane
	hazard.color = Color.YELLOW
	hazard.size = Vector2(32, 32)
	hazard.telegraph_time = 0.5
	return hazard

static func create_xp_pickup(target_lane: int) -> HazardData:
	var hazard = HazardData.new()
	hazard.type = HazardType.PICKUP_XP
	hazard.lane = target_lane
	hazard.color = Color.CYAN
	hazard.size = Vector2(28, 28)
	hazard.telegraph_time = 0.5
	return hazard

static func create_enemy_marker(target_lane: int, formation_id: String = "") -> HazardData:
	var hazard = HazardData.new()
	hazard.type = HazardType.ENEMY_MARKER
	hazard.lane = target_lane
	hazard.color = Color.PURPLE
	hazard.size = Vector2(40, 40)
	hazard.telegraph_time = 1.5  # Longer warning for combat encounters
	hazard.enemy_formation_id = formation_id
	return hazard

static func create_health_potion(target_lane: int) -> HazardData:
	var hazard = HazardData.new()
	hazard.type = HazardType.HEALTH_POTION
	hazard.lane = target_lane
	hazard.color = Color.MAGENTA  # Bright magenta for health potions
	hazard.size = Vector2(32, 32)
	hazard.telegraph_time = 0.5
	return hazard
