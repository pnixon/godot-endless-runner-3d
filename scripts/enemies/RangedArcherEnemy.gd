extends EnemyAI
class_name RangedArcherEnemy

## Ranged Archer Enemy - Maintains distance and uses projectile attacks
## Focuses on positioning and telegraphed arrow attacks

func _ready():
	# Set enemy type before calling parent _ready
	enemy_type = EnemyAttackSystem.EnemyType.RANGED_ARCHER
	
	# Configure ranged archer stats
	max_health = 60.0
	current_health = max_health
	attack_damage = 18.0
	movement_speed = 2.0
	attack_cooldown = 4.0
	detection_range = 10.0
	preferred_distance = 7.0
	aggression_level = 0.8
	retreat_threshold = 0.4
	
	# Call parent setup
	super._ready()
	
	print("RangedArcherEnemy initialized")

func choose_attack_pattern(available_patterns: Array[String]) -> String:
	"""Override attack pattern selection for ranged combat behavior"""
	if not target_player:
		return super.choose_attack_pattern(available_patterns)
	
	var distance = global_position.distance_to(target_player.global_position)
	var health_percentage = current_health / max_health
	
	# When player is far, use single shots for accuracy
	if distance > 8.0 and "archer_single_shot" in available_patterns:
		return "archer_single_shot"
	
	# When player is at medium range and healthy, use volleys
	if distance > 4.0 and distance <= 8.0 and health_percentage > 0.5:
		if "archer_triple_volley" in available_patterns:
			return "archer_triple_volley"
	
	# When player is close or archer is low health, panic with volleys
	if distance <= 4.0 or health_percentage < 0.3:
		if "archer_triple_volley" in available_patterns:
			return "archer_triple_volley"
	
	# Default to single shot
	if "archer_single_shot" in available_patterns:
		return "archer_single_shot"
	
	return super.choose_attack_pattern(available_patterns)

func execute_pursuing_behavior(delta):
	"""Override pursuing behavior for ranged combat positioning"""
	if not target_player:
		return
	
	var direction = (target_player.global_position - global_position).normalized()
	var distance = global_position.distance_to(target_player.global_position)
	
	# Maintain optimal range for archery
	if distance < preferred_distance - 1.0:
		# Too close - back away
		velocity = -direction * movement_speed * 1.5
	elif distance > preferred_distance + 2.0:
		# Too far - move closer but slowly
		velocity = direction * movement_speed * 0.7
	else:
		# Good range - strafe to avoid player attacks
		var perpendicular = Vector3(-direction.z, 0, direction.x)
		var strafe_direction = 1.0 if randf() > 0.5 else -1.0
		velocity = perpendicular * strafe_direction * movement_speed * 0.8
	
	# Always face the player for aiming
	look_at(target_player.global_position, Vector3.UP)

func execute_retreating_behavior(delta):
	"""Override retreating behavior for archer tactics"""
	if not target_player:
		return
	
	var direction = (global_position - target_player.global_position).normalized()
	
	# Retreat while trying to maintain line of sight
	velocity = direction * movement_speed * 1.8  # Faster retreat
	
	# Face the player while retreating (backpedaling)
	look_at(target_player.global_position, Vector3.UP)
	
	# Try to attack while retreating if cooldown is ready
	if attack_timer >= attack_cooldown * 0.7:  # Attack more frequently while retreating
		start_attack()

func start_attack():
	"""Override attack start for archer-specific behavior"""
	# Archers need to stop moving to aim properly
	velocity = Vector3.ZERO
	
	super.start_attack()

func take_damage(damage: float, damage_type: String = "physical"):
	"""Override damage handling for archer behavior"""
	super.take_damage(damage, damage_type)
	
	# Archers become more defensive when damaged
	if current_health < max_health * 0.6:
		preferred_distance = min(10.0, preferred_distance + 1.0)
		retreat_threshold = min(0.6, retreat_threshold + 0.1)
		
		# Panic mode - attack more frequently but less accurately
		if current_health < max_health * 0.3:
			attack_cooldown = max(2.0, attack_cooldown - 0.5)
			aggression_level = min(1.5, aggression_level + 0.3)