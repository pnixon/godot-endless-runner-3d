extends CharacterBody3D
class_name RunnerPlayer

# Player controller for endless runner
# Handles movement, jumping, sliding, and collisions

# Signals
signal player_died
signal health_changed(current: float, max: float)

# Movement constants
const SPEED = 12.0
const JUMP_VELOCITY = 14.0
const LANE_SWITCH_SPEED = 25.0

# Lane system
const LANE_POSITIONS = [-3.0, 0.0, 3.0]
var current_lane = 1
var target_x = 0.0

# Movement state
var is_jumping = false
var is_sliding = false
var jump_timer = 0.0
var slide_timer = 0.0
const JUMP_DURATION = 0.4
const SLIDE_DURATION = 0.4

# Health system
const MAX_HEALTH = 100.0
var current_health = MAX_HEALTH

# Visual effects
var shield_visual: MeshInstance3D
var magnet_visual: MeshInstance3D
var speed_trail: GPUParticles3D

# Collision detection
var player_area: Area3D

# Enhanced gravity for snappy jumps
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity") * 2.5

func _ready():
	add_to_group("player")

	# Set initial position
	target_x = LANE_POSITIONS[current_lane]
	position.x = target_x
	position.y = 1.0

	# Create player collision area for collectibles and obstacles
	create_detection_area()

	# Set up visual model
	setup_visual_model()

	print("✓ Runner Player initialized")

func create_detection_area():
	"""Create Area3D for detecting collectibles and obstacles"""
	player_area = Area3D.new()
	player_area.name = "PlayerArea"
	player_area.collision_layer = 2  # Player layer
	player_area.collision_mask = 5   # Obstacles (1) + Collectibles (4)
	add_child(player_area)

	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(0.9, 1.9, 0.9)
	collision.shape = shape
	collision.position.y = 0.0
	player_area.add_child(collision)

	print("✓ Player detection area created")

func setup_visual_model():
	"""Create a simple visual representation of the player"""
	# Check if we already have a model
	var existing_model = get_node_or_null("FighterModel")
	if existing_model:
		print("Using existing player model")
		return

	# Create simple capsule as placeholder
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "PlayerMesh"
	var capsule = CapsuleMesh.new()
	capsule.radius = 0.4
	capsule.height = 1.8
	mesh_instance.mesh = capsule

	# Create material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.2, 0.5, 0.9)  # Blue
	material.metallic = 0.3
	material.roughness = 0.7
	mesh_instance.material_override = material

	mesh_instance.position.y = 0.9
	add_child(mesh_instance)

	# Add collision shape
	var collision_shape = get_node_or_null("CollisionShape3D")
	if not collision_shape:
		collision_shape = CollisionShape3D.new()
		collision_shape.name = "CollisionShape3D"
		var shape = CapsuleShape3D.new()
		shape.radius = 0.4
		shape.height = 1.8
		collision_shape.shape = shape
		collision_shape.position.y = 0.9
		add_child(collision_shape)

	print("✓ Player visual model created")

func _physics_process(delta):
	# Apply gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle input
	handle_input()

	# Update movement states
	update_movement_states(delta)

	# Smooth lane switching
	position.x = lerp(position.x, target_x, LANE_SWITCH_SPEED * delta)

	# Move the player
	move_and_slide()

func handle_input():
	"""Handle player input"""
	# Lane switching
	if Input.is_action_just_pressed("move_left") and current_lane > 0:
		current_lane -= 1
		target_x = LANE_POSITIONS[current_lane]
		create_lane_switch_effect()

	if Input.is_action_just_pressed("move_right") and current_lane < 2:
		current_lane += 1
		target_x = LANE_POSITIONS[current_lane]
		create_lane_switch_effect()

	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor() and not is_jumping:
		velocity.y = JUMP_VELOCITY
		is_jumping = true
		jump_timer = JUMP_DURATION
		create_jump_effect()

	# Slide
	if Input.is_action_just_pressed("slide") and not is_sliding:
		is_sliding = true
		slide_timer = SLIDE_DURATION
		create_slide_effect()

func update_movement_states(delta: float):
	"""Update jump and slide timers"""
	if is_jumping:
		jump_timer -= delta
		if jump_timer <= 0 or is_on_floor():
			is_jumping = false

	if is_sliding:
		slide_timer -= delta
		# Crouch down when sliding
		scale.y = lerp(scale.y, 0.5, 12.0 * delta)
		if slide_timer <= 0:
			is_sliding = false
	else:
		# Return to normal height
		scale.y = lerp(scale.y, 1.0, 12.0 * delta)

func take_damage(amount: float):
	"""Take damage and check for death"""
	current_health = max(0, current_health - amount)
	health_changed.emit(current_health, MAX_HEALTH)

	# Create damage effect
	create_damage_effect()

	print("Player took ", amount, " damage! Health: ", current_health, "/", MAX_HEALTH)

	# Check for death
	if current_health <= 0:
		die()

func heal(amount: float):
	"""Restore health"""
	current_health = min(MAX_HEALTH, current_health + amount)
	health_changed.emit(current_health, MAX_HEALTH)

	# Create heal effect
	create_heal_effect()

	print("Player healed ", amount, " HP! Health: ", current_health, "/", MAX_HEALTH)

func die():
	"""Handle player death"""
	print("Player died!")
	player_died.emit()

func reset_position():
	"""Reset player to starting state"""
	current_lane = 1
	target_x = LANE_POSITIONS[current_lane]
	position.x = target_x
	position.y = 1.0
	position.z = 0.0

	current_health = MAX_HEALTH
	velocity = Vector3.ZERO
	is_jumping = false
	is_sliding = false
	scale.y = 1.0

	health_changed.emit(current_health, MAX_HEALTH)

	# Clear visual effects
	clear_power_up_visuals()

	print("Player reset")

# Visual effect functions

func create_lane_switch_effect():
	"""Create visual effect when switching lanes"""
	var effect = ParticleEffects.create_jump_dust_effect(global_position)
	get_parent().add_child(effect)

func create_jump_effect():
	"""Create visual effect when jumping"""
	var effect = ParticleEffects.create_jump_dust_effect(global_position)
	get_parent().add_child(effect)

func create_slide_effect():
	"""Create visual effect when sliding"""
	# Will create trail particles during slide
	pass

func create_damage_effect():
	"""Create visual effect when taking damage"""
	var effect = ParticleEffects.create_damage_effect(global_position + Vector3(0, 1, 0))
	get_parent().add_child(effect)

	# Screen shake could be added here
	flash_red()

func create_heal_effect():
	"""Create visual effect when healing"""
	var effect = ParticleEffects.create_heal_effect(global_position + Vector3(0, 1, 0))
	get_parent().add_child(effect)

func flash_red():
	"""Flash the player red when taking damage"""
	var mesh = get_node_or_null("PlayerMesh")
	if not mesh:
		return

	var material = mesh.material_override
	if material:
		var original_color = material.albedo_color
		material.albedo_color = Color(1, 0, 0)

		var tween = create_tween()
		tween.tween_property(material, "albedo_color", original_color, 0.2)

# Power-up visual effects

func activate_shield_visual():
	"""Activate shield visual effect"""
	if shield_visual:
		return  # Already active

	shield_visual = ParticleEffects.create_shield_aura()
	shield_visual.position.y = 1.0
	add_child(shield_visual)
	print("Shield visual activated")

func deactivate_shield_visual():
	"""Deactivate shield visual effect"""
	if shield_visual:
		shield_visual.queue_free()
		shield_visual = null
		print("Shield visual deactivated")

func activate_speed_visual():
	"""Activate speed boost visual effect"""
	if speed_trail:
		return  # Already active

	speed_trail = ParticleEffects.create_speed_trail_particles()
	speed_trail.position.y = 1.0
	add_child(speed_trail)
	print("Speed visual activated")

func deactivate_speed_visual():
	"""Deactivate speed boost visual effect"""
	if speed_trail:
		speed_trail.queue_free()
		speed_trail = null
		print("Speed visual deactivated")

func activate_magnet_visual():
	"""Activate magnet visual effect"""
	if magnet_visual:
		return  # Already active

	magnet_visual = ParticleEffects.create_magnet_field()
	magnet_visual.position.y = 1.0
	add_child(magnet_visual)
	print("Magnet visual activated")

func deactivate_magnet_visual():
	"""Deactivate magnet visual effect"""
	if magnet_visual:
		magnet_visual.queue_free()
		magnet_visual = null
		print("Magnet visual deactivated")

func clear_power_up_visuals():
	"""Clear all power-up visual effects"""
	deactivate_shield_visual()
	deactivate_speed_visual()
	deactivate_magnet_visual()

func _process(delta):
	"""Update sliding trail particles"""
	if is_sliding:
		# Occasionally spawn slide trail particles
		if randf() < 0.3:
			var effect = ParticleEffects.create_slide_trail_effect(global_position)
			get_parent().add_child(effect)
