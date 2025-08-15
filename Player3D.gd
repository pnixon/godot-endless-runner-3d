extends CharacterBody3D

# Player signals
signal player_died
signal obstacle_hit
signal obstacle_avoided
signal coin_collected
signal xp_collected

# 3D Movement constants
const SPEED = 8.0
const JUMP_VELOCITY = 12.0
const SLIDE_VELOCITY = -8.0

# Lane positions (X coordinates)
const LANE_POSITIONS = [-3.0, 0.0, 3.0]  # Left, Center, Right lanes
var current_lane = 1  # Start in center lane
var target_x = 0.0

# Row positions (Z coordinates) - closer to camera is forward
const ROW_POSITIONS = [-8.0, -5.0, -2.0, 1.0]  # Back to front
var current_row = 1  # Start in middle-back row
var target_z = -5.0

# Movement state
var is_jumping = false
var is_sliding = false
var jump_timer = 0.0
var slide_timer = 0.0
const JUMP_DURATION = 0.8
const SLIDE_DURATION = 0.6

# Movement smoothing
var movement_speed = 15.0
var original_y_position = 1.0  # Ground level

# Health system
const MAX_HEALTH = 100.0
var current_health = MAX_HEALTH
var health_bar: ColorRect
var health_bg: ColorRect

# Movement cooldown to prevent spam
var movement_cooldown = 0.0
const MOVEMENT_COOLDOWN_TIME = 0.15

# Input buffering for responsive controls
var input_buffer_time = 0.1  # 100ms buffer window
var buffered_inputs = {}

# Stamina system
const MAX_STAMINA = 100.0
var current_stamina = MAX_STAMINA
var stamina_bar: ColorRect
var stamina_bg: ColorRect
var stamina_regen_rate = 30.0  # Stamina per second
var stamina_drain_rate = 40.0  # Stamina per second when using abilities

# Detection area for hazards
var detection_area: Area3D
var detection_shape: CollisionShape3D

# Get gravity from the project settings to be synced with RigidBody nodes
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	add_to_group("player")
	
	# Set initial position
	target_x = LANE_POSITIONS[current_lane]
	target_z = ROW_POSITIONS[current_row]
	position.x = target_x
	position.z = target_z
	
	# Create Area3D for hazard detection
	detection_area = Area3D.new()
	detection_area.name = "DetectionArea"
	# Set collision layers for proper detection
	detection_area.collision_layer = 2  # Player detection layer
	detection_area.collision_mask = 1   # Detect hazards on layer 1
	add_child(detection_area)
	
	# Create collision shape for detection area
	detection_shape = CollisionShape3D.new()
	detection_shape.name = "DetectionShape"
	detection_area.add_child(detection_shape)
	
	# Connect the area detection signal
	detection_area.area_entered.connect(_on_hazard_area_entered)
	
	# Set up collision shape
	var shape = BoxShape3D.new()
	shape.size = Vector3(1.0, 2.0, 1.0)
	$CollisionShape3D.shape = shape
	
	# Use the same shape for detection area
	var detection_shape_resource = BoxShape3D.new()
	detection_shape_resource.size = Vector3(1.2, 2.2, 1.2)  # Slightly larger
	detection_shape.shape = detection_shape_resource
	
	# Create stamina bar
	create_stamina_bar()
	
	# Create health bar in top left of screen
	create_health_bar()
	
	# Debug health bar after creation
	call_deferred("debug_health_bar")
	
	# Set up camera for better hazard anticipation
	setup_camera()

func setup_camera():
	# The camera is already set up in the scene, but we can adjust it here
	var camera = $Camera3D
	if camera:
		# Position camera behind and above player for 3D runner view
		camera.position = Vector3(0, 4, 6)
		camera.rotation_degrees = Vector3(-15, 0, 0)
		
		# Adjust FOV for better view
		camera.fov = 75.0
		
		print("3D Camera configured for endless runner view")

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
	stamina_bar.size = Vector2(38, 4)
	stamina_bar.position = Vector2(-19, -29)
	stamina_bar.color = Color.BLUE
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
	# Handle gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# Update timers
	movement_cooldown -= delta
	
	# Update input buffers
	update_input_buffers(delta)
	
	var moved = false
	
	# Handle movement input with cooldown
	if movement_cooldown <= 0:
		# Handle lane switching (A/D keys) - INSTANT movement
		if (Input.is_action_just_pressed("move_left") or has_buffered_input("move_left")) and current_lane > 0 and not is_sliding:
			current_lane -= 1
			target_x = LANE_POSITIONS[current_lane]
			print("Moving to lane ", current_lane, " (X: ", target_x, ")")
			create_movement_effect("left")
			movement_cooldown = MOVEMENT_COOLDOWN_TIME
			clear_buffered_input("move_left")
			moved = true
		elif (Input.is_action_just_pressed("move_right") or has_buffered_input("move_right")) and current_lane < 2 and not is_sliding:
			current_lane += 1
			target_x = LANE_POSITIONS[current_lane]
			print("Moving to lane ", current_lane, " (X: ", target_x, ")")
			create_movement_effect("right")
			movement_cooldown = MOVEMENT_COOLDOWN_TIME
			clear_buffered_input("move_right")
			moved = true
		
		# Handle row movement (W/S keys) - INSTANT movement
		elif (Input.is_action_just_pressed("move_forward") or has_buffered_input("move_forward")) and current_row < 3 and not is_sliding:
			current_row += 1
			target_z = ROW_POSITIONS[current_row]
			print("Moving to row ", current_row, " (Z: ", target_z, ")")
			create_movement_effect("forward")
			movement_cooldown = MOVEMENT_COOLDOWN_TIME
			clear_buffered_input("move_forward")
			moved = true
		elif (Input.is_action_just_pressed("move_backward") or has_buffered_input("move_backward")) and current_row > 0 and not is_sliding:
			current_row -= 1
			target_z = ROW_POSITIONS[current_row]
			print("Moving to row ", current_row, " (Z: ", target_z, ")")
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

	# Handle jump (Space key - avoid ground hazards) - No cooldown for actions
	if Input.is_action_just_pressed("jump") and is_on_floor() and not is_jumping and current_stamina >= 20:
		velocity.y = JUMP_VELOCITY
		is_jumping = true
		jump_timer = JUMP_DURATION
		current_stamina -= 20
		print("Jumping! Stamina: ", current_stamina)
		create_movement_effect("jump")
	
	# Handle slide (Shift key - avoid overhead hazards) - No cooldown for actions
	if Input.is_action_just_pressed("slide") and not is_sliding and current_stamina >= 15:
		is_sliding = true
		slide_timer = SLIDE_DURATION
		current_stamina -= 15
		print("Sliding! Stamina: ", current_stamina)
		create_movement_effect("slide")
	
	# Update action states
	if is_jumping:
		jump_timer -= delta
		if jump_timer <= 0 or is_on_floor():
			is_jumping = false
			print("Jump ended")
	
	if is_sliding:
		slide_timer -= delta
		if slide_timer <= 0:
			is_sliding = false
			print("Slide ended")
	
	# Smooth movement to target positions
	position.x = lerp(position.x, target_x, movement_speed * delta)
	position.z = lerp(position.z, target_z, movement_speed * delta)
	
	# Regenerate stamina
	if current_stamina < MAX_STAMINA:
		current_stamina = min(MAX_STAMINA, current_stamina + stamina_regen_rate * delta)
	
	# Update stamina bar
	update_stamina_bar()
	
	# Move and slide
	move_and_slide()

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
	# Create visual feedback for movement
	print("Movement effect: ", direction)

func update_stamina_bar():
	if not stamina_bar:
		return
	
	var stamina_ratio = current_stamina / MAX_STAMINA
	stamina_bar.size.x = 38 * stamina_ratio
	
	# Change color based on stamina level
	if stamina_ratio > 0.6:
		stamina_bar.color = Color.BLUE
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
	# Visual feedback for taking damage
	print("Damage effect: ", damage)

func create_heal_effect(amount: float):
	# Visual feedback for healing
	print("Heal effect: ", amount)

func reset_position():
	# Reset to starting position
	current_lane = 1
	current_row = 1
	target_x = LANE_POSITIONS[current_lane]
	target_z = ROW_POSITIONS[current_row]
	position.x = target_x
	position.z = target_z
	position.y = original_y_position
	
	# Reset movement states
	is_jumping = false
	is_sliding = false
	jump_timer = 0.0
	slide_timer = 0.0
	velocity = Vector3.ZERO
	
	# Reset stamina
	current_stamina = MAX_STAMINA
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
				if not is_jumping:
					print("Hit ground spikes - taking 20 damage!")
					take_damage(20.0)
					obstacle_hit.emit()
				else:
					print("Avoided ground spikes by jumping!")
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
