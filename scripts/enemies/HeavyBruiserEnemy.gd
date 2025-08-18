extends EnemyAI
class_name HeavyBruiserEnemy

## Heavy Bruiser Enemy - Slow but powerful with area attacks
## Focuses on devastating attacks with long telegraphs

func _ready():
	# Set enemy type before calling parent _ready
	enemy_type = EnemyAttackSystem.EnemyType.HEAVY_BRUISER
	
	# Configure heavy bruiser stats
	max_health = 150.0
	current_health = max_health
	attack_damage = 35.0
	movement_speed = 1.2
	attack_cooldown = 6.0
	detection_range = 8.0
	preferred_distance = 3.0
	aggression_level = 1.5
	retreat_threshold = 0.15  # Very low retreat threshold - bruisers fight to the end
	
	# Call parent setup
	super._ready()
	
	print("HeavyBruiserEnemy initialized")

func choose_attack_pattern(available_patterns: Array[String]) -> String:
	"""Override attack pattern selection for heavy bruiser behavior"""
	if not target_player:
		return super.choose_attack_pattern(available_patterns)
	
	var distance = global_position.distance_to(target_player.global_position)
	var health_percentage = current_health / max_health
	
	# When player is very close, use area attacks to create space
	if distance < 2.5:
		if "bruiser_ground_pound" in available_patterns:
			return "bruiser_ground_pound"
		elif "bruiser_slam_pound_combo" in available_patterns:
			return "bruiser_slam_pound_combo"
	
	# When player is far, use bull rush to close distance
	if distance > 5.0 and "bruiser_bull_rush" in available_patterns:
		return "bruiser_bull_rush"
	
	# When at medium range and healthy, use combo attacks
	if distance >= 2.5 and distance <= 5.0 and health_percentage > 0.4:
		if "bruiser_slam_pound_combo" in available_patterns and last_attack_pattern != "bruiser_slam_pound_combo":
			return "bruiser_slam_pound_combo"
		elif last_attack_pattern == "bruiser_slam" and "bruiser_ground_pound" in available_patterns:
			return "bruiser_ground_pound"
		elif "bruiser_slam" in available_patterns:
			return "bruiser_slam"
	
	# When low on health, prefer powerful area attacks
	if health_percentage < 0.3:
		if "bruiser_slam_pound_combo" in available_patterns:
			return "bruiser_slam_pound_combo"
		elif "bruiser_ground_pound" in available_patterns:
			return "bruiser_ground_pound"
	
	# Default selection with variety
	var preferred_patterns = ["bruiser_slam", "bruiser_ground_pound", "bruiser_bull_rush"]
	for pattern in preferred_patterns:
		if pattern in available_patterns and pattern != last_attack_pattern:
			return pattern
	
	return super.choose_attack_pattern(available_patterns)

func execute_pursuing_behavior(delta):
	"""Override pursuing behavior for heavy bruiser movement"""
	if not target_player:
		return
	
	var direction = (target_player.global_position - global_position).normalized()
	var distance = global_position.distance_to(target_player.global_position)
	
	# Slow but relentless pursuit
	if distance > preferred_distance + 0.5:
		velocity = direction * movement_speed
	elif distance < preferred_distance - 0.5:
		# Don't back away much - bruisers like to be close
		velocity = -direction * movement_speed * 0.3
	else:
		# Hold position and prepare for attack
		velocity = velocity.move_toward(Vector3.ZERO, movement_speed * delta)
	
	# Face the player
	look_at(target_player.global_position, Vector3.UP)

func execute_attacking_behavior(delta):
	"""Override attacking behavior for heavy attacks"""
	# Bruisers plant themselves firmly when attacking
	velocity = Vector3.ZERO
	
	# Face the player during attack
	if target_player:
		look_at(target_player.global_position, Vector3.UP)

func execute_retreating_behavior(delta):
	"""Override retreating behavior - bruisers rarely retreat"""
	if not target_player:
		return
	
	# Even when "retreating", bruisers move slowly and reluctantly
	var direction = (global_position - target_player.global_position).normalized()
	velocity = direction * movement_speed * 0.5  # Very slow retreat
	
	# Face the player while retreating - ready to turn and fight
	look_at(target_player.global_position, Vector3.UP)
	
	# Try to attack while retreating if possible
	if attack_timer >= attack_cooldown * 0.8:
		start_attack()

func start_attack():
	"""Override attack start for bruiser-specific behavior"""
	# Bruisers take a moment to wind up their attacks
	velocity = Vector3.ZERO
	
	# Create a brief wind-up effect
	create_windup_effect()
	
	super.start_attack()

func create_windup_effect():
	"""Create visual effect for attack wind-up"""
	if visual_mesh and visual_mesh.material_override:
		var original_color = visual_mesh.material_override.albedo_color
		var windup_color = Color.RED
		
		# Flash red to indicate incoming powerful attack
		var tween = create_tween()
		tween.tween_property(visual_mesh.material_override, "albedo_color", windup_color, 0.3)
		tween.tween_property(visual_mesh.material_override, "albedo_color", original_color, 0.3)

func take_damage(damage: float, damage_type: String = "physical"):
	"""Override damage handling for bruiser behavior"""
	super.take_damage(damage, damage_type)
	
	# Bruisers become more dangerous when damaged
	if current_health < max_health * 0.5:
		# Increase aggression and reduce attack cooldown
		aggression_level = min(2.0, aggression_level + 0.1)
		attack_cooldown = max(4.0, attack_cooldown - 0.2)
		
		# Berserker mode when very low on health
		if current_health < max_health * 0.25:
			attack_cooldown = max(3.0, attack_cooldown - 0.5)
			movement_speed = min(2.0, movement_speed + 0.3)  # Slight speed boost
			
			# Visual indicator of berserker mode
			if visual_mesh and visual_mesh.material_override:
				visual_mesh.material_override.emission = Color.RED * 0.8

func interrupt_attack():
	"""Override attack interruption - bruisers are harder to interrupt"""
	# Only interrupt on very high damage (30% or more)
	var last_damage = max_health - current_health  # This is a simplification
	if last_damage >= max_health * 0.3:
		super.interrupt_attack()
	else:
		# Bruisers shrug off smaller hits and continue attacking
		print("HeavyBruiserEnemy: Shrugged off interruption attempt")