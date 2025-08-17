extends CharacterBody3D

# Player signals
signal player_died
signal obstacle_hit
signal obstacle_avoided
signal coin_collected
signal xp_collected

# 3D Movement constants - ULTRA-CRUNCHY SETTINGS
const SPEED = 12.0  # Faster base speed
const JUMP_VELOCITY = 16.0  # Reduced for quicker, less floaty jumps
const SLIDE_VELOCITY = -12.0  # Faster slide

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
const JUMP_DURATION = 0.3  # Much shorter jump duration for ultra-snappy feel
const SLIDE_DURATION = 0.3  # Shorter slide for snappier feel

# Movement smoothing - CRUNCHY SETTINGS
var movement_speed = 35.0  # Much faster lateral movement
var original_y_position = 1.0  # Ground level

# Health system
const MAX_HEALTH = 100.0
var current_health = MAX_HEALTH
var health_bar: ColorRect
var health_bg: ColorRect

# Movement cooldown to prevent spam - REDUCED for crunchiness
var movement_cooldown = 0.0
const MOVEMENT_COOLDOWN_TIME = 0.08  # Much shorter cooldown for rapid inputs

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

# Animation references
var animation_player: AnimationPlayer
var fighter_model: Node3D

# Get gravity from the project settings and enhance it for ultra-crunchy jumps
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity") * 3.5  # Much higher gravity
var jump_gravity_multiplier = 2.5  # Heavy extra gravity when falling from jump
var coyote_time = 0.1  # Brief moment to still jump after leaving ground

func _ready():
	add_to_group("player")
	
	# Set up animation player
	setup_animation_player()
	
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
	
	# Set up collision shape - MUCH MORE PRECISE for lane-based gameplay
	var shape = BoxShape3D.new()
	shape.size = Vector3(0.8, 1.8, 0.8)  # Smaller, more precise collision
	$CollisionShape3D.shape = shape
	
	# Detection area should be even more precise - only detect in same lane
	var detection_shape_resource = BoxShape3D.new()
	detection_shape_resource.size = Vector3(0.9, 1.9, 0.9)  # Just slightly larger than player
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
		# Position camera much higher and further back for better overview
		camera.position = Vector3(0, 8, 8)  # Higher up (8 vs 4) and further back
		camera.rotation_degrees = Vector3(-25, 0, 0)  # Steeper angle (-25 vs -15)
		
		# Adjust FOV for better view of the action
		camera.fov = 65.0  # Slightly tighter FOV for more focused view
		
		print("3D Camera configured: High overview angle for crunchy gameplay")

func setup_animation_player():
	# Find the fighter model and animation player
	fighter_model = $FighterModel/Animation_Running_withSkin
	if fighter_model:
		# Rotate the fighter model 180 degrees to face away from camera
		fighter_model.rotation_degrees.y = 180
		
		# Look for AnimationPlayer in the fighter model
		animation_player = fighter_model.get_node("AnimationPlayer")
		if animation_player:
			# Debug: Print all available animations
			print("Available animations:")
			var animation_list = animation_player.get_animation_list()
			for anim_name in animation_list:
				print("  - ", anim_name)
			
			# Try to play the first available animation with looping
			if animation_list.size() > 0:
				var first_animation = animation_list[0]
				animation_player.play(first_animation)
				# Set the animation to loop
				var animation_resource = animation_player.get_animation(first_animation)
				if animation_resource:
					animation_resource.loop_mode = Animation.LOOP_LINEAR
				print("Playing looped animation: ", first_animation)
			else:
				print("No animations found in AnimationPlayer")
		else:
			print("AnimationPlayer not found in fighter model")
	else:
		print("Fighter model not found")

func play_animation(animation_name: String):
	if animation_player and animation_player.has_animation(animation_name):
		animation_player.play(animation_name)
		# Ensure the animation loops
		var animation_resource = animation_player.get_animation(animation_name)
		if animation_resource:
			animation_resource.loop_mode = Animation.LOOP_LINEAR
		print("Playing looped animation: ", animation_name)
	else:
		print("Animation not found: ", animation_name)

func play_running_animation():
	# Try different possible running animation names
	var possible_names = ["Running", "run", "Run", "Animation_Running_withSkin", "Armature|Running"]
	for name in possible_names:
		if animation_player and animation_player.has_animation(name):
			play_animation(name)
			return
	print("No running animation found")

func play_jump_animation():
	# Try different possible jump animation names
	var possible_names = ["Jump", "jump", "Regular_Jump", "Animation_Regular_Jump_withSkin", "Armature|Jump"]
	for name in possible_names:
		if animation_player and animation_player.has_animation(name):
			play_animation(name)
			return
	# If no jump animation found, keep running
	play_running_animation()

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
	# Handle ULTRA-enhanced gravity for non-floaty jumps
	if not is_on_floor():
		var gravity_multiplier = jump_gravity_multiplier if velocity.y < 0 else 1.8  # Heavy gravity even going up
		velocity.y -= gravity * gravity_multiplier * delta
		
		# Cap falling speed to prevent going through floor
		velocity.y = max(velocity.y, -50.0)
	
	# Update timers
	movement_cooldown -= delta
	
	# Update input buffers
	update_input_buffers(delta)
	
	var moved = false
	
	# Handle movement input with cooldown
	if movement_cooldown <= 0:
		# Handle lane switching (A/D keys) - SMOOTH but fast movement
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
		
		# Handle row movement (W/S keys) - SMOOTH but fast movement
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
		play_jump_animation()
	
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
			play_running_animation()
	
	if is_sliding:
		slide_timer -= delta
		# Make player crouch lower when sliding
		scale.y = lerp(scale.y, 0.5, 15.0 * delta)  # Squash player down
		if slide_timer <= 0:
			is_sliding = false
			print("Slide ended")
	else:
		# Return to normal height when not sliding
		scale.y = lerp(scale.y, 1.0, 15.0 * delta)
	
	# SMOOTH movement to target positions - fast but not jarring
	var movement_lerp_speed = 20.0  # Fast but smooth interpolation
	position.x = lerp(position.x, target_x, movement_lerp_speed * delta)
	position.z = lerp(position.z, target_z, movement_lerp_speed * delta)
	
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
	# Create visual and audio feedback for crunchy movement
	print("CRUNCHY movement effect: ", direction)
	
	# Add screen shake effect for crunchiness
	var camera = $Camera3D
	if camera:
		# Quick camera shake
		var original_pos = camera.position
		camera.position += Vector3(randf_range(-0.1, 0.1), randf_range(-0.1, 0.1), 0)
		
		# Return to original position quickly
		var tween = create_tween()
		tween.tween_property(camera, "position", original_pos, 0.05)
	
	# Add particle effect or visual pop
	create_movement_particles(direction)
	
	# Play crunchy sound effect
	play_movement_sound(direction)

func create_movement_particles(direction: String):
	# Create quick particle burst for movement feedback
	# For now, just a visual indicator - could add actual particles later
	var indicator = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.2
	sphere.height = 0.4
	indicator.mesh = sphere
	
	# Create glowing material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.CYAN
	material.emission_enabled = true
	material.emission = Color.CYAN * 0.8
	indicator.material_override = material
	
	# Position slightly offset from player
	var offset = Vector3.ZERO
	match direction:
		"left": offset = Vector3(-0.5, 0.5, 0)
		"right": offset = Vector3(0.5, 0.5, 0)
		"forward": offset = Vector3(0, 0.5, -0.5)
		"backward": offset = Vector3(0, 0.5, 0.5)
		"jump": offset = Vector3(0, 1.0, 0)
		"slide": offset = Vector3(0, 0.2, 0)
	
	indicator.position = position + offset
	get_parent().add_child(indicator)
	
	# Animate and remove
	var tween = create_tween()
	tween.parallel().tween_property(indicator, "scale", Vector3.ZERO, 0.3)
	tween.parallel().tween_property(indicator, "position:y", indicator.position.y + 1, 0.3)
	tween.tween_callback(indicator.queue_free)

func play_movement_sound(direction: String):
	# Play different pitched sounds for different movements
	var pitch = 1.0
	match direction:
		"left": pitch = 0.8
		"right": pitch = 1.2
		"forward": pitch = 1.1
		"backward": pitch = 0.9
		"jump": pitch = 1.5
		"slide": pitch = 0.6
	
	# For now just print - could add actual audio later
	print("CRUNCH sound: ", direction, " at pitch ", pitch)

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
	
	# LANE-BASED COLLISION VALIDATION
	# Check if hazard is actually in the same lane as player
	var hazard_position = area.global_position
	var player_position = global_position
	
	# Calculate which lane the hazard is in
	var hazard_lane = -1
	var min_distance = 999.0
	for i in range(LANE_POSITIONS.size()):
		var distance = abs(hazard_position.x - LANE_POSITIONS[i])
		if distance < min_distance:
			min_distance = distance
			hazard_lane = i
	
	# Only process collision if hazard is in same lane as player
	if hazard_lane != current_lane:
		print("COLLISION IGNORED - Hazard in lane ", hazard_lane, " but player in lane ", current_lane)
		print("Hazard X: ", hazard_position.x, " Player X: ", player_position.x)
		return
	
	print("VALID COLLISION - Both in lane ", current_lane)
	
	# Handle different types of obstacles/pickups
	if area.has_method("get_hazard_type"):
		var hazard_type = area.get_hazard_type()
		print("Hazard type: ", hazard_type)
		
		match hazard_type:
			"GROUND_SPIKES":
				# Ground spikes are avoided by jumping
				if not is_jumping:
					print("Hit ground spikes - taking 20 damage!")
					take_damage(20.0)
					obstacle_hit.emit()
				else:
					print("Avoided ground spikes by jumping!")
					obstacle_avoided.emit()
				area.queue_free()  # Remove the hazard
			
			"OVERHEAD_BARRIER":
				# Overhead barriers are avoided by sliding (crouching)
				if not is_sliding:
					print("Hit overhead barrier - taking 15 damage!")
					take_damage(15.0)
					obstacle_hit.emit()
				else:
					print("Avoided overhead barrier by sliding!")
					obstacle_avoided.emit()
				area.queue_free()  # Remove the hazard
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
