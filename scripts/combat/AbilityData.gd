extends Resource
class_name AbilityData

## DQ Dai-inspired Ability/Technique Data Resource
## Represents special moves, magic spells, and techniques like Avan Strash, Air Slash, etc.

enum AbilityType {
	PHYSICAL_TECHNIQUE,  # Sword techniques like Avan Strash
	MAGIC_OFFENSIVE,     # Offensive magic like Gira, Hyado
	MAGIC_DEFENSIVE,     # Defensive magic like Reflect, Barrier
	MAGIC_HEALING,       # Healing spells like Heal, Behoma
	SPECIAL_FINISHER,    # Ultimate techniques like Bloody Scryde
	COMBO_ATTACK         # Multi-hit combo abilities
}

enum Element {
	NONE,
	FIRE,     # Gira, Meragira, etc.
	ICE,      # Hyado, Mahyado
	LIGHTNING, # Giraizin, Io
	LIGHT,    # Radiant-based attacks
	DARK      # Dark energy attacks
}

enum TargetType {
	SINGLE_ENEMY,
	MULTIPLE_ENEMIES,
	ALL_ENEMIES,
	SELF,
	AREA_CONE,    # Forward cone attack
	AREA_CIRCLE   # Circular AoE around player
}

# Basic Info
@export var ability_name: String = "Avan Strash"
@export_multiline var description: String = "A powerful sword technique taught by Avan"
@export var ability_type: AbilityType = AbilityType.PHYSICAL_TECHNIQUE
@export var element: Element = Element.NONE

# Costs & Requirements
@export var mp_cost: int = 10
@export var stamina_cost: float = 20.0
@export var cooldown_time: float = 3.0
@export var required_level: int = 1
@export var requires_weapon: bool = true

# Damage & Effects
@export var base_damage: float = 50.0
@export var damage_multiplier: float = 1.0  # Scales with player level/stats
@export var crit_chance: float = 0.1  # 10% crit chance
@export var crit_multiplier: float = 2.0

# Targeting
@export var target_type: TargetType = TargetType.SINGLE_ENEMY
@export var max_range: float = 10.0
@export var aoe_radius: float = 0.0  # For area attacks
@export var projectile_speed: float = 20.0  # For ranged abilities

# Animation & Visual
@export var animation_name: String = "avan_strash"
@export var cast_time: float = 0.3  # Wind-up time
@export var execution_time: float = 0.5  # Time to complete
@export var particle_effect_path: String = ""
@export var sound_effect_path: String = ""
@export var camera_shake_intensity: float = 0.2

# Status Effects
@export var applies_status_effect: bool = false
@export var status_effect_name: String = ""
@export var status_effect_duration: float = 0.0
@export var status_effect_chance: float = 0.0

# Combo System
@export var can_start_combo: bool = false
@export var combo_window: float = 1.0  # Time window to chain next ability
@export var combo_damage_bonus: float = 0.2  # 20% more damage in combo
@export var next_combo_abilities: Array[String] = []  # Ability names that can follow

# Progression
@export var can_be_upgraded: bool = true
@export var max_level: int = 5
@export var upgrade_damage_per_level: float = 10.0
@export var upgrade_mp_cost_reduction_per_level: float = 1.0

# Special Properties
@export var pierces_defense: bool = false
@export var ignores_dodge: bool = false
@export var life_steal_percent: float = 0.0  # Restore HP based on damage dealt
@export var knockback_force: float = 0.0
@export var stun_duration: float = 0.0

# Visual Indicator
@export var ability_icon_path: String = ""
@export var ability_color: Color = Color.WHITE

# Internal tracking
var current_level: int = 1
var is_unlocked: bool = false


func get_actual_damage() -> float:
	"""Calculate actual damage including level upgrades"""
	var damage = base_damage + (upgrade_damage_per_level * (current_level - 1))
	return damage * damage_multiplier


func get_actual_mp_cost() -> int:
	"""Calculate actual MP cost including level reductions"""
	var cost = mp_cost - int(upgrade_mp_cost_reduction_per_level * (current_level - 1))
	return max(1, cost)  # Minimum 1 MP


func can_use(player_mp: int, player_stamina: float, player_level: int) -> bool:
	"""Check if player can use this ability"""
	if not is_unlocked:
		return false
	if player_level < required_level:
		return false
	if player_mp < get_actual_mp_cost():
		return false
	if player_stamina < stamina_cost:
		return false
	return true


func upgrade_ability() -> bool:
	"""Upgrade ability to next level"""
	if current_level >= max_level or not can_be_upgraded:
		return false
	current_level += 1
	return true


func get_element_color() -> Color:
	"""Get color based on element for visual effects"""
	match element:
		Element.FIRE:
			return Color(1.0, 0.3, 0.0)  # Orange-red
		Element.ICE:
			return Color(0.3, 0.7, 1.0)  # Light blue
		Element.LIGHTNING:
			return Color(1.0, 1.0, 0.3)  # Yellow
		Element.LIGHT:
			return Color(1.0, 1.0, 0.9)  # Bright white
		Element.DARK:
			return Color(0.5, 0.0, 0.5)  # Purple
		_:
			return ability_color
