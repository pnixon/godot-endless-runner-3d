extends CharacterBody3D
class_name EnemyAI

## Base Enemy AI class with attack pattern integration
## Manages enemy behavior, health, and attack pattern execution

signal enemy_died(enemy: EnemyAI)
signal attack_pattern_triggered(pattern_id: String)
signal health_changed(current_health: float, max_health: float)

# Enemy properties
@export var enemy_type: EnemyAttackSystem.EnemyType = EnemyAttackSystem.EnemyType.BASIC_MELEE
@export var max_health: float = 100.0
@export var current_health: float = 100.0
@export var attack_damage: float = 20.0
@export var movement_speed: float = 2.0
@export var attack_cooldown: float = 3.0
@export var detection_range: float = 8.0

# AI behavior settings
@export var aggression_level: float = 1.0  # 0.0 to 2.0, affects attack frequency
@export var preferred_distance: float = 3.0  # Preferred distance from player
@export var retreat_threshold: float = 0.3  # Health percentage to start retreating

# Internal state
var current_state: EnemyState = EnemyState.IDLE
var target_player: RPGPlayer3D
var attack_timer: float = 0.0
var state_timer: float = 0.0
var last_attack_pattern: String = ""
var retreat_position: Vector3

# Components
var attack_system: EnemyAttackSystem
var health_bar: ProgressBar
var visual_mesh: MeshInstance3D
var collision_shape: CollisionShape3D

# Visual effects
var damage_effect_scene: PackedScene
var death_effect_scene: PackedScene

enum EnemyState {
	IDLE,
	PURSUING,
	ATTACKING,
	RETREATING,
	STUNNED,
	DEAD
}

func _ready():
	# Initialize health
	current_health = max_health
	
	# Set up collision layers
	collision_layer = 4  # Enemies on layer 4
	collision_mask = 2   # Detect player on layer 2
	
	# Find player reference
	target_player = get_tree().get_first_node_in_group("rpg_player") as RPGPlayer3D
	
	# Set up attack system
	setup_attack_system()
	
	# Set up visual components
	setup_visual_components()
	
	# Set up health bar
	setup_health_bar()
	
	# Initialize AI behavior
	initialize_ai_behavior()
	
	print("EnemyAI initialized: ", enemy_type, " with ", max_health, " health")

func setup_attack_system():
	"""Set up the enemy attack system"""
	attack_system = EnemyAttackSystem.new()
	attack_system.name = "AttackSystem"
	add_child(attack_system)
	
	# Connect attack system signals
	attack_system.attack_pattern_started.connect(_on_attack_pattern_started)
	attack_system.attack_pattern_completed.connect(_on_attack_pattern_completed)
	attack_system.attack_executed.connect(_on_attack_executed)

func setup_visual_components():
	"""Set up visual mesh and collision shape"""
	# Create collision shape
	collision_shape = CollisionShape3D.new()
	collision_shape.name = "CollisionShape3D"
	var shape = CapsuleShape3D.new()
	shape.height = 2.0
	shape.radius = 0.5
	collision_shape.shape = shape
	add_child(collision_shape)
	
	# Create visual mesh
	visual_mesh = MeshInstance3D.new()
	visual_mesh.name = "VisualMesh"
	add_child(visual_mesh)
	
	# Set mesh based on enemy type
	var mesh: Mesh
	var material = StandardMaterial3D.new()
	
	match enemy_type:
		EnemyAttackSystem.EnemyType.BASIC_MELEE:
			mesh = CapsuleMesh.new()
			(mesh as CapsuleMesh).height = 2.0
			(mesh as CapsuleMesh).radius = 0.4
			material.albedo_color = Color.RED
		EnemyAttackSystem.EnemyType.RANGED_ARCHER:
			mesh = BoxMesh.new()
			(mesh as BoxMesh).size = Vector3(0.8, 1.8, 0.8)
			material.albedo_color = Color.GREEN
		EnemyAttackSystem.EnemyType.HEAVY_BRUISER:
			mesh = BoxMesh.new()
			(mesh as BoxMesh).size = Vector3(1.2, 2.2, 1.2)
			material.albedo_color = Color.ORANGE
		EnemyAttackSystem.EnemyType.AGILE_ROGUE:
			mesh = CapsuleMesh.new()
			(mesh as CapsuleMesh).height = 1.6
			(mesh as CapsuleMesh).radius = 0.3
			material.albedo_color = Color.PURPLE
		EnemyAttackSystem.EnemyType.MAGE_CASTER:
			mesh = CylinderMesh.new()
			(mesh as CylinderMesh).height = 1.8
			(mesh as CylinderMesh).top_radius = 0.4
			(mesh as CylinderMesh).bottom_radius = 0.4
			material.albedo_color = Color.BLUE
		_:
			mesh = CapsuleMesh.new()
			material.albedo_color = Color.GRAY
	
	# Add emission for visibility
	material.emission_enabled = true
	material.emission = material.albedo_color * 0.3
	
	visual_mesh.mesh = mesh
	visual_mesh.material_override = material

func setup_health_bar():
	"""Set up floating health bar above enemy"""
	# Create a Control node for UI
	var ui_container = Control.new()
	ui_container.name = "UIContainer"
	
	# Create health bar
	health_bar = ProgressBar.new()
	health_bar.size = Vector2(60, 8)
	health_bar.position = Vector2(-30, -40)  # Center above enemy
	health_bar.max_value = max_health
	health_bar.value = current_health
	health_bar.show_percentage = false
	
	# Style the health bar
	var style_bg = StyleBoxFlat.new()
	style_bg.bg_color = Color.BLACK
	style_bg.border_width_left = 1
	style_bg.border_width_right = 1
	style_bg.border_width_top = 1
	style_bg.border_width_bottom = 1
	style_bg.border_color = Color.WHITE
	
	var style_fg = StyleBoxFlat.new()
	style_fg.bg_color = Color.RED
	
	health_bar.add_theme_stylebox_override("background", style_bg)
	health_bar.add_theme_stylebox_override("fill", style_fg)
	
	ui_container.add_child(health_bar)
	add_child(ui_container)

func initialize_ai_behavior():
	"""Initialize AI behavior based on enemy type"""
	match enemy_type:
		EnemyAttackSystem.EnemyType.BASIC_MELEE:
			attack_cooldown = 3.0
			movement_speed = 2.0
			preferred_distance = 2.0
		EnemyAttackSystem.EnemyType.RANGED_ARCHER:
			attack_cooldown = 4.0
			movement_speed = 1.5
			preferred_distance = 6.0
		EnemyAttackSystem.EnemyType.HEAVY_BRUISER:
			attack_cooldown = 5.0
			movement_speed = 1.0
			preferred_distance = 2.5
		EnemyAttackSystem.EnemyType.AGILE_ROGUE:
			attack_cooldown = 2.0
			movement_speed = 3.0
			preferred_distance = 1.5
		EnemyAttackSystem.EnemyType.MAGE_CASTER:
			attack_cooldown = 6.0
			movement_speed = 1.2
			preferred_distance = 8.0

func _physics_process(delta):
	if current_state == EnemyState.DEAD:
		return
	
	update_ai_state(delta)
	execute_current_state(delta)
	update_timers(delta)
	move_and_slide()

func update_timers(delta):
	"""Update internal timers"""
	attack_timer += delta
	state_timer += delta

func update_ai_state(delta):
	"""Update AI state based on conditions"""
	if not target_player or not is_instance_valid(target_player):
		current_state = EnemyState.IDLE
		return
	
	var distance_to_player = global_position.distance_to(target_player.global_position)
	var health_percentage = current_health / max_health
	
	# Check for retreat condition
	if health_percentage <= retreat_threshold and current_state != EnemyState.RETREATING:
		start_retreating()
		return
	
	# State transitions based on distance and conditions
	match current_state:
		EnemyState.IDLE:
			if distance_to_player <= detection_range:
				current_state = EnemyState.PURSUING
				state_timer = 0.0
		
		EnemyState.PURSUING:
			if distance_to_player <= preferred_distance and attack_timer >= attack_cooldown:
				start_attack()
			elif distance_to_player > detection_range * 1.5:
				current_state = EnemyState.IDLE
				state_timer = 0.0
		
		EnemyState.ATTACKING:
			# Attacking state is managed by attack pattern completion
			pass
		
		EnemyState.RETREATING:
			if health_percentage > retreat_threshold + 0.1:  # Hysteresis
				current_state = EnemyState.PURSUING
				state_timer = 0.0
		
		EnemyState.STUNNED:
			if state_timer >= 2.0:  # Stun duration
				current_state = EnemyState.PURSUING
				state_timer = 0.0

func execute_current_state(delta):
	"""Execute behavior for current AI state"""
	match current_state:
		EnemyState.IDLE:
			execute_idle_behavior(delta)
		EnemyState.PURSUING:
			execute_pursuing_behavior(delta)
		EnemyState.ATTACKING:
			execute_attacking_behavior(delta)
		EnemyState.RETREATING:
			execute_retreating_behavior(delta)
		EnemyState.STUNNED:
			execute_stunned_behavior(delta)

func execute_idle_behavior(delta):
	"""Execute idle behavior - minimal movement"""
	velocity = velocity.move_toward(Vector3.ZERO, movement_speed * delta)

func execute_pursuing_behavior(delta):
	"""Execute pursuing behavior - move toward player"""
	if not target_player:
		return
	
	var direction = (target_player.global_position - global_position).normalized()
	var distance = global_position.distance_to(target_player.global_position)
	
	# Maintain preferred distance
	if distance > preferred_distance + 0.5:
		velocity = direction * movement_speed
	elif distance < preferred_distance - 0.5:
		velocity = -direction * movement_speed * 0.5
	else:
		velocity = velocity.move_toward(Vector3.ZERO, movement_speed * delta)
	
	# Face the player
	look_at(target_player.global_position, Vector3.UP)

func execute_attacking_behavior(delta):
	"""Execute attacking behavior - stay in position while attacking"""
	velocity = velocity.move_toward(Vector3.ZERO, movement_speed * 2.0 * delta)
	
	# Face the player during attack
	if target_player:
		look_at(target_player.global_position, Vector3.UP)

func execute_retreating_behavior(delta):
	"""Execute retreating behavior - move away from player"""
	if not target_player:
		return
	
	var direction = (global_position - target_player.global_position).normalized()
	velocity = direction * movement_speed * 1.5  # Move faster when retreating
	
	# Face the player while retreating
	look_at(target_player.global_position, Vector3.UP)

func execute_stunned_behavior(delta):
	"""Execute stunned behavior - no movement"""
	velocity = velocity.move_toward(Vector3.ZERO, movement_speed * 3.0 * delta)

func start_attack():
	"""Start an attack sequence"""
	if current_state == EnemyState.ATTACKING:
		return
	
	current_state = EnemyState.ATTACKING
	attack_timer = 0.0
	state_timer = 0.0
	
	# Choose attack pattern based on enemy type and aggression
	var available_patterns = attack_system.get_available_patterns_for_enemy_type(enemy_type)
	if available_patterns.size() > 0:
		var pattern_id = choose_attack_pattern(available_patterns)
		print("EnemyAI: Starting attack pattern '", pattern_id, "' at position ", global_position)
		attack_system.start_attack_pattern(pattern_id, global_position)
		last_attack_pattern = pattern_id
		attack_pattern_triggered.emit(pattern_id)
	else:
		print("EnemyAI: No available attack patterns for enemy type ", enemy_type)

func choose_attack_pattern(available_patterns: Array[String]) -> String:
	"""Choose an attack pattern based on AI logic"""
	# Basic implementation - random selection with some logic
	var filtered_patterns = available_patterns.duplicate()
	
	# Avoid repeating the same pattern immediately
	if last_attack_pattern != "" and filtered_patterns.size() > 1:
		filtered_patterns.erase(last_attack_pattern)
	
	# Choose based on aggression level and distance
	if target_player:
		var distance = global_position.distance_to(target_player.global_position)
		
		# Prefer area attacks when player is close and aggression is high
		if distance < 3.0 and aggression_level > 1.5:
			for pattern in filtered_patterns:
				if "area" in pattern or "ground_pound" in pattern:
					return pattern
		
		# Prefer ranged attacks when player is far
		if distance > 5.0:
			for pattern in filtered_patterns:
				if "shot" in pattern or "fireball" in pattern:
					return pattern
	
	# Default to random selection
	return filtered_patterns[randi() % filtered_patterns.size()]

func start_retreating():
	"""Start retreating behavior"""
	current_state = EnemyState.RETREATING
	state_timer = 0.0
	
	# Calculate retreat position (away from player)
	if target_player:
		var direction = (global_position - target_player.global_position).normalized()
		retreat_position = global_position + direction * 5.0

func take_damage(damage: float, damage_type: String = "physical"):
	"""Take damage and update health"""
	if current_state == EnemyState.DEAD:
		return
	
	current_health = max(0.0, current_health - damage)
	health_changed.emit(current_health, max_health)
	
	# Update health bar
	if health_bar:
		health_bar.value = current_health
		
		# Change color based on health percentage
		var health_percentage = current_health / max_health
		var style_fg = health_bar.get_theme_stylebox("fill") as StyleBoxFlat
		if style_fg:
			if health_percentage > 0.6:
				style_fg.bg_color = Color.GREEN
			elif health_percentage > 0.3:
				style_fg.bg_color = Color.YELLOW
			else:
				style_fg.bg_color = Color.RED
	
	# Create damage effect
	create_damage_effect(damage, damage_type)
	
	# Check for death
	if current_health <= 0:
		die()
	else:
		# Interrupt current attack if taking significant damage
		if damage >= max_health * 0.2:  # 20% or more damage
			interrupt_attack()

func interrupt_attack():
	"""Interrupt current attack and enter stunned state"""
	if current_state == EnemyState.ATTACKING:
		attack_system.stop_current_pattern()
		current_state = EnemyState.STUNNED
		state_timer = 0.0

func die():
	"""Handle enemy death"""
	current_state = EnemyState.DEAD
	current_health = 0.0
	
	# Stop all attacks
	attack_system.stop_current_pattern()
	
	# Create death effect
	create_death_effect()
	
	# Emit death signal
	enemy_died.emit(self)
	
	# Remove from scene after a delay
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 1.0)
	tween.tween_callback(queue_free)

func create_damage_effect(damage: float, damage_type: String):
	"""Create visual effect for taking damage"""
	# Flash red
	if visual_mesh and visual_mesh.material_override:
		var original_color = visual_mesh.material_override.albedo_color
		visual_mesh.material_override.albedo_color = Color.WHITE
		
		var tween = create_tween()
		tween.tween_property(visual_mesh.material_override, "albedo_color", original_color, 0.2)
	
	# Create floating damage text
	create_floating_damage_text(str(int(damage)), global_position + Vector3(0, 2, 0))

func create_death_effect():
	"""Create visual effect for death"""
	# Create explosion-like effect
	var effect = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	effect.mesh = sphere
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.ORANGE
	material.emission_enabled = true
	material.emission = Color.ORANGE * 2.0
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	effect.material_override = material
	
	effect.position = global_position
	get_parent().add_child(effect)
	
	# Animate explosion
	var tween = create_tween()
	tween.parallel().tween_property(effect, "scale", Vector3(3.0, 3.0, 3.0), 0.5)
	tween.parallel().tween_property(material, "albedo_color:a", 0.0, 0.5)
	tween.tween_callback(effect.queue_free)

func create_floating_damage_text(text: String, world_position: Vector3):
	"""Create floating damage text at world position"""
	# This would create a 3D label or UI element showing damage
	print("EnemyAI: Damage dealt - ", text)

# Signal handlers

func _on_attack_pattern_started(pattern_id: String):
	"""Handle attack pattern started"""
	print("EnemyAI: Started attack pattern '", pattern_id, "'")

func _on_attack_pattern_completed(pattern_id: String):
	"""Handle attack pattern completed"""
	print("EnemyAI: Completed attack pattern '", pattern_id, "'")
	
	# Return to pursuing state
	if current_state == EnemyState.ATTACKING:
		current_state = EnemyState.PURSUING
		state_timer = 0.0

func _on_attack_executed(attack_data: EnemyAttackSystem.AttackData):
	"""Handle individual attack execution"""
	print("EnemyAI: Executed attack '", attack_data.attack_id, "'")

# Public API methods

func get_enemy_type() -> EnemyAttackSystem.EnemyType:
	"""Get the enemy type"""
	return enemy_type

func get_current_state() -> EnemyState:
	"""Get current AI state"""
	return current_state

func get_health_percentage() -> float:
	"""Get current health as percentage"""
	return current_health / max_health

func is_alive() -> bool:
	"""Check if enemy is alive"""
	return current_state != EnemyState.DEAD

func force_attack_pattern(pattern_id: String) -> bool:
	"""Force the enemy to use a specific attack pattern"""
	print("EnemyAI: Forcing attack pattern '", pattern_id, "'")
	if attack_system.start_attack_pattern(pattern_id, global_position):
		current_state = EnemyState.ATTACKING
		attack_timer = 0.0
		state_timer = 0.0
		print("EnemyAI: Successfully forced attack pattern")
		return true
	else:
		print("EnemyAI: Failed to force attack pattern")
		return false

func force_immediate_attack():
	"""Force the enemy to attack immediately (for testing)"""
	if target_player:
		var distance = global_position.distance_to(target_player.global_position)
		print("EnemyAI: Forcing immediate attack at distance ", distance)
		start_attack()
	else:
		print("EnemyAI: Cannot force attack - no target player")

# Debug methods

func debug_enemy_ai():
	"""Print debug information about enemy AI"""
	print("=== ENEMY AI DEBUG ===")
	print("Enemy Type: ", enemy_type)
	print("Current State: ", current_state)
	print("Health: ", current_health, "/", max_health)
	print("Attack Timer: ", attack_timer)
	print("State Timer: ", state_timer)
	print("Distance to Player: ", global_position.distance_to(target_player.global_position) if target_player else "No player")
	print("======================")
