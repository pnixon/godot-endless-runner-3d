extends Resource
class_name CharacterConfig

## Character configuration for different play styles
## Defines stats, abilities, and movement characteristics

# ============================================================================
# Character Identity
# ============================================================================

@export_group("Identity")
## Character name
@export var character_name: String = "Runner"

## Character description
@export_multiline var description: String = "A balanced runner"

## Character archetype
@export_enum("Balanced", "Tank", "Speedster", "Acrobat", "Skill") var archetype: String = "Balanced"

# ============================================================================
# Health & Survival
# ============================================================================

@export_group("Health")
## Maximum health points
@export var max_health: float = 100.0

## Starting health (use -1 for max health)
@export var starting_health: float = -1.0

## Health regeneration per second (0 = none)
@export var health_regen: float = 0.0

## Damage resistance multiplier (1.0 = normal, 0.5 = half damage, 2.0 = double damage)
@export var damage_resistance: float = 1.0

## Can revive once when health reaches 0
@export var has_second_chance: bool = false

# ============================================================================
# Movement Characteristics
# ============================================================================

@export_group("Movement")
## Base movement speed multiplier
@export var speed_multiplier: float = 1.0

## Lane switch speed (higher = faster switching)
@export var lane_switch_speed: float = 25.0

## Jump power multiplier
@export var jump_power: float = 1.0

## Slide duration multiplier
@export var slide_duration: float = 1.0

## Movement cooldown between inputs (seconds)
@export var movement_cooldown: float = 0.08

## Can double jump
@export var can_double_jump: bool = false

## Can air dash
@export var can_air_dash: bool = false

# ============================================================================
# Stamina System
# ============================================================================

@export_group("Stamina")
## Enable stamina system
@export var use_stamina: bool = true

## Maximum stamina
@export var max_stamina: float = 100.0

## Stamina regeneration rate (per second)
@export var stamina_regen_rate: float = 30.0

## Jump stamina cost
@export var jump_stamina_cost: float = 20.0

## Slide stamina cost
@export var slide_stamina_cost: float = 15.0

## Dash stamina cost
@export var dash_stamina_cost: float = 25.0

# ============================================================================
# Special Abilities
# ============================================================================

@export_group("Abilities")
## Can break through obstacles
@export var can_break_obstacles: bool = false

## Magnet range multiplier for auto-collecting
@export var magnet_range: float = 1.0

## Shield duration multiplier
@export var shield_duration_multiplier: float = 1.0

## Speed boost effectiveness multiplier
@export var speed_boost_multiplier: float = 1.0

## Score multiplier (passive bonus)
@export var score_multiplier: float = 1.0

## Coin value multiplier
@export var coin_multiplier: float = 1.0

# ============================================================================
# Physics Properties
# ============================================================================

@export_group("Physics")
## Gravity multiplier (higher = faster fall)
@export var gravity_multiplier: float = 1.0

## Terminal velocity multiplier
@export var terminal_velocity_multiplier: float = 1.0

## Collision box scale
@export var collision_scale: Vector3 = Vector3.ONE

# ============================================================================
# Visual Properties
# ============================================================================

@export_group("Visual")
## Character color tint
@export var color_tint: Color = Color.WHITE

## Model scale
@export var model_scale: Vector3 = Vector3.ONE

## Trail effect color
@export var trail_color: Color = Color(0.5, 0.8, 1.0)

## Enable custom particle effects
@export var custom_particles: bool = false

# ============================================================================
# Helper Methods
# ============================================================================

func get_starting_health() -> float:
	"""Get the actual starting health value"""
	return max_health if starting_health < 0 else starting_health

func can_afford_action(stamina_cost: float, current_stamina: float) -> bool:
	"""Check if character has enough stamina for an action"""
	if not use_stamina:
		return true
	return current_stamina >= stamina_cost

func get_effective_damage(base_damage: float) -> float:
	"""Calculate effective damage after resistance"""
	return base_damage * damage_resistance

func get_effective_speed(base_speed: float) -> float:
	"""Calculate effective movement speed"""
	return base_speed * speed_multiplier

func get_effective_jump_power(base_jump: float) -> float:
	"""Calculate effective jump velocity"""
	return base_jump * jump_power

func get_magnet_radius(base_radius: float) -> float:
	"""Calculate magnet collection radius"""
	return base_radius * magnet_range

# ============================================================================
# Character Presets
# ============================================================================

static func create_balanced() -> CharacterConfig:
	"""Balanced character - good at everything"""
	var config = CharacterConfig.new()
	config.character_name = "Balanced Runner"
	config.archetype = "Balanced"
	config.description = "A well-rounded character with no weaknesses"
	# Uses default values
	return config

static func create_tank() -> CharacterConfig:
	"""Tank character - high health, slow movement"""
	var config = CharacterConfig.new()
	config.character_name = "Tank"
	config.archetype = "Tank"
	config.description = "High health and damage resistance, but slower movement"
	config.max_health = 200.0
	config.damage_resistance = 0.5  # Takes half damage
	config.speed_multiplier = 0.75
	config.lane_switch_speed = 18.0
	config.jump_power = 0.8
	config.gravity_multiplier = 1.3
	config.color_tint = Color(0.8, 0.3, 0.3)
	config.model_scale = Vector3(1.2, 1.2, 1.2)
	return config

static func create_speedster() -> CharacterConfig:
	"""Speedster character - fast movement, low health"""
	var config = CharacterConfig.new()
	config.character_name = "Speedster"
	config.archetype = "Speedster"
	config.description = "Lightning fast movement, but fragile"
	config.max_health = 75.0
	config.speed_multiplier = 1.5
	config.lane_switch_speed = 40.0
	config.movement_cooldown = 0.05
	config.speed_boost_multiplier = 1.5
	config.can_air_dash = true
	config.dash_stamina_cost = 15.0
	config.color_tint = Color(0.2, 0.6, 1.0)
	config.trail_color = Color(0.3, 0.7, 1.0)
	return config

static func create_acrobat() -> CharacterConfig:
	"""Acrobat character - excellent aerial control"""
	var config = CharacterConfig.new()
	config.character_name = "Acrobat"
	config.archetype = "Acrobat"
	config.description = "Master of aerial movement with double jump"
	config.jump_power = 1.3
	config.can_double_jump = true
	config.can_air_dash = true
	config.gravity_multiplier = 0.8
	config.jump_stamina_cost = 15.0
	config.max_stamina = 120.0
	config.stamina_regen_rate = 40.0
	config.color_tint = Color(0.3, 0.8, 0.3)
	return config

static func create_berserker() -> CharacterConfig:
	"""Berserker character - can break obstacles"""
	var config = CharacterConfig.new()
	config.character_name = "Berserker"
	config.archetype = "Tank"
	config.description = "Smashes through obstacles but takes more damage from hits"
	config.max_health = 150.0
	config.can_break_obstacles = true
	config.damage_resistance = 1.3  # Takes more damage
	config.speed_multiplier = 1.1
	config.score_multiplier = 1.25  # Bonus for risky play
	config.color_tint = Color(0.9, 0.4, 0.1)
	config.model_scale = Vector3(1.15, 1.15, 1.15)
	return config

static func create_collector() -> CharacterConfig:
	"""Collector character - bonus coin collection"""
	var config = CharacterConfig.new()
	config.character_name = "Collector"
	config.archetype = "Skill"
	config.description = "Enhanced coin collection and value"
	config.magnet_range = 2.0
	config.coin_multiplier = 2.0
	config.score_multiplier = 1.5
	config.speed_multiplier = 0.9
	config.color_tint = Color(1.0, 0.84, 0.0)
	return config

static func create_survivor() -> CharacterConfig:
	"""Survivor character - regeneration and second chance"""
	var config = CharacterConfig.new()
	config.character_name = "Survivor"
	config.archetype = "Tank"
	config.description = "Slowly regenerates health and can revive once"
	config.max_health = 120.0
	config.health_regen = 2.0  # 2 HP per second
	config.has_second_chance = true
	config.shield_duration_multiplier = 1.5
	config.damage_resistance = 0.9
	config.color_tint = Color(0.4, 0.8, 0.4)
	return config

static func create_glass_cannon() -> CharacterConfig:
	"""Glass Cannon - high score bonus, very fragile"""
	var config = CharacterConfig.new()
	config.character_name = "Glass Cannon"
	config.archetype = "Skill"
	config.description = "Massive score bonuses but extremely fragile"
	config.max_health = 50.0
	config.damage_resistance = 1.5  # Takes 50% more damage
	config.score_multiplier = 3.0
	config.coin_multiplier = 2.5
	config.speed_multiplier = 1.2
	config.color_tint = Color(0.8, 0.1, 0.8)
	return config

# ============================================================================
# Preset Registry
# ============================================================================

static func get_all_presets() -> Array[CharacterConfig]:
	"""Get all available character presets"""
	return [
		create_balanced(),
		create_tank(),
		create_speedster(),
		create_acrobat(),
		create_berserker(),
		create_collector(),
		create_survivor(),
		create_glass_cannon()
	]

static func get_preset_by_name(preset_name: String) -> CharacterConfig:
	"""Get a specific preset by name"""
	match preset_name.to_lower():
		"balanced": return create_balanced()
		"tank": return create_tank()
		"speedster": return create_speedster()
		"acrobat": return create_acrobat()
		"berserker": return create_berserker()
		"collector": return create_collector()
		"survivor": return create_survivor()
		"glass_cannon": return create_glass_cannon()
		_: return create_balanced()
