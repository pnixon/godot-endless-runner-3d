extends EnemyAI
class_name AgileRogueEnemy

## Agile Rogue Enemy - Fast movement with quick combo attacks
## Focuses on mobility and multi-hit attack sequences

var dash_cooldown: float = 5.0
var dash_timer: float = 0.0
var is_dashing: bool = false
var dash_direction: Vector3
var dash_speed: float = 8.0
var dash_duration: float = 0.5

func _ready():
	# Set enemy type before calling parent _ready
	enemy_type = EnemyAttackSystem.EnemyType.AGILE_ROGUE
	
	# Configure agile rogue stats
	max_health = 70.0
	current_health = max_health
	attack_damage = 15.0
	movement_speed = 3.5
	attack_cooldown = 2.5
	detection_range = 9.0
	preferred_distance = 1.8
	aggression_level = 1.3
	retreat_threshold = 0.35
	
	# Call parent setup
	super._ready()
	
	print("AgileRogueEnemy initialized")

func _physics_process(delta):
	# Update dash timer
	dash_timer += delta
	
	# Handle dashing movement
	if is_dashing:
		velocity = dash_direction * dash_speed
		dash_duration -= delta
		if dash_duration <= 0:
			end_dash()
	
	# Call parent physics process
	super._physics_process(delta)

func choose_attack_pattern(available_patterns: Array[String]) -> String:
	"""Override attack pattern selection for rogue behavior"""
	if not target_player:
		return super.choose_attack_pattern(available_patterns)
	
	var distance = global_position.distance_to(target_player.global_position)
	var health_percentage = current_health / max_health
	
	# When surrounded or overwhelmed, use spinning blades
	if distance <= 2.0 and health_percentage < 0.3:
		if "rogue_spinning_blades" in available_patterns:
			return "rogue_spinning_blades"
	
	# When at optimal range and healthy, use advanced combos
	if distance <= 2.5 and health_percentage > 0.5:
		if "rogue_shadow_strike_combo" in available_patterns and last_attack_pattern != "rogue_shadow_strike_combo":
			return "rogue_shadow_strike_combo"
		elif "rogue_triple_combo" in available_patterns:
			return "rogue_triple_combo"
	
	# When player is to the side, use appropriate dash attacks
	if can_dash() and distance > 2.0 and distance < 5.0:
		var player_direction = (target_player.global_position - global_position).normalized()
		var right_dot = player_direction.dot(transform.basis.x)
		
		if right_dot > 0.3:  # Player is to the right
			if "rogue_dash_right" in available_patterns:
				return "rogue_dash_right"
		elif right_dot < -0.3:  # Player is to the left
			if "rogue_dash_left" in available_patterns:
				return "rogue_dash_left"
	
	# When low on health, prefer evasive attacks
	if health_percentage < 0.4:
		if can_dash():
			var dash_patterns = ["rogue_dash_left", "rogue_dash_right"]
			for pattern in dash_patterns:
				if pattern in available_patterns:
					return pattern
		elif "rogue_spinning_blades" in available_patterns:
			return "rogue_spinning_blades"
	
	# Default selection with variety
	var preferred_patterns = ["rogue_triple_combo", "rogue_shadow_strike_combo", "rogue_dash_left", "rogue_dash_right"]
	for pattern in preferred_patterns:
		if pattern in available_patterns and pattern != last_attack_pattern:
			return pattern
	
	return super.choose_attack_pattern(available_patterns)

func execute_pursuing_behavior(delta):
	"""Override pursuing behavior for agile movement"""
	if not target_player or is_dashing:
		return
	
	var direction = (target_player.global_position - global_position).normalized()
	var distance = global_position.distance_to(target_player.global_position)
	
	# Use dash to close distance if available and player is far
	if can_dash() and distance > 4.0:
		start_dash(direction)
		return
	
	# Normal agile movement
	if distance > preferred_distance + 0.5:
		velocity = direction * movement_speed
	elif distance < preferred_distance - 0.5:
		# Quick retreat with side-stepping
		var retreat_direction = -direction
		var side_step = Vector3(-direction.z, 0, direction.x) * (1.0 if randf() > 0.5 else -1.0)
		velocity = (retreat_direction + side_step * 0.5).normalized() * movement_speed
	else:
		# Circle around player at preferred distance
		var perpendicular = Vector3(-direction.z, 0, direction.x)
		var circle_direction = 1.0 if randf() > 0.5 else -1.0
		velocity = perpendicular * circle_direction * movement_speed * 0.8
	
	# Face the player
	look_at(target_player.global_position, Vector3.UP)

func execute_attacking_behavior(delta):
	"""Override attacking behavior for mobile combat"""
	# Rogues can move slightly while attacking (not completely stationary)
	if not is_dashing:
		velocity = velocity.move_toward(Vector3.ZERO, movement_speed * 0.5 * delta)
	
	# Face the player during attack
	if target_player:
		look_at(target_player.global_position, Vector3.UP)

func execute_retreating_behavior(delta):
	"""Override retreating behavior for agile escape"""
	if not target_player:
		return
	
	var direction = (global_position - target_player.global_position).normalized()
	
	# Use dash to escape if available
	if can_dash():
		start_dash(direction)
		return
	
	# Fast retreat with evasive movement
	var side_step = Vector3(-direction.z, 0, direction.x) * sin(state_timer * 8.0) * 0.3
	velocity = (direction + side_step).normalized() * movement_speed * 1.8
	
	# Face the player while retreating
	look_at(target_player.global_position, Vector3.UP)

func can_dash() -> bool:
	"""Check if dash ability is available"""
	return dash_timer >= dash_cooldown and not is_dashing

func start_dash(direction: Vector3):
	"""Start a dash in the specified direction"""
	if not can_dash():
		return
	
	is_dashing = true
	dash_direction = direction.normalized()
	dash_duration = 0.5
	dash_timer = 0.0
	
	# Create dash effect
	create_dash_effect()
	
	print("AgileRogueEnemy: Started dash")

func end_dash():
	"""End the current dash"""
	is_dashing = false
	dash_duration = 0.0
	
	print("AgileRogueEnemy: Ended dash")

func create_dash_effect():
	"""Create visual effect for dash"""
	if visual_mesh and visual_mesh.material_override:
		# Create afterimage effect
		var afterimage = visual_mesh.duplicate()
		afterimage.material_override = visual_mesh.material_override.duplicate()
		afterimage.material_override.albedo_color.a = 0.5
		afterimage.material_override.albedo_color = Color.CYAN
		
		get_parent().add_child(afterimage)
		afterimage.global_position = global_position
		
		# Fade out afterimage
		var tween = create_tween()
		tween.tween_property(afterimage.material_override, "albedo_color:a", 0.0, 0.8)
		tween.tween_callback(afterimage.queue_free)

func start_attack():
	"""Override attack start for rogue-specific behavior"""
	# If starting a dash attack, initiate dash toward player
	if target_player and last_attack_pattern.begins_with("rogue_dash"):
		var direction = (target_player.global_position - global_position).normalized()
		start_dash(direction)
	
	super.start_attack()

func take_damage(damage: float, damage_type: String = "physical"):
	"""Override damage handling for rogue behavior"""
	super.take_damage(damage, damage_type)
	
	# Rogues become more evasive when damaged
	if current_health < max_health * 0.6:
		movement_speed = min(5.0, movement_speed + 0.3)
		dash_cooldown = max(3.0, dash_cooldown - 0.5)
		
		# Panic mode - very evasive
		if current_health < max_health * 0.3:
			attack_cooldown = max(1.5, attack_cooldown - 0.3)
			preferred_distance = max(1.0, preferred_distance - 0.3)  # Get closer for quick strikes
			
			# Visual indicator of panic mode
			if visual_mesh and visual_mesh.material_override:
				visual_mesh.material_override.emission = Color.PURPLE * 0.6

func interrupt_attack():
	"""Override attack interruption for rogue evasion"""
	super.interrupt_attack()
	
	# Rogues try to dash away when interrupted
	if can_dash() and target_player:
		var escape_direction = (global_position - target_player.global_position).normalized()
		start_dash(escape_direction)