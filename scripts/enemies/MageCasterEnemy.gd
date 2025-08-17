extends EnemyAI
class_name MageCasterEnemy

## Mage Caster Enemy - Long-range spellcaster with powerful area attacks
## Focuses on maintaining distance and casting devastating spells

var mana: float = 100.0
var max_mana: float = 100.0
var mana_regen_rate: float = 10.0  # Mana per second
var spell_costs: Dictionary = {
	"mage_fireball": 30.0,
	"mage_lightning_storm": 50.0
}

var casting_time: float = 0.0
var is_casting: bool = false
var current_spell: String = ""

func _ready():
	# Set enemy type before calling parent _ready
	enemy_type = EnemyAttackSystem.EnemyType.MAGE_CASTER
	
	# Configure mage caster stats
	max_health = 90.0
	current_health = max_health
	attack_damage = 25.0
	movement_speed = 1.5
	attack_cooldown = 7.0
	detection_range = 12.0
	preferred_distance = 9.0
	aggression_level = 1.1
	retreat_threshold = 0.5  # Mages retreat early
	
	# Initialize mana
	mana = max_mana
	
	# Call parent setup
	super._ready()
	
	print("MageCasterEnemy initialized")

func _physics_process(delta):
	# Regenerate mana
	if mana < max_mana:
		mana = min(max_mana, mana + mana_regen_rate * delta)
	
	# Handle casting
	if is_casting:
		casting_time -= delta
		if casting_time <= 0:
			complete_spell_cast()
	
	# Call parent physics process
	super._physics_process(delta)

func choose_attack_pattern(available_patterns: Array[String]) -> String:
	"""Override attack pattern selection for mage behavior"""
	if not target_player:
		return super.choose_attack_pattern(available_patterns)
	
	var distance = global_position.distance_to(target_player.global_position)
	var health_percentage = current_health / max_health
	var mana_percentage = mana / max_mana
	
	# Check mana costs and availability
	var affordable_patterns: Array[String] = []
	for pattern in available_patterns:
		if not spell_costs.has(pattern) or mana >= spell_costs[pattern]:
			affordable_patterns.append(pattern)
	
	if affordable_patterns.is_empty():
		# No mana for spells - retreat and regenerate
		return ""
	
	# When player is far and mage has high mana, use lightning storm
	if distance > 7.0 and mana_percentage > 0.6:
		if "mage_lightning_storm" in affordable_patterns:
			return "mage_lightning_storm"
	
	# When player is at medium range, use fireball
	if distance > 4.0 and distance <= 8.0:
		if "mage_fireball" in affordable_patterns:
			return "mage_fireball"
	
	# When player is close or mage is low on health, use area attacks to create space
	if distance <= 4.0 or health_percentage < 0.4:
		if "mage_lightning_storm" in affordable_patterns:
			return "mage_lightning_storm"
	
	# Default to fireball if available
	if "mage_fireball" in affordable_patterns:
		return "mage_fireball"
	
	return affordable_patterns[0] if affordable_patterns.size() > 0 else ""

func execute_pursuing_behavior(delta):
	"""Override pursuing behavior for mage positioning"""
	if not target_player or is_casting:
		return
	
	var direction = (target_player.global_position - global_position).normalized()
	var distance = global_position.distance_to(target_player.global_position)
	
	# Maintain optimal casting range
	if distance < preferred_distance - 1.0:
		# Too close - back away quickly
		velocity = -direction * movement_speed * 1.8
	elif distance > preferred_distance + 3.0:
		# Too far - move closer slowly
		velocity = direction * movement_speed * 0.6
	else:
		# Good range - maintain position with slight adjustments
		var perpendicular = Vector3(-direction.z, 0, direction.x)
		var adjustment = sin(state_timer * 2.0) * 0.3
		velocity = perpendicular * adjustment * movement_speed
	
	# Always face the player for spell targeting
	look_at(target_player.global_position, Vector3.UP)

func execute_attacking_behavior(delta):
	"""Override attacking behavior for spellcasting"""
	# Mages must remain stationary while casting
	velocity = Vector3.ZERO
	
	# Face the player during casting
	if target_player:
		look_at(target_player.global_position, Vector3.UP)
	
	# Visual casting effect
	if is_casting:
		create_casting_effect()

func execute_retreating_behavior(delta):
	"""Override retreating behavior for mage tactics"""
	if not target_player:
		return
	
	var direction = (global_position - target_player.global_position).normalized()
	
	# Retreat while maintaining line of sight for casting
	velocity = direction * movement_speed * 2.0  # Fast retreat
	
	# Face the player while retreating
	look_at(target_player.global_position, Vector3.UP)
	
	# Try to cast defensive spells while retreating
	if mana >= spell_costs.get("mage_lightning_storm", 50.0) and attack_timer >= attack_cooldown * 0.5:
		start_attack()

func start_attack():
	"""Override attack start for spellcasting behavior"""
	var pattern = choose_attack_pattern(attack_system.get_available_patterns_for_enemy_type(enemy_type))
	
	if pattern == "":
		# No mana for spells - just wait
		print("MageCasterEnemy: Not enough mana for spells")
		return
	
	# Check mana cost
	var mana_cost = spell_costs.get(pattern, 0.0)
	if mana < mana_cost:
		print("MageCasterEnemy: Not enough mana for ", pattern)
		return
	
	# Start casting
	is_casting = true
	current_spell = pattern
	casting_time = get_spell_cast_time(pattern)
	
	# Consume mana
	mana -= mana_cost
	
	# Create casting visual effect
	create_spell_windup_effect(pattern)
	
	print("MageCasterEnemy: Started casting ", pattern, " (", mana_cost, " mana)")

func get_spell_cast_time(spell: String) -> float:
	"""Get the casting time for a spell"""
	match spell:
		"mage_fireball":
			return 1.5
		"mage_lightning_storm":
			return 2.5
		_:
			return 1.0

func complete_spell_cast():
	"""Complete the spell casting and trigger the attack pattern"""
	is_casting = false
	casting_time = 0.0
	
	# Now actually start the attack pattern
	if current_spell != "":
		super.start_attack()  # This will use the stored pattern choice
		print("MageCasterEnemy: Completed casting ", current_spell)
	
	current_spell = ""

func create_casting_effect():
	"""Create visual effect while casting"""
	if visual_mesh and visual_mesh.material_override:
		# Pulsing glow effect
		var pulse = sin(Time.get_unix_time_from_system() * 8.0) * 0.3 + 0.7
		visual_mesh.material_override.emission = Color.BLUE * pulse

func create_spell_windup_effect(spell: String):
	"""Create visual effect for spell wind-up"""
	var effect_color = Color.BLUE
	
	match spell:
		"mage_fireball":
			effect_color = Color.ORANGE
		"mage_lightning_storm":
			effect_color = Color.CYAN
	
	if visual_mesh and visual_mesh.material_override:
		var original_color = visual_mesh.material_override.albedo_color
		
		# Change color during casting
		var tween = create_tween()
		tween.tween_property(visual_mesh.material_override, "albedo_color", effect_color, 0.5)
		tween.tween_property(visual_mesh.material_override, "albedo_color", original_color, 0.5)
		tween.set_loops()

func take_damage(damage: float, damage_type: String = "physical"):
	"""Override damage handling for mage behavior"""
	super.take_damage(damage, damage_type)
	
	# Interrupt casting if taking significant damage
	if is_casting and damage >= max_health * 0.15:  # 15% or more damage
		interrupt_casting()
	
	# Mages become more defensive when damaged
	if current_health < max_health * 0.7:
		preferred_distance = min(12.0, preferred_distance + 1.0)
		retreat_threshold = min(0.7, retreat_threshold + 0.1)
		
		# Panic casting when very low on health
		if current_health < max_health * 0.3:
			attack_cooldown = max(4.0, attack_cooldown - 1.0)
			mana_regen_rate = min(20.0, mana_regen_rate + 5.0)
			
			# Visual indicator of panic mode
			if visual_mesh and visual_mesh.material_override:
				visual_mesh.material_override.emission = Color.RED * 0.7

func interrupt_casting():
	"""Interrupt current spell casting"""
	if not is_casting:
		return
	
	is_casting = false
	casting_time = 0.0
	
	# Refund half the mana cost
	var mana_cost = spell_costs.get(current_spell, 0.0)
	mana = min(max_mana, mana + mana_cost * 0.5)
	
	print("MageCasterEnemy: Spell casting interrupted - ", current_spell)
	current_spell = ""
	
	# Enter stunned state briefly
	current_state = EnemyState.STUNNED
	state_timer = 0.0

func interrupt_attack():
	"""Override attack interruption for casting interruption"""
	interrupt_casting()
	super.interrupt_attack()

# Public API methods

func get_mana_percentage() -> float:
	"""Get current mana as percentage"""
	return mana / max_mana

func is_spell_casting() -> bool:
	"""Check if currently casting a spell"""
	return is_casting

func get_current_spell() -> String:
	"""Get the currently casting spell"""
	return current_spell if is_casting else ""

# Debug methods

func debug_mage_ai():
	"""Print debug information about mage AI"""
	debug_enemy_ai()
	print("Mana: ", mana, "/", max_mana)
	print("Is Casting: ", is_casting)
	print("Current Spell: ", current_spell)
	print("Casting Time: ", casting_time)