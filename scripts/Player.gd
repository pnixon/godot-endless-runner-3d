extends CharacterBody2D

const LANE_POSITIONS = [384, 512, 640]  # 3 lanes: left, center, right
const ROW_POSITIONS = [400, 300, 200, 100]  # 4 rows: front to back
const MOVE_SPEED = 800.0  # Increased for snappier feel
const HOP_DURATION = 0.2  # Faster hop
const SLIDE_DURATION = 0.3  # Faster slide
const MAX_STAMINA = 100.0
const STAMINA_REGEN_RATE = 40.0  # Faster regen for more responsive gameplay
const HOP_STAMINA_COST = 20.0  # Reduced cost
const SLIDE_STAMINA_COST = 15.0  # Reduced cost

var sprite: Sprite2D
var collision_shape: CollisionShape2D
var detection_area: Area2D  # For detecting hazards
var detection_shape: CollisionShape2D
var stamina_bar: ColorRect
var stamina_bg: ColorRect

var current_lane = 1  # Start in center lane (0=left, 1=center, 2=right)
var current_row = 0   # Start in front row (0=front, 1, 2, 3=back)
var target_x = LANE_POSITIONS[current_lane]
var target_y = ROW_POSITIONS[current_row]

# Movement states
var is_hopping = false
var is_sliding = false
var hop_timer = 0.0
var slide_timer = 0.0

# Input buffering for responsive controls
var input_buffer_time = 0.1  # 100ms buffer window
var buffered_inputs = {}

# Stamina system
var stamina = MAX_STAMINA
var original_y_position = 400.0  # Front row position

# Health system
const MAX_HEALTH = 100.0
var current_health = MAX_HEALTH
var health_bar: ColorRect
var health_bg: ColorRect

# Movement cooldown to prevent spam
var movement_cooldown = 0.0
const MOVEMENT_COOLDOWN_TIME = 0.05  # 50ms between moves for crunchiness

# Signals for game events
signal coin_collected
signal xp_collected
signal obstacle_hit
signal obstacle_avoided
signal player_died

func _ready():
	print("Player _ready() called")
	add_to_group("player")
	
	# Get or create sprite node
	sprite = get_node_or_null("Sprite2D")
	if not sprite:
		print("Creating Sprite2D node...")
		sprite = Sprite2D.new()
		sprite.name = "Sprite2D"
		add_child(sprite)
	
	# Get or create collision shape node
	collision_shape = get_node_or_null("CollisionShape2D")
	if not collision_shape:
		print("Creating CollisionShape2D node...")
		collision_shape = CollisionShape2D.new()
		collision_shape.name = "CollisionShape2D"
		add_child(collision_shape)
	
	# Create Area2D for hazard detection
	detection_area = Area2D.new()
	detection_area.name = "DetectionArea"
	# Set collision layers for proper detection
	detection_area.collision_layer = 2  # Player detection layer
	detection_area.collision_mask = 1   # Detect hazards on layer 1
	add_child(detection_area)
	
	# Create collision shape for detection area
	detection_shape = CollisionShape2D.new()
	detection_shape.name = "DetectionShape"
	detection_area.add_child(detection_shape)
	
	# Connect the area detection signal
	detection_area.area_entered.connect(_on_hazard_area_entered)
	
	# Try to load the wizard sprite
	print("Attempting to load wizard sprite...")
	var wizard_texture = load("res://wizard_variation_01.png")
	if wizard_texture:
		sprite.texture = wizard_texture
		print("✅ Loaded wizard sprite successfully!")
		print("Wizard texture size: ", wizard_texture.get_size())
		
		# Scale the sprite if needed (adjust these values as needed)
		sprite.scale = Vector2(0.5, 0.5)  # Make it smaller if the original is too big
		print("Set wizard sprite scale to: ", sprite.scale)
		
		# Set up collision shape based on wizard sprite size
		var shape = RectangleShape2D.new()
		var texture_size = wizard_texture.get_size()
		shape.size = Vector2(texture_size.x * 0.5, texture_size.y * 0.5)  # Match the scale
		collision_shape.shape = shape
		
		# Use the same shape for detection area
		var detection_shape_resource = RectangleShape2D.new()
		detection_shape_resource.size = Vector2(texture_size.x * 0.5, texture_size.y * 0.5)
		detection_shape.shape = detection_shape_resource
		
		print("Set collision shape size to: ", shape.size, " (based on wizard sprite)")
		
	else:
		print("❌ Could not load wizard sprite, creating fallback...")
		# Fallback to blue rectangle if wizard sprite not found
		var texture = ImageTexture.new()
		var image = Image.create(48, 48, false, Image.FORMAT_RGB8)
		image.fill(Color.BLUE)
		texture.set_image(image)
		sprite.texture = texture
		print("Created fallback blue rectangle")
		
		# Fallback collision size
		var shape = RectangleShape2D.new()
		shape.size = Vector2(48, 48)
		collision_shape.shape = shape
		
		# Use the same shape for detection area
		var detection_shape_resource = RectangleShape2D.new()
		detection_shape_resource.size = Vector2(48, 48)
		detection_shape.shape = detection_shape_resource
		
		print("Set fallback collision shape size to: ", shape.size)
	
	# Set initial position
	position.x = LANE_POSITIONS[current_lane]
	position.y = ROW_POSITIONS[current_row]
	print("Set player initial position to: ", position)
	
	# Create stamina bar
	create_stamina_bar()
	
	# Create health bar in top left of screen
	create_health_bar()
	
	# Debug health bar after creation
	call_deferred("debug_health_bar")
	
	# Set up camera for better hazard anticipation
	setup_camera()

func setup_camera():
	# Create and configure camera
	var camera = Camera2D.new()
	camera.name = "PlayerCamera"
	
	# Zoom out to give more view distance (smaller numbers = more zoomed out)
	camera.zoom = Vector2(0.65, 0.65)  # Zoom out to 65%
	
	# Offset camera to show more of what's ahead
	camera.offset = Vector2(0, -100)  # Show more area above the player
	
	# Enable camera smoothing for better movement feel
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 4.0
	
	# Set camera limits to prevent showing too much empty space
	camera.limit_left = -100
	camera.limit_right = 1124  # Assuming 1024 screen width + some buffer
	camera.limit_top = -200
	camera.limit_bottom = 800
	
	# Make this camera current
	camera.enabled = true
	
	add_child(camera)
	print("Camera set up with zoom: ", camera.zoom, " and offset: ", camera.offset)

func _input(event):
	# Press H to debug health bar
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_H:
			debug_health_bar()
		# Press T to test damage
		elif event.keycode == KEY_T:
			take_damage(10)
			print("Test damage applied!")
		# Press Y to test healing
		elif event.keycode == KEY_Y:
			heal(10)
			print("Test heal applied!")
		# Press M to toggle music
		elif event.keycode == KEY_M:
			var game_manager = get_tree().get_first_node_in_group("game_manager")
			if game_manager:
				game_manager.toggle_music()
		# Press + to increase music volume
		elif event.keycode == KEY_EQUAL:  # + key (without shift)
			var game_manager = get_tree().get_first_node_in_group("game_manager")
			if game_manager:
				game_manager.set_music_volume(game_manager.music_volume + 0.1)
				print("Music volume: ", int(game_manager.music_volume * 100), "%")
		# Press - to decrease music volume
		elif event.keycode == KEY_MINUS:
			var game_manager = get_tree().get_first_node_in_group("game_manager")
			if game_manager:
				game_manager.set_music_volume(game_manager.music_volume - 0.1)
				print("Music volume: ", int(game_manager.music_volume * 100), "%")

func create_stamina_bar():
	# Background for stamina bar
	stamina_bg = ColorRect.new()
	stamina_bg.size = Vector2(40, 6)
	stamina_bg.position = Vector2(-20, -30)
	stamina_bg.color = Color.DARK_GRAY
	add_child(stamina_bg)
	
	# Foreground stamina bar
	stamina_bar = ColorRect.new()
	stamina_bar.size = Vector2(40, 6)
	stamina_bar.position = Vector2(-20, -30)
	stamina_bar.color = Color.GREEN
	stamina_bar.z_index = 1
	add_child(stamina_bar)

func create_health_bar():
	# Get the UI CanvasLayer to add the health bar to
	var main_scene = get_tree().current_scene
	var ui_layer = main_scene.get_node_or_null("UI")
	
	if not ui_layer:
		print("Warning: UI CanvasLayer not found, creating health bar on main scene")
		ui_layer = main_scene
	
	# Background for health bar (top left of screen)
	health_bg = ColorRect.new()
	health_bg.name = "PlayerHealthBG"
	health_bg.size = Vector2(200, 20)
	health_bg.position = Vector2(20, 20)  # Top left corner with margin
	health_bg.color = Color.BLACK
	ui_layer.add_child(health_bg)
	
	# Foreground health bar
	health_bar = ColorRect.new()
	health_bar.name = "PlayerHealthBar"
	health_bar.size = Vector2(196, 16)  # Slightly smaller than background
	health_bar.position = Vector2(22, 22)  # Offset from background
	health_bar.color = Color.GREEN  # Start with green for full health
	ui_layer.add_child(health_bar)
	
	# Add health text label
	var health_label = Label.new()
	health_label.name = "PlayerHealthLabel"
	health_label.text = "HP: " + str(int(current_health)) + "/" + str(int(MAX_HEALTH))
	health_label.position = Vector2(25, 45)  # Below the health bar
	health_label.add_theme_color_override("font_color", Color.WHITE)
	ui_layer.add_child(health_label)
	
	print("Created health bar in UI layer at position: ", health_bg.position)

# Debug function to check health bar status
func debug_health_bar():
	print("=== HEALTH BAR DEBUG ===")
	print("Health bar exists: ", health_bar != null)
	print("Health bg exists: ", health_bg != null)
	
	if health_bar:
		print("Health bar visible: ", health_bar.visible)
		print("Health bar position: ", health_bar.position)
		print("Health bar size: ", health_bar.size)
		print("Health bar color: ", health_bar.color)
		print("Health bar parent: ", health_bar.get_parent().name if health_bar.get_parent() else "No parent")
	
	if health_bg:
		print("Health bg visible: ", health_bg.visible)
		print("Health bg position: ", health_bg.position)
		print("Health bg size: ", health_bg.size)
	
	var main_scene = get_tree().current_scene
	var ui_layer = main_scene.get_node_or_null("UI")
	if ui_layer:
		print("UI layer children: ", ui_layer.get_children().map(func(child): return child.name))
	
	print("Current health: ", current_health, "/", MAX_HEALTH)
	print("========================")

func _physics_process(delta):
	# Update cooldowns
	movement_cooldown = max(0, movement_cooldown - delta)
	
	# Update input buffers
	update_input_buffers(delta)
	
	var moved = false
	
	# Only process movement if not in cooldown
	if movement_cooldown <= 0:
		# Handle lane switching (A/D keys) - INSTANT movement
		if (Input.is_action_just_pressed("move_left") or has_buffered_input("move_left")) and current_lane > 0 and not is_sliding:
			current_lane -= 1
			target_x = LANE_POSITIONS[current_lane]
			position.x = target_x  # INSTANT movement
			create_movement_effect("left")
			movement_cooldown = MOVEMENT_COOLDOWN_TIME
			clear_buffered_input("move_left")
			moved = true
		elif (Input.is_action_just_pressed("move_right") or has_buffered_input("move_right")) and current_lane < 2 and not is_sliding:
			current_lane += 1
			target_x = LANE_POSITIONS[current_lane]
			position.x = target_x  # INSTANT movement
			create_movement_effect("right")
			movement_cooldown = MOVEMENT_COOLDOWN_TIME
			clear_buffered_input("move_right")
			moved = true
		
		# Handle row movement (W/S keys) - INSTANT movement
		elif (Input.is_action_just_pressed("move_forward") or has_buffered_input("move_forward")) and current_row < 3 and not is_sliding:
			current_row += 1
			target_y = ROW_POSITIONS[current_row]
			position.y = target_y  # INSTANT movement
			create_movement_effect("forward")
			movement_cooldown = MOVEMENT_COOLDOWN_TIME
			clear_buffered_input("move_forward")
			moved = true
		elif (Input.is_action_just_pressed("move_backward") or has_buffered_input("move_backward")) and current_row > 0 and not is_sliding:
			current_row -= 1
			target_y = ROW_POSITIONS[current_row]
			position.y = target_y  # INSTANT movement
			create_movement_effect("backward")
			movement_cooldown = MOVEMENT_COOLDOWN_TIME
			clear_buffered_input("move_backward")
			moved = true
	else:
		# Buffer inputs if we're in cooldown
		if Input.is_action_just_pressed("move_left"):
			buffer_input("move_left")
		elif Input.is_action_just_pressed("move_right"):
			buffer_input("move_right")
		elif Input.is_action_just_pressed("move_forward"):
			buffer_input("move_forward")
		elif Input.is_action_just_pressed("move_backward"):
			buffer_input("move_backward")
	
	# Handle hop/jump (Space key - avoid ground hazards) - No cooldown for actions
	if Input.is_action_just_pressed("hop") and not is_hopping and not is_sliding and stamina >= HOP_STAMINA_COST:
		start_hop()
	
	# Handle slide/duck (Shift key - avoid overhead hazards) - No cooldown for actions
	if Input.is_action_just_pressed("slide") and not is_sliding and not is_hopping and stamina >= SLIDE_STAMINA_COST:
		start_slide()
	
	# Update movement states
	update_hop(delta)
	update_slide(delta)
	
	# Add screen shake on movement
	if moved:
		add_screen_shake(3.0)  # Increased intensity
	
	# Regenerate stamina
	if stamina < MAX_STAMINA:
		stamina = min(MAX_STAMINA, stamina + STAMINA_REGEN_RATE * delta)
		update_stamina_bar()

func buffer_input(action: String):
	buffered_inputs[action] = input_buffer_time

func has_buffered_input(action: String) -> bool:
	return buffered_inputs.has(action) and buffered_inputs[action] > 0

func clear_buffered_input(action: String):
	if buffered_inputs.has(action):
		buffered_inputs.erase(action)

func update_input_buffers(delta: float):
	for action in buffered_inputs.keys():
		buffered_inputs[action] -= delta
		if buffered_inputs[action] <= 0:
			buffered_inputs.erase(action)

func create_movement_effect(direction: String):
	# Create a quick visual effect for movement
	var effect = Sprite2D.new()
	effect.name = "MovementEffect"
	
	# Create a small colored square for the effect
	var effect_texture = ImageTexture.new()
	var effect_image = Image.create(20, 20, false, Image.FORMAT_RGB8)
	
	# Different colors for different directions
	var color: Color
	match direction:
		"left":
			color = Color.CYAN
		"right":
			color = Color.MAGENTA
		"forward":
			color = Color.YELLOW
		"backward":
			color = Color.ORANGE
		_:
			color = Color.WHITE
	
	effect_image.fill(color)
	effect_texture.set_image(effect_image)
	effect.texture = effect_texture
	effect.position = Vector2(0, 0)  # Relative to player
	effect.z_index = -1  # Behind player
	
	add_child(effect)
	
	# Animate the effect
	var tween = create_tween()
	tween.parallel().tween_property(effect, "scale", Vector2(2.0, 2.0), 0.2)
	tween.parallel().tween_property(effect, "modulate:a", 0.0, 0.2)
	tween.tween_callback(effect.queue_free)
	
	print("Player moved ", direction, " with CRUNCH!")

func add_screen_shake(intensity: float):
	# Create a subtle screen shake effect by moving the sprite briefly
	var original_pos = sprite.position
	
	var shake_tween = create_tween()
	# Quick shake left-right
	shake_tween.tween_property(sprite, "position:x", original_pos.x + intensity, 0.05)
	shake_tween.tween_property(sprite, "position:x", original_pos.x - intensity, 0.05)
	shake_tween.tween_property(sprite, "position:x", original_pos.x, 0.05)

func start_hop():
	is_hopping = true
	hop_timer = HOP_DURATION
	stamina -= HOP_STAMINA_COST
	update_stamina_bar()
	
	# More dramatic hop effect
	var hop_tween = create_tween()
	hop_tween.tween_property(sprite, "position:y", -30, HOP_DURATION * 0.3)  # Higher jump
	hop_tween.tween_property(sprite, "position:y", 0, HOP_DURATION * 0.7)   # Faster fall
	
	# Add hop effect
	create_hop_effect()
	
	print("Player HOPS with power!")

func create_hop_effect():
	# Create a burst effect for hopping
	for i in range(5):
		var particle = Sprite2D.new()
		particle.name = "HopParticle_" + str(i)
		
		var particle_texture = ImageTexture.new()
		var particle_image = Image.create(8, 8, false, Image.FORMAT_RGB8)
		particle_image.fill(Color.WHITE)
		particle_texture.set_image(particle_image)
		particle.texture = particle_texture
		
		# Random position around player
		particle.position = Vector2(randf_range(-20, 20), 10)
		particle.z_index = -1
		
		add_child(particle)
		
		# Animate particles
		var particle_tween = create_tween()
		particle_tween.parallel().tween_property(particle, "position:y", particle.position.y + randf_range(20, 40), 0.5)
		particle_tween.parallel().tween_property(particle, "modulate:a", 0.0, 0.5)
		particle_tween.tween_callback(particle.queue_free)

func start_slide():
	is_sliding = true
	slide_timer = SLIDE_DURATION
	stamina -= SLIDE_STAMINA_COST
	update_stamina_bar()
	
	# More dramatic slide effect
	sprite.position.y = 15  # Lower crouch
	sprite.scale.y = 0.2    # More squashed
	
	# Add slide effect
	create_slide_effect()
	
	print("Player SLIDES with style!")

func create_slide_effect():
	# Create a dust trail effect for sliding
	for i in range(3):
		var dust = Sprite2D.new()
		dust.name = "SlideDust_" + str(i)
		
		var dust_texture = ImageTexture.new()
		var dust_image = Image.create(12, 6, false, Image.FORMAT_RGB8)
		dust_image.fill(Color(0.8, 0.7, 0.5, 0.7))  # Dusty brown
		dust_texture.set_image(dust_image)
		dust.texture = dust_texture
		
		# Position behind player
		dust.position = Vector2(randf_range(-15, -5), 15)
		dust.z_index = -1
		
		add_child(dust)
		
		# Animate dust
		var dust_tween = create_tween()
		dust_tween.parallel().tween_property(dust, "position:x", dust.position.x - 30, 0.4)
		dust_tween.parallel().tween_property(dust, "modulate:a", 0.0, 0.4)
		dust_tween.tween_callback(dust.queue_free)

func update_hop(delta):
	if is_hopping:
		hop_timer -= delta
		if hop_timer <= 0:
			is_hopping = false
			sprite.position.y = 0  # Return to normal position
			print("Hop finished")

func update_slide(delta):
	if is_sliding:
		slide_timer -= delta
		if slide_timer <= 0:
			is_sliding = false
			sprite.position.y = 0  # Return to normal position
			sprite.scale.y = 0.5   # Return to normal scale (matching the wizard sprite scale)
			print("Slide finished")

func update_stamina_bar():
	var stamina_ratio = stamina / MAX_STAMINA
	stamina_bar.size.x = 40 * stamina_ratio
	
	# Change color based on stamina level
	if stamina_ratio > 0.6:
		stamina_bar.color = Color.GREEN
	elif stamina_ratio > 0.3:
		stamina_bar.color = Color.YELLOW
	else:
		stamina_bar.color = Color.RED

func update_health_bar():
	if not health_bar:
		return
	
	var health_ratio = current_health / MAX_HEALTH
	health_bar.size.x = 196 * health_ratio  # Scale the bar width
	
	# Change color based on health level
	if health_ratio > 0.6:
		health_bar.color = Color.GREEN
	elif health_ratio > 0.3:
		health_bar.color = Color.YELLOW
	else:
		health_bar.color = Color.RED
	
	# Update health label
	var main_scene = get_tree().current_scene
	var ui_layer = main_scene.get_node_or_null("UI")
	var health_label = null
	
	if ui_layer:
		health_label = ui_layer.get_node_or_null("PlayerHealthLabel")
	else:
		health_label = main_scene.get_node_or_null("PlayerHealthLabel")
	
	if health_label:
		health_label.text = "HP: " + str(int(current_health)) + "/" + str(int(MAX_HEALTH))

func take_damage(damage: float):
	current_health = max(0, current_health - damage)
	update_health_bar()
	
	# Create damage effect
	create_damage_effect(damage)
	
	print("Player took ", damage, " damage! Health: ", current_health, "/", MAX_HEALTH)
	
	# Check if player died
	if current_health <= 0:
		player_died.emit()
		print("Player died!")

func heal(amount: float):
	current_health = min(MAX_HEALTH, current_health + amount)
	update_health_bar()
	
	# Create heal effect
	create_heal_effect(amount)
	
	print("Player healed ", amount, " HP! Health: ", current_health, "/", MAX_HEALTH)

func create_damage_effect(damage: float):
	# Create red damage numbers floating up
	var damage_label = Label.new()
	damage_label.text = "-" + str(int(damage))
	damage_label.position = position + Vector2(randf_range(-20, 20), -40)
	damage_label.add_theme_color_override("font_color", Color.RED)
	damage_label.z_index = 50
	
	get_tree().current_scene.add_child(damage_label)
	
	# Animate the damage number
	var tween = create_tween()
	tween.parallel().tween_property(damage_label, "position:y", damage_label.position.y - 50, 1.0)
	tween.parallel().tween_property(damage_label, "modulate:a", 0.0, 1.0)
	tween.tween_callback(damage_label.queue_free)
	
	# Screen shake for damage
	add_screen_shake(5.0)

func create_heal_effect(amount: float):
	# Create green heal numbers floating up
	var heal_label = Label.new()
	heal_label.text = "+" + str(int(amount))
	heal_label.position = position + Vector2(randf_range(-20, 20), -40)
	heal_label.add_theme_color_override("font_color", Color.GREEN)
	heal_label.z_index = 50
	
	get_tree().current_scene.add_child(heal_label)
	
	# Animate the heal number
	var tween = create_tween()
	tween.parallel().tween_property(heal_label, "position:y", heal_label.position.y - 50, 1.0)
	tween.parallel().tween_property(heal_label, "modulate:a", 0.0, 1.0)
	tween.tween_callback(heal_label.queue_free)

func get_current_lane() -> int:
	return current_lane

func get_current_row() -> int:
	return current_row

func reset_position():
	current_lane = 1
	current_row = 0
	target_x = LANE_POSITIONS[current_lane]
	target_y = ROW_POSITIONS[current_row]
	position.x = target_x
	position.y = target_y
	
	# Reset movement states
	is_hopping = false
	is_sliding = false
	hop_timer = 0.0
	slide_timer = 0.0
	sprite.position.y = 0
	sprite.scale.y = 0.5  # Match wizard sprite scale
	
	# Reset stamina
	stamina = MAX_STAMINA
	update_stamina_bar()
	
	# Reset health
	current_health = MAX_HEALTH
	update_health_bar()
	
	print("Player position and health reset to lane ", current_lane, " row ", current_row)

func _on_hazard_area_entered(area):
	print("=== PLAYER COLLISION DETECTED ===")
	print("Area name: ", area.name)
	print("Player health before: ", current_health, "/", MAX_HEALTH)
	
	# Handle different types of obstacles/pickups
	if area.has_method("get_hazard_type"):
		var hazard_type = area.get_hazard_type()
		print("Hazard type: ", hazard_type)
		
		match hazard_type:
			"GROUND_SPIKES":
				if not is_hopping:
					print("Hit ground spikes - taking 20 damage!")
					take_damage(20.0)
					obstacle_hit.emit()
				else:
					print("Avoided ground spikes by hopping!")
					obstacle_avoided.emit()
				area.queue_free()  # Remove the hazard
			
			"OVERHEAD_BARRIER":
				if not is_sliding:
					print("Hit overhead barrier - taking 15 damage!")
					take_damage(15.0)
					obstacle_hit.emit()
				else:
					print("Avoided overhead barrier by sliding!")
					obstacle_avoided.emit()
				area.queue_free()  # Remove the hazard
			
			"PICKUP_COIN":
				print("Collected coin!")
				coin_collected.emit()
				area.queue_free()
			
			"PICKUP_XP":
				print("Collected XP - healing 5 HP!")
				xp_collected.emit()
				heal(5.0)
				area.queue_free()
			
			"ENEMY_MARKER":
				print("Hit enemy marker - taking 25 damage!")
				take_damage(25.0)
				obstacle_hit.emit()
				area.queue_free()
			
			"HEALTH_POTION":
				print("Collected health potion - healing 30 HP!")
				heal(30.0)
				# You could add a special signal for health potion collection if needed
				area.queue_free()
			
			_:
				print("Unknown hazard type: ", hazard_type)
	else:
		print("Area doesn't have get_hazard_type method")
	
	print("Player health after: ", current_health, "/", MAX_HEALTH)
	print("=== END COLLISION ===")
