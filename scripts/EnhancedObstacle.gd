extends Area2D

const SPEED = 300.0
const LANE_POSITIONS = [384, 512, 640]  # Closer together - center at 512, lanes 128px apart
const REMOVAL_MARGIN = 150  # Safety margin beyond viewport

var sprite: Sprite2D
var collision_shape: CollisionShape2D
var aura_sprite: Sprite2D  # Track aura sprite for enemy markers

var hazard_data: HazardData
var is_telegraphing = true
var telegraph_timer = 0.0
var setup_deferred = false

# Viewport bounds - calculated on ready
var viewport_height: float
var removal_y_threshold: float
var spawn_y_position: float

func _init():
	# Set Z-index to ensure hazards render above background
	z_index = 10
	
	# Set collision layers for proper detection
	collision_layer = 1  # Hazards on layer 1
	collision_mask = 2   # Detect player on layer 2
	
	# Create collision shape node (keep this as child)
	collision_shape = CollisionShape2D.new()
	collision_shape.name = "CollisionShape2D"
	add_child(collision_shape)

func _ready():
	# Get actual viewport size
	var viewport = get_viewport()
	if viewport:
		var viewport_size = viewport.get_visible_rect().size
		viewport_height = viewport_size.y
	else:
		# Fallback to project settings
		viewport_height = ProjectSettings.get_setting("display/window/size/viewport_height", 600)
	
	# Calculate bounds with safety margins
	removal_y_threshold = viewport_height + REMOVAL_MARGIN
	spawn_y_position = -REMOVAL_MARGIN
	
	# Connect signals
	body_entered.connect(_on_body_entered)
	
	# If setup was called before _ready, process it now
	if setup_deferred:
		_process_setup()

func setup_hazard(data: HazardData):
	# Store the data
	hazard_data = data
	
	# Check if we're ready to process setup
	if not is_inside_tree():
		setup_deferred = true
		return
	
	_process_setup()

func _process_setup():
	if not hazard_data:
		return
	
	# Set position based on lane
	position.x = LANE_POSITIONS[hazard_data.lane]
	position.y = spawn_y_position
	
	# Create sprite and add it directly to the main scene
	sprite = Sprite2D.new()
	sprite.name = "HazardSprite_" + str(randi())
	sprite.z_index = 50  # High enough to be above background
	sprite.visible = true
	
	# Get the main scene and add sprite to it
	var main_scene = get_parent()
	if main_scene:
		main_scene.add_child(sprite)
	else:
		add_child(sprite)  # Fallback
	
	# Create texture based on hazard type
	var normal_size = hazard_data.size
	var hazard_color: Color
	
	match hazard_data.type:
		HazardData.HazardType.GROUND_SPIKES:
			hazard_color = Color.RED
		HazardData.HazardType.OVERHEAD_BARRIER:
			hazard_color = Color.ORANGE
		HazardData.HazardType.PICKUP_COIN:
			hazard_color = Color.YELLOW
		HazardData.HazardType.PICKUP_XP:
			hazard_color = Color.CYAN
		HazardData.HazardType.ENEMY_MARKER:
			hazard_color = Color.PURPLE
			# Create special visual for enemy markers
			create_enemy_marker_visual()
		HazardData.HazardType.HEALTH_POTION:
			hazard_color = Color.MAGENTA
			# Create special visual for health potions
			create_health_potion_visual()
		_:
			hazard_color = hazard_data.color
	
	var texture = ImageTexture.new()
	var image = Image.create(int(normal_size.x), int(normal_size.y), false, Image.FORMAT_RGB8)
	image.fill(hazard_color)
	texture.set_image(image)
	
	# Set sprite properties
	sprite.texture = texture
	sprite.position = Vector2(position.x, position.y)  # Use global position
	sprite.modulate = Color.WHITE
	sprite.visible = true
	
	# Set up collision shape
	var shape = RectangleShape2D.new()
	shape.size = hazard_data.size
	collision_shape.shape = shape
	
	# Set telegraph timer
	telegraph_timer = hazard_data.telegraph_time

func create_enemy_marker_visual():
	# Create a more distinctive visual for enemy markers
	# Add a pulsing border effect
	if sprite:
		# Create a larger background sprite for the "aura" effect
		aura_sprite = Sprite2D.new()
		aura_sprite.name = "EnemyAura"
		aura_sprite.z_index = sprite.z_index - 1
		
		var aura_texture = ImageTexture.new()
		var aura_image = Image.create(80, 80, false, Image.FORMAT_RGB8)
		aura_image.fill(Color(0.5, 0.0, 0.5, 0.3))  # Semi-transparent purple
		aura_texture.set_image(aura_image)
		
		aura_sprite.texture = aura_texture
		aura_sprite.position = sprite.position
		aura_sprite.modulate = Color(1, 1, 1, 0.5)
		
		# Add to main scene
		var main_scene = get_parent()
		if main_scene:
			main_scene.add_child(aura_sprite)

func create_health_potion_visual():
	# Create a healing aura effect for health potions
	var main_scene = get_tree().current_scene
	if not main_scene:
		return
	
	# Create a pulsing green aura around the health potion
	var aura_sprite = Sprite2D.new()
	aura_sprite.name = "HealthPotionAura"
	
	# Create a larger, semi-transparent green circle
	var aura_texture = ImageTexture.new()
	var aura_image = Image.create(int(hazard_data.size.x * 1.8), int(hazard_data.size.y * 1.8), false, Image.FORMAT_RGBA8)
	aura_image.fill(Color(0, 1, 0, 0.3))  # Semi-transparent green
	aura_texture.set_image(aura_image)
	aura_sprite.texture = aura_texture
	
	# Position the aura to match the health potion
	aura_sprite.position = position
	aura_sprite.z_index = z_index - 1  # Behind the main sprite
	
	main_scene.add_child(aura_sprite)

func _physics_process(delta):
	# Move Area2D downward
	position.y += SPEED * delta
	
	# Also move the sprite if it exists
	if sprite and is_instance_valid(sprite):
		sprite.position.y = position.y
	
	# Move aura sprite if it exists
	if aura_sprite and is_instance_valid(aura_sprite):
		aura_sprite.position.y = position.y
	
	# Handle telegraphing phase
	if is_telegraphing:
		telegraph_timer -= delta
		
		if sprite and is_instance_valid(sprite):
			# Different telegraph effects for different hazard types
			if hazard_data.type == HazardData.HazardType.ENEMY_MARKER:
				# Slower, more dramatic pulsing for enemy markers
				var pulse = sin(telegraph_timer * 6.0) * 0.4 + 0.6
				sprite.modulate.a = pulse
				# Add color shifting
				var color_shift = sin(telegraph_timer * 8.0) * 0.3 + 0.7
				sprite.modulate = Color(1.0, color_shift, 1.0, pulse)
			elif hazard_data.type == HazardData.HazardType.HEALTH_POTION:
				# Gentle, healing pulsing for health potions
				var pulse = sin(telegraph_timer * 4.0) * 0.2 + 0.8
				sprite.modulate.a = pulse
				# Add green healing glow
				var glow = sin(telegraph_timer * 5.0) * 0.3 + 0.7
				sprite.modulate = Color(glow, 1.0, glow, pulse)
			else:
				# Normal telegraph for other hazards
				var pulse = sin(telegraph_timer * 10.0) * 0.3 + 0.7
				sprite.modulate.a = pulse
		
		if telegraph_timer <= 0:
			# Telegraph finished - show full hazard
			is_telegraphing = false
			if sprite and is_instance_valid(sprite):
				sprite.modulate = Color.WHITE
	
	# Remove when past calculated threshold
	if position.y > removal_y_threshold:
		return_to_pool()
	
	# Safety check for hazards that moved backwards
	if position.y < (spawn_y_position - 50):
		return_to_pool()

func return_to_pool():
	# Try to return to pool via game manager
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	if game_manager and game_manager.has_method("return_obstacle_to_pool"):
		game_manager.return_obstacle_to_pool(self)
	else:
		# Fallback: clean up and free
		cleanup()
		queue_free()

func reset_state():
	# Reset all state variables for reuse from object pool
	hazard_data = null
	is_telegraphing = true
	telegraph_timer = 0.0
	setup_deferred = false
	
	# Clean up any existing sprites
	cleanup()
	
	# Reset position
	position = Vector2.ZERO
	
	# Clear collision shape
	if collision_shape:
		collision_shape.shape = null

func cleanup():
	# Clean up all associated sprites and shapes
	if sprite and is_instance_valid(sprite):
		sprite.queue_free()
		sprite = null
	
	if aura_sprite and is_instance_valid(aura_sprite):
		aura_sprite.queue_free()
		aura_sprite = null
	
	# Clear collision shape reference
	if collision_shape and collision_shape.shape:
		collision_shape.shape = null

func _exit_tree():
	# Ensure cleanup when node is removed from tree
	cleanup()

func _on_body_entered(body):
	print("=== ENHANCED OBSTACLE COLLISION ===")
	print("Body entered: ", body.name)
	print("Body type: ", body.get_class())
	print("Hazard type: ", get_hazard_type())
	
	if body.name == "Player":
		match hazard_data.type:
			HazardData.HazardType.GROUND_SPIKES:
				if not body.is_hopping:
					get_tree().call_group("game_manager", "player_hit", "ground_spikes")
				else:
					get_tree().call_group("game_manager", "perfect_dodge")
			
			HazardData.HazardType.OVERHEAD_BARRIER:
				if not body.is_sliding:
					get_tree().call_group("game_manager", "player_hit", "overhead_barrier")
				else:
					get_tree().call_group("game_manager", "perfect_dodge")
			
			HazardData.HazardType.PICKUP_COIN:
				get_tree().call_group("game_manager", "collect_pickup", "coin", 10)
				return_to_pool()
			
			HazardData.HazardType.PICKUP_XP:
				get_tree().call_group("game_manager", "collect_pickup", "xp", 5)
				return_to_pool()
			
			HazardData.HazardType.ENEMY_MARKER:
				# Trigger combat encounter
				print("Player hit enemy marker! Formation: ", hazard_data.enemy_formation_id)
				get_tree().call_group("game_manager", "start_combat", hazard_data.enemy_formation_id, hazard_data.lane)
				return_to_pool()
			
			HazardData.HazardType.HEALTH_POTION:
				get_tree().call_group("game_manager", "collect_pickup", "health_potion", 30)
				return_to_pool()

func get_hazard_type() -> String:
	# Convert HazardData.HazardType enum to string for player collision detection
	if not hazard_data:
		return "UNKNOWN"
	
	match hazard_data.type:
		HazardData.HazardType.GROUND_SPIKES:
			return "GROUND_SPIKES"
		HazardData.HazardType.OVERHEAD_BARRIER:
			return "OVERHEAD_BARRIER"
		HazardData.HazardType.PICKUP_COIN:
			return "PICKUP_COIN"
		HazardData.HazardType.PICKUP_XP:
			return "PICKUP_XP"
		HazardData.HazardType.ENEMY_MARKER:
			return "ENEMY_MARKER"
		HazardData.HazardType.HEALTH_POTION:
			return "HEALTH_POTION"
		_:
			return "UNKNOWN"
