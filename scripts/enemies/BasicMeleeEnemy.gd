extends EnemyAI
class_name BasicMeleeEnemy

## Basic Melee Enemy - Simple frontal and side attacks
## Focuses on close-range combat with straightforward attack patterns

func _ready():
	# Set enemy type before calling parent _ready
	enemy_type = EnemyAttackSystem.EnemyType.BASIC_MELEE
	
	# Configure basic melee stats
	max_health = 80.0
	current_health = max_health
	attack_damage = 20.0
	movement_speed = 2.5
	attack_cooldown = 3.0
	detection_range = 6.0
	preferred_distance = 2.0
	aggression_level = 1.0
	retreat_threshold = 0.2
	
	# Call parent setup
	super._ready()
	
	print("BasicMeleeEnemy initialized")

func choose_attack_pattern(available_patterns: Array[String]) -> String:
	"""Override attack pattern selection for basic melee behavior"""
	if not target_player:
		return super.choose_attack_pattern(available_patterns)
	
	var distance = global_position.distance_to(target_player.global_position)
	var health_percentage = current_health / max_health
	
	# When low on health, prefer simple attacks
	if health_percentage < 0.4:
		if "basic_melee_simple" in available_patterns:
			return "basic_melee_simple"
	
	# When close to player, use combo attacks
	if distance < 2.5 and "basic_melee_combo" in available_patterns:
		return "basic_melee_combo"
	
	# Default to simple attack
	if "basic_melee_simple" in available_patterns:
		return "basic_melee_simple"
	
	return super.choose_attack_pattern(available_patterns)

func execute_pursuing_behavior(delta):
	"""Override pursuing behavior for aggressive melee combat"""
	if not target_player:
		return
	
	var direction = (target_player.global_position - global_position).normalized()
	var distance = global_position.distance_to(target_player.global_position)
	
	# More aggressive pursuit - get closer to player
	if distance > preferred_distance:
		velocity = direction * movement_speed * 1.2  # 20% faster pursuit
	else:
		# Circle around player when at preferred distance
		var perpendicular = Vector3(-direction.z, 0, direction.x)
		velocity = perpendicular * movement_speed * 0.5
	
	# Face the player
	look_at(target_player.global_position, Vector3.UP)

func take_damage(damage: float, damage_type: String = "physical"):
	"""Override damage handling for melee enemy behavior"""
	super.take_damage(damage, damage_type)
	
	# Become more aggressive when damaged
	if current_health < max_health * 0.5:
		aggression_level = min(2.0, aggression_level + 0.2)
		attack_cooldown = max(1.5, attack_cooldown - 0.3)
		movement_speed = min(4.0, movement_speed + 0.5)