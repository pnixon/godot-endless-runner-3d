extends CharacterBody3D
class_name ConfigurablePlayer

## Highly configurable player controller
## Supports multiple play styles, camera views, and character configurations

# ============================================================================
# Signals
# ============================================================================

signal player_died
signal health_changed(current: float, maximum: float)
signal stamina_changed(current: float, maximum: float)
signal action_performed(action_name: String)
signal lane_changed(new_lane: int)
signal power_up_activated(power_up_type: String)

# ============================================================================
# Configuration
# ============================================================================

@export var character_config: CharacterConfig
@export var view_adapter: ViewAdapter
@export var camera_controller: CameraController

## Enable debug info
@export var debug_mode: bool = false

# ============================================================================
# State
# ============================================================================

# Health & Stamina
var current_health: float
var current_stamina: float
var has_used_second_chance: bool = false

# Movement
var current_lane: int = 1
var current_row: int = 1
var target_position: Vector3
var is_jumping: bool = false
var is_sliding: bool = false
var is_dashing: bool = false
var jump_count: int = 0
var max_jump_count: int = 1

# Timers
var jump_timer: float = 0.0
var slide_timer: float = 0.0
var dash_timer: float = 0.0
var movement_cooldown: float = 0.0
var invincibility_timer: float = 0.0

# Constants
const JUMP_DURATION = 0.4
const SLIDE_DURATION = 0.4
const DASH_DURATION = 0.2

# Power-ups
var active_power_ups: Dictionary = {}

# Visual components
var mesh_instance: MeshInstance3D
var player_area: Area3D

# Physics
var gravity: float

# ============================================================================
# Initialization
# ============================================================================

func _ready():
	add_to_group("player")

	# Apply default configs if not set
	if not character_config:
		character_config = CharacterConfig.create_balanced()

	# Initialize stats from config
	current_health = character_config.get_starting_health()
	current_stamina = character_config.max_stamina

	# Setup jump count
	max_jump_count = 2 if character_config.can_double_jump else 1

	# Calculate gravity
	gravity = ProjectSettings.get_setting("physics/3d/default_gravity") * character_config.gravity_multiplier

	# Setup visual model
	setup_visual_model()

	# Setup collision
	setup_collision()

	# Setup detection area
	setup_detection_area()

	# Set initial position
	reset_to_spawn_position()

	# Emit initial state
	health_changed.emit(current_health, character_config.max_health)
	stamina_changed.emit(current_stamina, character_config.max_stamina)

	print("✓ ConfigurablePlayer initialized: ", character_config.character_name)
	print("  Archetype: ", character_config.archetype)
	print("  Health: ", current_health, "/", character_config.max_health)

# ============================================================================
# Setup Methods
# ============================================================================

func setup_visual_model():
	"""Create visual representation"""
	# Check for existing model
	var existing = get_node_or_null("PlayerMesh")
	if existing:
		mesh_instance = existing
		apply_visual_config()
		return

	# Create new model
	mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "PlayerMesh"

	var capsule = CapsuleMesh.new()
	capsule.radius = 0.4
	capsule.height = 1.8
	mesh_instance.mesh = capsule

	var material = StandardMaterial3D.new()
	material.albedo_color = character_config.color_tint
	material.metallic = 0.3
	material.roughness = 0.7
	mesh_instance.material_override = material

	mesh_instance.position.y = 0.9
	mesh_instance.scale = character_config.model_scale
	add_child(mesh_instance)

func apply_visual_config():
	"""Apply visual configuration to existing mesh"""
	if not mesh_instance:
		return

	mesh_instance.scale = character_config.model_scale

	var material = mesh_instance.material_override
	if material is StandardMaterial3D:
		material.albedo_color = character_config.color_tint

func setup_collision():
	"""Setup collision shape"""
	var collision = get_node_or_null("CollisionShape3D")
	if not collision:
		collision = CollisionShape3D.new()
		collision.name = "CollisionShape3D"
		var shape = CapsuleShape3D.new()
		shape.radius = 0.4 * character_config.collision_scale.x
		shape.height = 1.8 * character_config.collision_scale.y
		collision.shape = shape
		collision.position.y = 0.9
		add_child(collision)

func setup_detection_area():
	"""Setup Area3D for collision detection"""
	player_area = Area3D.new()
	player_area.name = "PlayerArea"
	player_area.collision_layer = 2
	player_area.collision_mask = 5  # Obstacles + Collectibles
	add_child(player_area)

	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(0.9, 1.9, 0.9) * character_config.collision_scale
	collision.shape = shape
	collision.position.y = 0.9
	player_area.add_child(collision)

# ============================================================================
# Physics Process
# ============================================================================

func _physics_process(delta):
	# Update timers
	update_timers(delta)

	# Apply gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
		velocity.y = max(velocity.y, -50.0 * character_config.terminal_velocity_multiplier)
	else:
		# Reset jump count when on ground
		jump_count = 0

	# Handle input
	handle_input()

	# Update movement
	update_movement(delta)

	# Regenerate stamina
	regenerate_stamina(delta)

	# Regenerate health if configured
	if character_config.health_regen > 0:
		heal(character_config.health_regen * delta, false)

	# Update power-ups
	update_power_ups(delta)

	# Move
	move_and_slide()

# ============================================================================
# Input Handling
# ============================================================================

func handle_input():
	"""Handle player input based on view mode"""
	if movement_cooldown > 0:
		return

	# Get input direction
	var input_dir = Vector2.ZERO
	if Input.is_action_pressed("move_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("move_right"):
		input_dir.x += 1
	if Input.is_action_pressed("move_forward"):
		input_dir.y += 1
	if Input.is_action_pressed("move_backward"):
		input_dir.y -= 1

	# Interpret input through view adapter
	if view_adapter:
		var movement_intent = view_adapter.interpret_movement_input(input_dir)

		# Handle lane changes
		if movement_intent.lane_change != 0:
			change_lane(movement_intent.lane_change)

		# Handle row changes
		if movement_intent.row_change != 0:
			change_row(movement_intent.row_change)

	# Jump
	if Input.is_action_just_pressed("jump"):
		attempt_jump()

	# Slide
	if Input.is_action_just_pressed("slide"):
		attempt_slide()

	# Dash (if character has ability)
	if character_config.can_air_dash and Input.is_action_just_pressed("attack"):
		attempt_dash()

# ============================================================================
# Movement Methods
# ============================================================================

func change_lane(direction: int):
	"""Change to adjacent lane"""
	if not view_adapter:
		return

	var lanes = view_adapter.get_lane_positions()
	var new_lane = current_lane + direction

	if new_lane >= 0 and new_lane < lanes.size():
		current_lane = new_lane
		update_target_position()
		movement_cooldown = character_config.movement_cooldown
		lane_changed.emit(current_lane)
		action_performed.emit("lane_switch")
		create_movement_effect()

func change_row(direction: int):
	"""Change to adjacent row"""
	if not view_adapter:
		return

	var rows = view_adapter.get_row_positions()
	var new_row = current_row + direction

	if new_row >= 0 and new_row < rows.size():
		current_row = new_row
		update_target_position()
		movement_cooldown = character_config.movement_cooldown
		action_performed.emit("row_change")

func update_target_position():
	"""Update target position based on current lane/row"""
	if not view_adapter:
		return

	target_position = view_adapter.get_spawn_position(current_lane, current_row)
	target_position.y = position.y  # Keep current Y

func update_movement(delta: float):
	"""Smoothly move toward target position"""
	if not view_adapter:
		return

	# Get effective lane switch speed
	var switch_speed = character_config.lane_switch_speed * character_config.speed_multiplier
	switch_speed *= view_adapter.get_movement_speed_multiplier()

	# Lerp to target position
	position.x = lerp(position.x, target_position.x, switch_speed * delta)
	position.z = lerp(position.z, target_position.z, switch_speed * delta)

func attempt_jump():
	"""Attempt to jump"""
	# Check if can jump
	if jump_count >= max_jump_count:
		return

	# Check stamina
	if not character_config.can_afford_action(character_config.jump_stamina_cost, current_stamina):
		return

	# Perform jump
	var jump_power = 14.0 * character_config.jump_power
	velocity.y = jump_power
	is_jumping = true
	jump_timer = JUMP_DURATION
	jump_count += 1

	# Consume stamina
	consume_stamina(character_config.jump_stamina_cost)

	action_performed.emit("jump")
	create_jump_effect()

func attempt_slide():
	"""Attempt to slide"""
	if is_sliding:
		return

	# Check stamina
	if not character_config.can_afford_action(character_config.slide_stamina_cost, current_stamina):
		return

	# Perform slide
	is_sliding = true
	slide_timer = SLIDE_DURATION * character_config.slide_duration

	# Consume stamina
	consume_stamina(character_config.slide_stamina_cost)

	action_performed.emit("slide")

func attempt_dash():
	"""Attempt to dash (air dash)"""
	if is_dashing:
		return

	# Check stamina
	if not character_config.can_afford_action(character_config.dash_stamina_cost, current_stamina):
		return

	# Perform dash
	is_dashing = true
	dash_timer = DASH_DURATION
	velocity.z -= 10.0  # Forward burst

	# Consume stamina
	consume_stamina(character_config.dash_stamina_cost)

	action_performed.emit("dash")

# ============================================================================
# Timer Updates
# ============================================================================

func update_timers(delta: float):
	"""Update all timers"""
	if jump_timer > 0:
		jump_timer -= delta
		if jump_timer <= 0:
			is_jumping = false

	if slide_timer > 0:
		slide_timer -= delta
		# Crouch visual
		if mesh_instance:
			mesh_instance.scale.y = lerp(mesh_instance.scale.y, character_config.model_scale.y * 0.5, 12.0 * delta)
		if slide_timer <= 0:
			is_sliding = false
	else:
		# Return to normal height
		if mesh_instance:
			mesh_instance.scale.y = lerp(mesh_instance.scale.y, character_config.model_scale.y, 12.0 * delta)

	if dash_timer > 0:
		dash_timer -= delta
		if dash_timer <= 0:
			is_dashing = false

	if movement_cooldown > 0:
		movement_cooldown -= delta

	if invincibility_timer > 0:
		invincibility_timer -= delta

# ============================================================================
# Health & Stamina
# ============================================================================

func take_damage(amount: float):
	"""Take damage with resistance applied"""
	# Check invincibility
	if invincibility_timer > 0:
		return

	# Check shield power-up
	if active_power_ups.has("shield"):
		print("Shield blocked damage!")
		return

	# Apply damage resistance
	var effective_damage = character_config.get_effective_damage(amount)
	current_health -= effective_damage

	# Invincibility frames
	invincibility_timer = 0.5

	health_changed.emit(current_health, character_config.max_health)

	# Check for second chance
	if current_health <= 0:
		if character_config.has_second_chance and not has_used_second_chance:
			print("Second chance activated!")
			current_health = character_config.max_health * 0.5
			has_used_second_chance = true
			health_changed.emit(current_health, character_config.max_health)
			invincibility_timer = 2.0
		else:
			die()

	create_damage_effect()

func heal(amount: float, emit_signal: bool = true):
	"""Heal the player"""
	current_health = min(character_config.max_health, current_health + amount)

	if emit_signal:
		health_changed.emit(current_health, character_config.max_health)
		create_heal_effect()

func consume_stamina(amount: float):
	"""Consume stamina"""
	if not character_config.use_stamina:
		return

	current_stamina = max(0, current_stamina - amount)
	stamina_changed.emit(current_stamina, character_config.max_stamina)

func regenerate_stamina(delta: float):
	"""Regenerate stamina over time"""
	if not character_config.use_stamina:
		return

	if current_stamina < character_config.max_stamina:
		current_stamina = min(character_config.max_stamina, current_stamina + character_config.stamina_regen_rate * delta)
		stamina_changed.emit(current_stamina, character_config.max_stamina)

func die():
	"""Handle player death"""
	print("Player died!")
	player_died.emit()

# ============================================================================
# Power-ups
# ============================================================================

func activate_power_up(power_up_type: String, duration: float):
	"""Activate a power-up"""
	# Apply character multipliers
	var effective_duration = duration
	if power_up_type == "shield":
		effective_duration *= character_config.shield_duration_multiplier
	elif power_up_type == "speed_boost":
		effective_duration *= character_config.speed_boost_multiplier

	active_power_ups[power_up_type] = effective_duration
	power_up_activated.emit(power_up_type)

	# Visual feedback
	match power_up_type:
		"shield":
			activate_shield_visual()
		"speed_boost":
			activate_speed_visual()
		"magnet":
			activate_magnet_visual()

func update_power_ups(delta: float):
	"""Update active power-up timers"""
	var expired_power_ups = []

	for power_up in active_power_ups:
		active_power_ups[power_up] -= delta
		if active_power_ups[power_up] <= 0:
			expired_power_ups.append(power_up)

	# Remove expired power-ups
	for power_up in expired_power_ups:
		active_power_ups.erase(power_up)
		deactivate_power_up_visual(power_up)

func has_power_up(power_up_type: String) -> bool:
	"""Check if power-up is active"""
	return active_power_ups.has(power_up_type)

# ============================================================================
# Visual Effects
# ============================================================================

func create_movement_effect():
	"""Create movement effect"""
	if not get_parent():
		return
	var effect = ParticleEffects.create_jump_dust_effect(global_position)
	get_parent().add_child(effect)

func create_jump_effect():
	"""Create jump effect"""
	if not get_parent():
		return
	var effect = ParticleEffects.create_jump_dust_effect(global_position)
	get_parent().add_child(effect)

func create_damage_effect():
	"""Create damage effect"""
	if not get_parent():
		return
	var effect = ParticleEffects.create_damage_effect(global_position + Vector3(0, 1, 0))
	get_parent().add_child(effect)
	flash_red()

func create_heal_effect():
	"""Create heal effect"""
	if not get_parent():
		return
	var effect = ParticleEffects.create_heal_effect(global_position + Vector3(0, 1, 0))
	get_parent().add_child(effect)

func flash_red():
	"""Flash player red when damaged"""
	if not mesh_instance or not mesh_instance.material_override:
		return

	var material = mesh_instance.material_override as StandardMaterial3D
	if material:
		var original_color = material.albedo_color
		material.albedo_color = Color(1, 0, 0)

		var tween = create_tween()
		tween.tween_property(material, "albedo_color", original_color, 0.2)

# Power-up visuals (placeholders - would need full implementation)
func activate_shield_visual(): pass
func activate_speed_visual(): pass
func activate_magnet_visual(): pass
func deactivate_power_up_visual(type: String): pass

# ============================================================================
# Reset & Utility
# ============================================================================

func reset_to_spawn_position():
	"""Reset player to starting position"""
	current_lane = 1
	current_row = 1

	if view_adapter:
		update_target_position()
		position = target_position
	else:
		position = Vector3(0, 1, 0)

	current_health = character_config.get_starting_health()
	current_stamina = character_config.max_stamina
	velocity = Vector3.ZERO
	is_jumping = false
	is_sliding = false
	is_dashing = false
	jump_count = 0
	active_power_ups.clear()
	has_used_second_chance = false

	health_changed.emit(current_health, character_config.max_health)
	stamina_changed.emit(current_stamina, character_config.max_stamina)

func get_score_multiplier() -> float:
	"""Get total score multiplier"""
	return character_config.score_multiplier

func get_coin_multiplier() -> float:
	"""Get coin value multiplier"""
	return character_config.coin_multiplier

func can_break_obstacles() -> bool:
	"""Check if can break through obstacles"""
	return character_config.can_break_obstacles
