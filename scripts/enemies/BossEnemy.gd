extends EnemyAI
class_name BossEnemy

## Boss Enemy - Complex multi-phase encounters with advanced attack patterns
## Features phase transitions, multiple attack patterns, and special mechanics

signal phase_changed(old_phase: int, new_phase: int)
signal boss_enraged()
signal special_attack_triggered(attack_name: String)

# Boss-specific properties
@export var boss_tier: int = 1  # 1, 2, or 3 (final boss)
@export var phase_count: int = 3
@export var current_phase: int = 1
@export var enrage_threshold: float = 0.2  # Health percentage to trigger enrage
@export var is_enraged: bool = false

# Phase transition settings
var phase_health_thresholds: Array[float] = [0.75, 0.5, 0.25]  # Health % for phase transitions
var phase_attack_patterns: Dictionary = {}
var phase_transition_duration: float = 3.0
var is_transitioning: bool = false
var transition_timer: float = 0.0

# Special attack mechanics
var special_attack_cooldown: float = 15.0
var special_attack_timer: float = 0.0
var combo_counter: int = 0
var max_combo_length: int = 4

# Visual effects
var phase_transition_effect: Node3D
var enrage_effect: Node3D

func _ready():
	# Configure boss stats based on tier
	configure_boss_by_tier()
	
	# Set up phase-specific attack patterns
	setup_phase_patterns()
	
	# Call parent setup
	super._ready()
	
	print("BossEnemy initialized - Tier ", boss_tier, " with ", phase_count, " phases")

func configure_boss_by_tier():
	"""Configure boss stats based on tier level"""
	match boss_tier:
		1:  # Tier 1 Boss
			enemy_type = EnemyAttackSystem.EnemyType.BOSS_TIER_1
			max_health = 300.0
			attack_damage = 40.0
			movement_speed = 1.8
			attack_cooldown = 4.0
			detection_range = 15.0
			preferred_distance = 4.0
			aggression_level = 1.5
			retreat_threshold = 0.1
			special_attack_cooldown = 12.0
			
		2:  # Tier 2 Boss
			enemy_type = EnemyAttackSystem.EnemyType.BOSS_TIER_2
			max_health = 500.0
			attack_damage = 55.0
			movement_speed = 2.0
			attack_cooldown = 3.5
			detection_range = 18.0
			preferred_distance = 5.0
			aggression_level = 1.8
			retreat_threshold = 0.05
			special_attack_cooldown = 10.0
			
		3:  # Final Boss
			enemy_type = EnemyAttackSystem.EnemyType.BOSS_FINAL
			max_health = 800.0
			attack_damage = 70.0
			movement_speed = 2.2
			attack_cooldown = 3.0
			detection_range = 20.0
			preferred_distance = 6.0
			aggression_level = 2.0
			retreat_threshold = 0.0  # Never retreats
			special_attack_cooldown = 8.0
	
	current_health = max_health

func setup_phase_patterns():
	"""Set up attack patterns for each phase"""
	match boss_tier:
		1:  # Tier 1 Boss phases
			phase_attack_patterns[1] = ["boss_tier1_combo", "basic_melee_combo"]
			phase_attack_patterns[2] = ["boss_tier1_combo", "bruiser_slam"]
			phase_attack_patterns[3] = ["boss_tier1_combo", "bruiser_ground_pound"]
			
		2:  # Tier 2 Boss phases
			phase_attack_patterns[1] = ["boss_tier2_complex", "archer_triple_volley"]
			phase_attack_patterns[2] = ["boss_tier2_complex", "mage_lightning_storm"]
			phase_attack_patterns[3] = ["boss_tier2_complex", "rogue_triple_combo"]
			
		3:  # Final Boss phases
			phase_attack_patterns[1] = ["final_boss_ultimate", "boss_tier1_combo"]
			phase_attack_patterns[2] = ["final_boss_ultimate", "boss_tier2_complex"]
			phase_attack_patterns[3] = ["final_boss_ultimate", "final_boss_ultimate"]  # Double ultimate in final phase

func _physics_process(delta):
	# Update special attack timer
	special_attack_timer += delta
	
	# Handle phase transition
	if is_transitioning:
		handle_phase_transition(delta)
	else:
		# Check for phase transitions
		check_phase_transition()
		
		# Check for enrage
		check_enrage_condition()
		
		# Handle special attacks
		handle_special_attacks(delta)
	
	# Call parent physics process
	super._physics_process(delta)

func check_phase_transition():
	"""Check if boss should transition to next phase"""
	if is_transitioning or current_phase >= phase_count:
		return
	
	var health_percentage = current_health / max_health
	var next_phase = current_phase + 1
	
	if next_phase <= phase_health_thresholds.size():
		var threshold = phase_health_thresholds[next_phase - 1]
		if health_percentage <= threshold:
			start_phase_transition(next_phase)

func start_phase_transition(new_phase: int):
	"""Start transitioning to a new phase"""
	if is_transitioning:
		return
	
	var old_phase = current_phase
	current_phase = new_phase
	is_transitioning = true
	transition_timer = phase_transition_duration
	
	# Stop current attacks
	attack_system.stop_current_pattern()
	current_state = EnemyState.STUNNED
	
	# Create transition effect
	create_phase_transition_effect()
	
	# Emit signal
	phase_changed.emit(old_phase, new_phase)
	
	print("BossEnemy: Starting phase transition from ", old_phase, " to ", new_phase)

func handle_phase_transition(delta):
	"""Handle phase transition logic"""
	transition_timer -= delta
	
	# Heal slightly during transition (boss mechanic)
	var heal_amount = (max_health * 0.05) * delta / phase_transition_duration  # 5% heal over transition
	current_health = min(max_health, current_health + heal_amount)
	
	if transition_timer <= 0:
		complete_phase_transition()

func complete_phase_transition():
	"""Complete the phase transition"""
	is_transitioning = false
	transition_timer = 0.0
	current_state = EnemyState.PURSUING
	
	# Increase boss power for new phase
	increase_phase_power()
	
	# Reset special attack timer
	special_attack_timer = 0.0
	
	print("BossEnemy: Completed transition to phase ", current_phase)

func increase_phase_power():
	"""Increase boss power when entering new phase"""
	# Increase stats based on phase
	var power_multiplier = 1.0 + (current_phase - 1) * 0.2  # 20% increase per phase
	
	attack_damage *= power_multiplier
	movement_speed = min(3.0, movement_speed * 1.1)
	attack_cooldown = max(2.0, attack_cooldown * 0.9)
	aggression_level = min(2.5, aggression_level * 1.15)
	
	# Reduce special attack cooldown
	special_attack_cooldown = max(5.0, special_attack_cooldown * 0.8)

func check_enrage_condition():
	"""Check if boss should enter enrage mode"""
	if is_enraged:
		return
	
	var health_percentage = current_health / max_health
	if health_percentage <= enrage_threshold:
		enter_enrage_mode()

func enter_enrage_mode():
	"""Enter enrage mode - boss becomes much more dangerous"""
	is_enraged = true
	
	# Dramatically increase boss power
	attack_damage *= 1.5
	movement_speed = min(4.0, movement_speed * 1.3)
	attack_cooldown *= 0.6
	special_attack_cooldown *= 0.5
	aggression_level = 2.5
	
	# Create enrage effect
	create_enrage_effect()
	
	# Emit signal
	boss_enraged.emit()
	
	print("BossEnemy: ENRAGED! Boss power dramatically increased!")

func handle_special_attacks(delta):
	"""Handle special attack mechanics"""
	if special_attack_timer >= special_attack_cooldown and current_state != EnemyState.ATTACKING:
		trigger_special_attack()

func trigger_special_attack():
	"""Trigger a special boss attack"""
	special_attack_timer = 0.0
	
	var special_attack = choose_special_attack()
	if special_attack != "":
		# Force the special attack pattern
		if attack_system.start_attack_pattern(special_attack, global_position):
			current_state = EnemyState.ATTACKING
			special_attack_triggered.emit(special_attack)
			print("BossEnemy: Triggered special attack - ", special_attack)

func choose_special_attack() -> String:
	"""Choose a special attack based on current phase and conditions"""
	var available_patterns = phase_attack_patterns.get(current_phase, [])
	
	if available_patterns.is_empty():
		return ""
	
	# In enrage mode, prefer the most powerful attacks
	if is_enraged:
		for pattern in available_patterns:
			if "ultimate" in pattern or "complex" in pattern:
				return pattern
	
	# Choose based on combo counter for variety
	combo_counter = (combo_counter + 1) % max_combo_length
	var pattern_index = combo_counter % available_patterns.size()
	
	return available_patterns[pattern_index]

func choose_attack_pattern(available_patterns: Array[String]) -> String:
	"""Override attack pattern selection for boss behavior"""
	if not target_player:
		return super.choose_attack_pattern(available_patterns)
	
	# Use phase-specific patterns
	var phase_patterns = phase_attack_patterns.get(current_phase, available_patterns)
	var distance = global_position.distance_to(target_player.global_position)
	
	# In enrage mode, always use the most powerful attacks
	if is_enraged:
		for pattern in phase_patterns:
			if "ultimate" in pattern or "boss" in pattern:
				return pattern
	
	# Choose based on distance and phase
	if distance > 6.0:
		# Long range - prefer area attacks
		for pattern in phase_patterns:
			if "area" in pattern or "storm" in pattern or "ultimate" in pattern:
				return pattern
	elif distance < 3.0:
		# Close range - prefer powerful single attacks
		for pattern in phase_patterns:
			if "slam" in pattern or "combo" in pattern:
				return pattern
	
	# Default to first available phase pattern
	return phase_patterns[0] if phase_patterns.size() > 0 else super.choose_attack_pattern(available_patterns)

func execute_attacking_behavior(delta):
	"""Override attacking behavior for boss mechanics"""
	# Bosses are more mobile during attacks
	if not is_transitioning:
		velocity = velocity.move_toward(Vector3.ZERO, movement_speed * 0.5 * delta)
	else:
		velocity = Vector3.ZERO
	
	# Face the player during attack
	if target_player:
		look_at(target_player.global_position, Vector3.UP)

func take_damage(damage: float, damage_type: String = "physical"):
	"""Override damage handling for boss mechanics"""
	# Bosses have damage reduction during phase transitions
	if is_transitioning:
		damage *= 0.3  # 70% damage reduction during transition
	
	super.take_damage(damage, damage_type)
	
	# Bosses don't get interrupted as easily
	# Only interrupt on very high damage
	if damage >= max_health * 0.25:  # 25% or more damage
		interrupt_attack()

func create_phase_transition_effect():
	"""Create visual effect for phase transition"""
	var effect = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 3.0
	sphere.height = 6.0
	effect.mesh = sphere
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.GOLD
	material.emission_enabled = true
	material.emission = Color.GOLD * 2.0
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color.a = 0.7
	effect.material_override = material
	
	effect.position = global_position
	get_parent().add_child(effect)
	phase_transition_effect = effect
	
	# Animate the effect
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(effect, "rotation:y", TAU, 2.0)
	
	# Remove after transition
	var removal_tween = create_tween()
	removal_tween.tween_delay(phase_transition_duration)
	removal_tween.tween_callback(effect.queue_free)

func create_enrage_effect():
	"""Create visual effect for enrage mode"""
	var effect = MeshInstance3D.new()
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 2.0
	cylinder.bottom_radius = 2.0
	cylinder.height = 4.0
	effect.mesh = cylinder
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.RED
	material.emission_enabled = true
	material.emission = Color.RED * 3.0
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color.a = 0.5
	effect.material_override = material
	
	effect.position = global_position
	get_parent().add_child(effect)
	enrage_effect = effect
	
	# Permanent pulsing effect
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(material, "emission", Color.RED * 1.5, 0.5)
	tween.tween_property(material, "emission", Color.RED * 3.0, 0.5)

# Public API methods

func get_current_phase() -> int:
	"""Get current boss phase"""
	return current_phase

func is_in_phase_transition() -> bool:
	"""Check if boss is transitioning between phases"""
	return is_transitioning

func get_enrage_status() -> bool:
	"""Check if boss is enraged"""
	return is_enraged

func force_phase_transition(new_phase: int):
	"""Force boss to transition to specific phase (for testing)"""
	if new_phase > 0 and new_phase <= phase_count:
		start_phase_transition(new_phase)

func force_enrage():
	"""Force boss into enrage mode (for testing)"""
	if not is_enraged:
		enter_enrage_mode()

# Debug methods

func debug_boss_ai():
	"""Print debug information about boss AI"""
	debug_enemy_ai()
	print("Boss Tier: ", boss_tier)
	print("Current Phase: ", current_phase, "/", phase_count)
	print("Is Transitioning: ", is_transitioning)
	print("Is Enraged: ", is_enraged)
	print("Special Attack Timer: ", special_attack_timer, "/", special_attack_cooldown)
	print("Combo Counter: ", combo_counter)