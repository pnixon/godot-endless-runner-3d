extends Node
class_name DaiAbilityLibrary

## Pre-defined Dragon Quest Dai abilities
## Includes iconic techniques from the anime/game

static func create_avan_strash() -> AbilityData:
	"""The legendary Avan Strash - powerful cross-slash technique"""
	var ability = AbilityData.new()
	ability.ability_name = "Avan Strash"
	ability.description = "Master Avan's signature technique - a powerful cross-shaped slash"
	ability.ability_type = AbilityData.AbilityType.PHYSICAL_TECHNIQUE
	ability.element = AbilityData.Element.NONE

	ability.mp_cost = 20
	ability.stamina_cost = 30.0
	ability.cooldown_time = 5.0
	ability.required_level = 5

	ability.base_damage = 80.0
	ability.damage_multiplier = 1.5
	ability.crit_chance = 0.25
	ability.crit_multiplier = 2.5

	ability.target_type = AbilityData.TargetType.AREA_CONE
	ability.max_range = 12.0
	ability.aoe_radius = 8.0

	ability.animation_name = "avan_strash"
	ability.cast_time = 0.5
	ability.execution_time = 0.8
	ability.camera_shake_intensity = 0.4

	ability.can_start_combo = true
	ability.combo_window = 1.5
	ability.next_combo_abilities = ["Avan Strash Extreme", "Gigastrash"]

	ability.can_be_upgraded = true
	ability.max_level = 5
	ability.upgrade_damage_per_level = 15.0

	ability.ability_color = Color(1.0, 0.9, 0.3)  # Golden
	return ability


static func create_air_slash() -> AbilityData:
	"""Air Slash - ranged sword wave"""
	var ability = AbilityData.new()
	ability.ability_name = "Air Slash"
	ability.description = "Launch a blade of compressed air at enemies"
	ability.ability_type = AbilityData.AbilityType.PHYSICAL_TECHNIQUE
	ability.element = AbilityData.Element.NONE

	ability.mp_cost = 10
	ability.stamina_cost = 15.0
	ability.cooldown_time = 3.0
	ability.required_level = 1

	ability.base_damage = 35.0
	ability.damage_multiplier = 1.0
	ability.crit_chance = 0.15

	ability.target_type = AbilityData.TargetType.SINGLE_ENEMY
	ability.max_range = 15.0
	ability.projectile_speed = 25.0

	ability.animation_name = "air_slash"
	ability.cast_time = 0.3
	ability.execution_time = 0.4
	ability.camera_shake_intensity = 0.2

	ability.pierces_defense = true

	ability.can_be_upgraded = true
	ability.max_level = 5
	ability.upgrade_damage_per_level = 8.0

	ability.ability_color = Color(0.7, 0.9, 1.0)  # Light blue
	return ability


static func create_bloody_scryde() -> AbilityData:
	"""Bloody Scryde - Hyunckel's dark finishing move"""
	var ability = AbilityData.new()
	ability.ability_name = "Bloody Scryde"
	ability.description = "A devastating dark energy slash that pierces everything"
	ability.ability_type = AbilityData.AbilityType.SPECIAL_FINISHER
	ability.element = AbilityData.Element.DARK

	ability.mp_cost = 50
	ability.stamina_cost = 60.0
	ability.cooldown_time = 15.0
	ability.required_level = 15

	ability.base_damage = 200.0
	ability.damage_multiplier = 2.0
	ability.crit_chance = 0.5
	ability.crit_multiplier = 3.0

	ability.target_type = AbilityData.TargetType.AREA_CONE
	ability.max_range = 20.0
	ability.aoe_radius = 10.0

	ability.animation_name = "bloody_scryde"
	ability.cast_time = 1.0
	ability.execution_time = 1.5
	ability.camera_shake_intensity = 0.8

	ability.pierces_defense = true
	ability.ignores_dodge = true
	ability.life_steal_percent = 0.3  # Heal 30% of damage

	ability.can_be_upgraded = true
	ability.max_level = 3
	ability.upgrade_damage_per_level = 40.0

	ability.ability_color = Color(0.5, 0.0, 0.5)  # Dark purple
	return ability


static func create_gira() -> AbilityData:
	"""Gira - Fire magic"""
	var ability = AbilityData.new()
	ability.ability_name = "Gira"
	ability.description = "Conjure flames to burn enemies"
	ability.ability_type = AbilityData.AbilityType.MAGIC_OFFENSIVE
	ability.element = AbilityData.Element.FIRE

	ability.mp_cost = 8
	ability.stamina_cost = 0.0
	ability.cooldown_time = 2.5
	ability.required_level = 1

	ability.base_damage = 40.0
	ability.damage_multiplier = 1.2
	ability.crit_chance = 0.1

	ability.target_type = AbilityData.TargetType.SINGLE_ENEMY
	ability.max_range = 12.0

	ability.animation_name = "gira"
	ability.cast_time = 0.4
	ability.execution_time = 0.6
	ability.camera_shake_intensity = 0.15

	ability.applies_status_effect = true
	ability.status_effect_name = "Burn"
	ability.status_effect_duration = 5.0
	ability.status_effect_chance = 0.3

	ability.can_start_combo = true
	ability.next_combo_abilities = ["Meragira", "Begirama"]

	ability.can_be_upgraded = true
	ability.max_level = 5
	ability.upgrade_damage_per_level = 10.0

	return ability


static func create_hyado() -> AbilityData:
	"""Hyado - Ice magic"""
	var ability = AbilityData.new()
	ability.ability_name = "Hyado"
	ability.description = "Freeze enemies with a blast of ice"
	ability.ability_type = AbilityData.AbilityType.MAGIC_OFFENSIVE
	ability.element = AbilityData.Element.ICE

	ability.mp_cost = 8
	ability.stamina_cost = 0.0
	ability.cooldown_time = 2.5
	ability.required_level = 1

	ability.base_damage = 35.0
	ability.damage_multiplier = 1.2
	ability.crit_chance = 0.1

	ability.target_type = AbilityData.TargetType.SINGLE_ENEMY
	ability.max_range = 12.0

	ability.animation_name = "hyado"
	ability.cast_time = 0.4
	ability.execution_time = 0.6
	ability.camera_shake_intensity = 0.15

	ability.applies_status_effect = true
	ability.status_effect_name = "Slow"
	ability.status_effect_duration = 4.0
	ability.status_effect_chance = 0.5

	ability.can_start_combo = true
	ability.next_combo_abilities = ["Mahyado", "Hyadalko"]

	ability.can_be_upgraded = true
	ability.max_level = 5
	ability.upgrade_damage_per_level = 10.0

	return ability


static func create_io() -> AbilityData:
	"""Io - Lightning magic"""
	var ability = AbilityData.new()
	ability.ability_name = "Io"
	ability.description = "Call down lightning to strike enemies"
	ability.ability_type = AbilityData.AbilityType.MAGIC_OFFENSIVE
	ability.element = AbilityData.Element.LIGHTNING

	ability.mp_cost = 12
	ability.stamina_cost = 0.0
	ability.cooldown_time = 3.0
	ability.required_level = 3

	ability.base_damage = 55.0
	ability.damage_multiplier = 1.3
	ability.crit_chance = 0.2

	ability.target_type = AbilityData.TargetType.AREA_CIRCLE
	ability.max_range = 15.0
	ability.aoe_radius = 5.0

	ability.animation_name = "io"
	ability.cast_time = 0.5
	ability.execution_time = 0.7
	ability.camera_shake_intensity = 0.3

	ability.applies_status_effect = true
	ability.status_effect_name = "Stun"
	ability.status_effect_duration = 2.0
	ability.status_effect_chance = 0.25

	ability.can_start_combo = true
	ability.next_combo_abilities = ["Giraizin", "Io Grande"]

	ability.can_be_upgraded = true
	ability.max_level = 5
	ability.upgrade_damage_per_level = 12.0

	return ability


static func create_heal() -> AbilityData:
	"""Heal - Healing magic"""
	var ability = AbilityData.new()
	ability.ability_name = "Heal"
	ability.description = "Restore health with healing magic"
	ability.ability_type = AbilityData.AbilityType.MAGIC_HEALING
	ability.element = AbilityData.Element.LIGHT

	ability.mp_cost = 15
	ability.stamina_cost = 0.0
	ability.cooldown_time = 8.0
	ability.required_level = 2

	ability.base_damage = -50.0  # Negative damage = healing
	ability.damage_multiplier = 1.0

	ability.target_type = AbilityData.TargetType.SELF
	ability.max_range = 0.0

	ability.animation_name = "heal"
	ability.cast_time = 0.6
	ability.execution_time = 0.8
	ability.camera_shake_intensity = 0.0

	ability.can_start_combo = true
	ability.next_combo_abilities = ["Behoma", "Behomara"]

	ability.can_be_upgraded = true
	ability.max_level = 5
	ability.upgrade_damage_per_level = -15.0  # More healing per level

	return ability


static func create_gigastrash() -> AbilityData:
	"""Gigastrash - Ultimate Avan Strash variant"""
	var ability = AbilityData.new()
	ability.ability_name = "Gigastrash"
	ability.description = "The ultimate evolution of Avan Strash with immense power"
	ability.ability_type = AbilityData.AbilityType.SPECIAL_FINISHER
	ability.element = AbilityData.Element.LIGHT

	ability.mp_cost = 60
	ability.stamina_cost = 80.0
	ability.cooldown_time = 20.0
	ability.required_level = 20

	ability.base_damage = 250.0
	ability.damage_multiplier = 2.5
	ability.crit_chance = 0.4
	ability.crit_multiplier = 3.0

	ability.target_type = AbilityData.TargetType.ALL_ENEMIES
	ability.max_range = 25.0
	ability.aoe_radius = 15.0

	ability.animation_name = "gigastrash"
	ability.cast_time = 1.2
	ability.execution_time = 2.0
	ability.camera_shake_intensity = 1.0

	ability.pierces_defense = true
	ability.knockback_force = 10.0

	ability.can_be_upgraded = true
	ability.max_level = 3
	ability.upgrade_damage_per_level = 50.0

	ability.ability_color = Color(1.0, 1.0, 0.8)  # Bright golden-white
	return ability


static func create_beast_king_blitz() -> AbilityData:
	"""Beast King Blitz - Crocodine's powerful punch technique"""
	var ability = AbilityData.new()
	ability.ability_name = "Beast King Blitz"
	ability.description = "A devastating bare-handed strike with explosive force"
	ability.ability_type = AbilityData.AbilityType.PHYSICAL_TECHNIQUE
	ability.element = AbilityData.Element.NONE

	ability.mp_cost = 25
	ability.stamina_cost = 40.0
	ability.cooldown_time = 7.0
	ability.required_level = 8
	ability.requires_weapon = false  # Can use without weapon

	ability.base_damage = 120.0
	ability.damage_multiplier = 1.8
	ability.crit_chance = 0.3
	ability.crit_multiplier = 2.2

	ability.target_type = AbilityData.TargetType.SINGLE_ENEMY
	ability.max_range = 5.0

	ability.animation_name = "beast_king_blitz"
	ability.cast_time = 0.4
	ability.execution_time = 0.7
	ability.camera_shake_intensity = 0.6

	ability.knockback_force = 15.0
	ability.stun_duration = 1.5

	ability.can_be_upgraded = true
	ability.max_level = 5
	ability.upgrade_damage_per_level = 20.0

	ability.ability_color = Color(0.8, 0.4, 0.0)  # Orange-brown
	return ability


static func create_twin_sword_flash() -> AbilityData:
	"""Twin Sword Flash - Rapid dual-blade strike"""
	var ability = AbilityData.new()
	ability.ability_name = "Twin Sword Flash"
	ability.description = "Lightning-fast strikes with both blades"
	ability.ability_type = AbilityData.AbilityType.COMBO_ATTACK
	ability.element = AbilityData.Element.NONE

	ability.mp_cost = 15
	ability.stamina_cost = 25.0
	ability.cooldown_time = 4.0
	ability.required_level = 6

	ability.base_damage = 30.0  # Per hit
	ability.damage_multiplier = 1.0
	ability.crit_chance = 0.2

	ability.target_type = AbilityData.TargetType.SINGLE_ENEMY
	ability.max_range = 6.0

	ability.animation_name = "twin_sword_flash"
	ability.cast_time = 0.2
	ability.execution_time = 1.0  # Multiple hits
	ability.camera_shake_intensity = 0.3

	ability.can_start_combo = true
	ability.combo_damage_bonus = 0.3

	ability.can_be_upgraded = true
	ability.max_level = 5
	ability.upgrade_damage_per_level = 7.0

	ability.ability_color = Color(0.9, 0.9, 0.9)  # Silver
	return ability


static func get_all_basic_abilities() -> Array[AbilityData]:
	"""Get a list of all basic/starter abilities"""
	var abilities: Array[AbilityData] = []
	abilities.append(create_air_slash())
	abilities.append(create_gira())
	abilities.append(create_hyado())
	abilities.append(create_heal())
	return abilities


static func get_all_advanced_abilities() -> Array[AbilityData]:
	"""Get a list of advanced abilities"""
	var abilities: Array[AbilityData] = []
	abilities.append(create_avan_strash())
	abilities.append(create_io())
	abilities.append(create_beast_king_blitz())
	abilities.append(create_twin_sword_flash())
	return abilities


static func get_all_ultimate_abilities() -> Array[AbilityData]:
	"""Get a list of ultimate/finisher abilities"""
	var abilities: Array[AbilityData] = []
	abilities.append(create_bloody_scryde())
	abilities.append(create_gigastrash())
	return abilities


static func get_ability_by_name(ability_name: String) -> AbilityData:
	"""Get a specific ability by name"""
	match ability_name:
		"Avan Strash":
			return create_avan_strash()
		"Air Slash":
			return create_air_slash()
		"Bloody Scryde":
			return create_bloody_scryde()
		"Gira":
			return create_gira()
		"Hyado":
			return create_hyado()
		"Io":
			return create_io()
		"Heal":
			return create_heal()
		"Gigastrash":
			return create_gigastrash()
		"Beast King Blitz":
			return create_beast_king_blitz()
		"Twin Sword Flash":
			return create_twin_sword_flash()
		_:
			return null


static func get_starter_loadout() -> Array[AbilityData]:
	"""Get a recommended starter ability loadout (4 skills)"""
	var abilities: Array[AbilityData] = []
	abilities.append(create_air_slash())     # Basic attack skill
	abilities.append(create_gira())          # Magic damage
	abilities.append(create_heal())          # Healing
	abilities.append(create_avan_strash())   # Powerful technique
	return abilities
