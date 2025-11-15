extends Node
class_name DaiCombatController

## Dragon Quest Dai: A Hero's Bonds Combat System
## Handles auto-attacks, skill charging, team management, and boss mechanics

signal skill_charged(skill_index: int)
signal skill_activated(skill_index: int, skill_name: String)
signal auto_attack_hit(target: Node3D, damage: float)
signal boss_staggered(boss: Node3D)
signal break_mode_activated(boss: Node3D)
signal vulnerability_window_opened(boss: Node3D)

enum CombatState {
	IDLE,
	AUTO_ATTACKING,
	SKILL_CASTING,
	DODGING,
	BLOCKING,
	STUNNED
}

# Team Configuration
const MAX_PARTY_SIZE = 4
const ACTIVE_HEROES = 2
const SUPPORT_HEROES = 2

# Auto-attack settings
@export var auto_attack_enabled: bool = true
@export var auto_attack_interval: float = 1.0  # Attack every 1 second
@export var auto_attack_range: float = 5.0
@export var auto_attack_damage: float = 15.0

# Skill system
@export var max_skills: int = 4
@export var skill_charge_rate: float = 1.0  # Charges per second
@export var skill_charge_on_hit: float = 5.0  # Charge gained per auto-attack hit
@export var skill_charge_on_damaged: float = 10.0  # Charge when taking damage

# Boss mechanics
@export var stagger_threshold: float = 3.0  # Successful hits needed to stagger
@export var break_mode_stagger_count: int = 3  # Staggers needed for break mode
@export var vulnerability_window_duration: float = 3.0
@export var break_mode_duration: float = 5.0
@export var break_mode_damage_multiplier: float = 2.0

# State
var combat_state: CombatState = CombatState.IDLE
var current_target: Node3D = null
var party_members: Array[Node3D] = []
var active_heroes: Array[Node3D] = []
var support_heroes: Array[Node3D] = []

# Skill tracking
var skills: Array[AbilityData] = []
var skill_charges: Array[float] = []  # 0-100 charge per skill
var skill_cooldowns: Array[float] = []  # Remaining cooldown time
var skill_max_charges: Array[float] = []  # Max charge needed (usually 100)

# Auto-attack tracking
var auto_attack_timer: float = 0.0
var can_auto_attack: bool = true

# Boss mechanics tracking
var current_boss: Node3D = null
var boss_hit_count: int = 0
var boss_stagger_count: int = 0
var is_boss_vulnerable: bool = false
var is_break_mode: bool = false
var vulnerability_timer: float = 0.0
var break_mode_timer: float = 0.0

# References
var player: Node3D
var combat_feedback: Node


func _ready() -> void:
	# Initialize skill arrays
	for i in range(max_skills):
		skill_charges.append(0.0)
		skill_cooldowns.append(0.0)
		skill_max_charges.append(100.0)


func _process(delta: float) -> void:
	if not player:
		return

	# Update auto-attack
	if auto_attack_enabled and combat_state != CombatState.STUNNED:
		_process_auto_attack(delta)

	# Charge skills over time
	_process_skill_charging(delta)

	# Update skill cooldowns
	_process_skill_cooldowns(delta)

	# Update boss mechanics
	_process_boss_mechanics(delta)


func _process_auto_attack(delta: float) -> void:
	"""Handle automatic attacks on nearby enemies"""
	auto_attack_timer += delta

	if auto_attack_timer >= auto_attack_interval and can_auto_attack:
		# Find nearest enemy
		var nearest_enemy = _find_nearest_enemy()

		if nearest_enemy and _is_in_auto_attack_range(nearest_enemy):
			_perform_auto_attack(nearest_enemy)
			auto_attack_timer = 0.0


func _perform_auto_attack(target: Node3D) -> void:
	"""Execute an auto-attack on the target"""
	if not target:
		return

	var damage = auto_attack_damage

	# Apply damage multiplier if in break mode
	if is_break_mode and target == current_boss:
		damage *= break_mode_damage_multiplier

	# Deal damage
	if target.has_method("take_damage"):
		target.take_damage(damage)

	# Charge skills on hit
	_add_skill_charge_all(skill_charge_on_hit)

	# Track boss hits
	if target == current_boss:
		_register_boss_hit()

	# Visual feedback
	if combat_feedback and combat_feedback.has_method("show_auto_attack_effect"):
		combat_feedback.show_auto_attack_effect(player.global_position, target.global_position)

	emit_signal("auto_attack_hit", target, damage)


func _find_nearest_enemy() -> Node3D:
	"""Find the closest enemy in range"""
	var enemies = get_tree().get_nodes_in_group("enemies")
	var nearest: Node3D = null
	var nearest_distance: float = INF

	for enemy in enemies:
		if not enemy is Node3D:
			continue

		var distance = player.global_position.distance_to(enemy.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = enemy

	return nearest


func _is_in_auto_attack_range(target: Node3D) -> bool:
	"""Check if target is within auto-attack range"""
	if not target or not player:
		return false

	var distance = player.global_position.distance_to(target.global_position)
	return distance <= auto_attack_range


func _process_skill_charging(delta: float) -> void:
	"""Passively charge all skills over time"""
	for i in range(skills.size()):
		if skill_charges[i] < skill_max_charges[i] and skill_cooldowns[i] <= 0:
			skill_charges[i] += skill_charge_rate * delta
			skill_charges[i] = min(skill_charges[i], skill_max_charges[i])

			# Emit signal when skill becomes fully charged
			if skill_charges[i] >= skill_max_charges[i]:
				emit_signal("skill_charged", i)


func _process_skill_cooldowns(delta: float) -> void:
	"""Update skill cooldown timers"""
	for i in range(skill_cooldowns.size()):
		if skill_cooldowns[i] > 0:
			skill_cooldowns[i] -= delta
			skill_cooldowns[i] = max(0, skill_cooldowns[i])


func _add_skill_charge_all(amount: float) -> void:
	"""Add charge to all skills"""
	for i in range(skills.size()):
		if skill_charges[i] < skill_max_charges[i]:
			skill_charges[i] += amount
			skill_charges[i] = min(skill_charges[i], skill_max_charges[i])

			# Emit signal when skill becomes fully charged
			if skill_charges[i] >= skill_max_charges[i]:
				emit_signal("skill_charged", i)


func add_skill_charge_on_damage(damage_taken: float) -> void:
	"""Called when player takes damage - charges skills"""
	var charge_amount = skill_charge_on_damaged * (damage_taken / 20.0)  # Scale with damage
	_add_skill_charge_all(charge_amount)


func activate_skill(skill_index: int) -> bool:
	"""Manually activate a skill (called by player input)"""
	if skill_index < 0 or skill_index >= skills.size():
		return false

	var skill = skills[skill_index]
	if not skill:
		return false

	# Check if skill is ready
	if skill_charges[skill_index] < skill_max_charges[skill_index]:
		return false  # Not fully charged

	if skill_cooldowns[skill_index] > 0:
		return false  # Still on cooldown

	# Check if we can use it (MP, stamina, etc.)
	if player.has_method("get_current_mp"):
		var current_mp = player.get_current_mp()
		if current_mp < skill.get_actual_mp_cost():
			return false

	# Execute the skill
	_execute_skill(skill_index, skill)

	# Reset charge and start cooldown
	skill_charges[skill_index] = 0.0
	skill_cooldowns[skill_index] = skill.cooldown_time

	emit_signal("skill_activated", skill_index, skill.ability_name)
	return true


func _execute_skill(skill_index: int, skill: AbilityData) -> void:
	"""Execute the skill effect"""
	combat_state = CombatState.SKILL_CASTING

	# Deduct MP/stamina
	if player.has_method("consume_mp"):
		player.consume_mp(skill.get_actual_mp_cost())

	if player.has_method("consume_stamina"):
		player.consume_stamina(skill.stamina_cost)

	# Find targets based on skill type
	var targets = _find_skill_targets(skill)

	# Deal damage to all targets
	for target in targets:
		if target and target.has_method("take_damage"):
			var damage = skill.get_actual_damage()

			# Apply break mode bonus
			if is_break_mode and target == current_boss:
				damage *= break_mode_damage_multiplier

			# Check for crit
			if randf() < skill.crit_chance:
				damage *= skill.crit_multiplier

			target.take_damage(damage)

			# Track boss hits for stagger
			if target == current_boss and is_boss_vulnerable:
				_register_boss_hit()

	# Visual/audio feedback
	if combat_feedback:
		if combat_feedback.has_method("show_skill_effect"):
			combat_feedback.show_skill_effect(skill, player.global_position, targets)

	# Return to normal state after cast time
	await get_tree().create_timer(skill.execution_time).timeout
	combat_state = CombatState.IDLE


func _find_skill_targets(skill: AbilityData) -> Array:
	"""Find valid targets for the skill"""
	var targets = []
	var enemies = get_tree().get_nodes_in_group("enemies")

	match skill.target_type:
		AbilityData.TargetType.SINGLE_ENEMY:
			var nearest = _find_nearest_enemy()
			if nearest:
				targets.append(nearest)

		AbilityData.TargetType.MULTIPLE_ENEMIES:
			# Get 2-3 nearest enemies
			var sorted_enemies = _get_enemies_by_distance()
			for i in range(min(3, sorted_enemies.size())):
				targets.append(sorted_enemies[i])

		AbilityData.TargetType.ALL_ENEMIES:
			targets = enemies.duplicate()

		AbilityData.TargetType.AREA_CONE:
			# Enemies in front cone
			for enemy in enemies:
				if _is_in_cone(enemy, skill.aoe_radius):
					targets.append(enemy)

		AbilityData.TargetType.AREA_CIRCLE:
			# Enemies in radius around player
			for enemy in enemies:
				if player.global_position.distance_to(enemy.global_position) <= skill.aoe_radius:
					targets.append(enemy)

	return targets


func _get_enemies_by_distance() -> Array:
	"""Get all enemies sorted by distance to player"""
	var enemies = get_tree().get_nodes_in_group("enemies")
	var enemy_distances = []

	for enemy in enemies:
		if enemy is Node3D:
			var distance = player.global_position.distance_to(enemy.global_position)
			enemy_distances.append({"enemy": enemy, "distance": distance})

	enemy_distances.sort_custom(func(a, b): return a.distance < b.distance)

	var sorted_enemies = []
	for entry in enemy_distances:
		sorted_enemies.append(entry.enemy)

	return sorted_enemies


func _is_in_cone(enemy: Node3D, radius: float) -> bool:
	"""Check if enemy is in a forward cone"""
	if not enemy or not player:
		return false

	var to_enemy = (enemy.global_position - player.global_position).normalized()
	var forward = -player.global_transform.basis.z  # Forward direction

	var dot = to_enemy.dot(forward)
	var distance = player.global_position.distance_to(enemy.global_position)

	return dot > 0.5 and distance <= radius  # 60 degree cone


## Boss Mechanics

func set_current_boss(boss: Node3D) -> void:
	"""Set the current boss for special mechanics"""
	current_boss = boss
	boss_hit_count = 0
	boss_stagger_count = 0
	is_boss_vulnerable = false
	is_break_mode = false


func _process_boss_mechanics(delta: float) -> void:
	"""Update boss-specific mechanics"""
	if not current_boss:
		return

	# Update vulnerability window
	if is_boss_vulnerable:
		vulnerability_timer -= delta
		if vulnerability_timer <= 0:
			_end_vulnerability_window()

	# Update break mode
	if is_break_mode:
		break_mode_timer -= delta
		if break_mode_timer <= 0:
			_end_break_mode()


func _register_boss_hit() -> void:
	"""Called when boss is hit during vulnerability window"""
	if not is_boss_vulnerable:
		return

	boss_hit_count += 1

	# Check for stagger
	if boss_hit_count >= stagger_threshold:
		_trigger_boss_stagger()


func _trigger_boss_stagger() -> void:
	"""Stagger the boss"""
	boss_hit_count = 0
	boss_stagger_count += 1

	if current_boss.has_method("apply_stagger"):
		current_boss.apply_stagger()

	emit_signal("boss_staggered", current_boss)

	# Check for break mode
	if boss_stagger_count >= break_mode_stagger_count:
		_activate_break_mode()


func _activate_break_mode() -> void:
	"""Activate break mode - massive damage window"""
	is_break_mode = true
	break_mode_timer = break_mode_duration
	boss_stagger_count = 0

	if current_boss.has_method("enter_break_mode"):
		current_boss.enter_break_mode(break_mode_duration)

	emit_signal("break_mode_activated", current_boss)


func _end_break_mode() -> void:
	"""End break mode"""
	is_break_mode = false

	if current_boss and current_boss.has_method("exit_break_mode"):
		current_boss.exit_break_mode()


func open_vulnerability_window() -> void:
	"""Called when boss enters vulnerability state"""
	is_boss_vulnerable = true
	vulnerability_timer = vulnerability_window_duration
	boss_hit_count = 0

	emit_signal("vulnerability_window_opened", current_boss)


func _end_vulnerability_window() -> void:
	"""Close the vulnerability window"""
	is_boss_vulnerable = false
	boss_hit_count = 0


## Party Management

func add_party_member(hero: Node3D) -> bool:
	"""Add a hero to the party"""
	if party_members.size() >= MAX_PARTY_SIZE:
		return false

	party_members.append(hero)
	_update_party_formation()
	return true


func remove_party_member(hero: Node3D) -> bool:
	"""Remove a hero from the party"""
	var index = party_members.find(hero)
	if index == -1:
		return false

	party_members.remove_at(index)
	_update_party_formation()
	return true


func swap_active_hero(active_index: int, party_index: int) -> bool:
	"""Swap an active hero with a support hero"""
	if active_index >= ACTIVE_HEROES or party_index >= party_members.size():
		return false

	# Swap heroes
	var temp = active_heroes[active_index]
	active_heroes[active_index] = party_members[party_index]
	party_members[party_index] = temp

	_update_party_formation()
	return true


func _update_party_formation() -> void:
	"""Update active and support hero arrays"""
	active_heroes.clear()
	support_heroes.clear()

	for i in range(party_members.size()):
		if i < ACTIVE_HEROES:
			active_heroes.append(party_members[i])
		else:
			support_heroes.append(party_members[i])


## Skill Management

func equip_skill(skill: AbilityData, slot_index: int) -> bool:
	"""Equip a skill to a slot"""
	if slot_index < 0 or slot_index >= max_skills:
		return false

	# Ensure arrays are large enough
	while skills.size() <= slot_index:
		skills.append(null)

	skills[slot_index] = skill
	skill.is_unlocked = true
	return true


func unequip_skill(slot_index: int) -> bool:
	"""Remove a skill from a slot"""
	if slot_index < 0 or slot_index >= skills.size():
		return false

	skills[slot_index] = null
	skill_charges[slot_index] = 0.0
	return true


func get_skill_charge_percent(skill_index: int) -> float:
	"""Get skill charge as percentage (0-100)"""
	if skill_index < 0 or skill_index >= skill_charges.size():
		return 0.0

	return (skill_charges[skill_index] / skill_max_charges[skill_index]) * 100.0


func is_skill_ready(skill_index: int) -> bool:
	"""Check if skill is fully charged and ready"""
	if skill_index < 0 or skill_index >= skill_charges.size():
		return false

	return skill_charges[skill_index] >= skill_max_charges[skill_index] and skill_cooldowns[skill_index] <= 0
