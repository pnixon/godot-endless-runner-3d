extends CharacterBody3D
class_name RPGPlayer3D

# Import existing Player3D functionality while adding RPG systems
# This extends the lane-based movement system with RPG mechanics

# Player signals - keeping existing ones and adding RPG-specific
signal player_died
signal obstacle_hit
signal obstacle_avoided
signal coin_collected
signal xp_collected
signal level_up(new_level: int)
signal equipment_changed(slot: String, item: Equipment)
signal stats_changed()

# RPG System Components
var player_data: PlayerData
var equipment_manager: EquipmentManager
var level_up_system: LevelUpSystem
var ability_system: AbilitySystem
var companion_coordinator: CompanionCoordinator
var combat_controller: CombatController

# 3D Movement constants - ULTRA-CRUNCHY SETTINGS (from original)
const SPEED = 12.0
const JUMP_VELOCITY = 16.0
const SLIDE_VELOCITY = -12.0

# Lane positions (X coordinates)
const LANE_POSITIONS = [-3.0, 0.0, 3.0]
var current_lane = 1
var target_x = 0.0

# Row positions (Z coordinates)
const ROW_POSITIONS = [-8.0, -5.0, -2.0, 1.0]
var current_row = 1
var target_z = -5.0

# Movement state
var is_jumping = false
var is_sliding = false
var jump_timer = 0.0
var slide_timer = 0.0
const JUMP_DURATION = 0.3
const SLIDE_DURATION = 0.3

# Movement smoothing
var movement_speed = 35.0
var original_y_position = 1.0

# Movement cooldown
var movement_cooldown = 0.0
const MOVEMENT_COOLDOWN_TIME = 0.08

# Input buffering
var input_buffer_time = 0.1
var buffered_inputs = {}

# UI References
var health_bar: ColorRect
var health_bg: ColorRect
var mana_bar: ColorRect
var mana_bg: ColorRect
var level_label: Label
var xp_bar: ColorRect
var xp_bg: ColorRect

# Animation references
var animation_player: AnimationPlayer
var fighter_model: Node3D

# Enhanced gravity system
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity") * 3.5
var jump_gravity_multiplier = 2.5
var coyote_time = 0.1

func _ready():
	add_to_group("player")
	add_to_group("rpg_player")
	
	# Initialize RPG systems
	initialize_rpg_systems()
	
	# Set up animation player
	setup_animation_player()
	
	# Set initial position
	target_x = LANE_POSITIONS[current_lane]
	target_z = ROW_POSITIONS[current_row]
	position.x = target_x
	position.z = target_z
	
	# Set up collision shape
	setup_collision_shape()
	
	# Create UI elements
	create_rpg_ui()
	
	# Set up camera
	setup_camera()
	
	# Connect RPG signals
	connect_rpg_signals()

func initialize_rpg_systems():
	"""Initialize all RPG system components"""
	# Create or load player data
	if not player_data:
		player_data = PlayerData.new()
		
		# Add some test companions for demonstration
		player_data.unlocked_companions = ["tank_companion", "healer_companion", "dps_companion"]
		player_data.active_companions = ["tank_companion", "healer_companion"]  # Start with 2 companions
	
	# Initialize equipment manager
	equipment_manager = EquipmentManager.new()
	equipment_manager.initialize(self, player_data)
	add_child(equipment_manager)
	
	# Initialize level up system
	level_up_system = LevelUpSystem.new()
	level_up_system.initialize(player_data)
	add_child(level_up_system)
	
	# Initialize ability system
	ability_system = AbilitySystem.new()
	ability_system.initialize(self, player_data)
	add_child(ability_system)
	
	# Initialize companion coordinator
	companion_coordinator = CompanionCoordinator.new()
	companion_coordinator.initialize(self, player_data)
	add_child(companion_coordinator)
	
	# Initialize combat controller
	combat_controller = CombatController.new()
	add_child(combat_controller)
	
	print("RPG systems initialized for player")

func connect_rpg_signals():
	"""Connect RPG-specific signals"""
	if player_data and player_data.stats:
		player_data.stats.level_up.connect(_on_player_level_up)
		player_data.stats.stats_changed.connect(_on_stats_changed)
		player_data.stats.experience_gained.connect(_on_experience_gained)
	
	if player_data:
		player_data.equipment_changed.connect(_on_equipment_changed)
	
	if equipment_manager:
		equipment_manager.visual_update_needed.connect(_on_equipment_visual_update)
	
	if ability_system:
		ability_system.ability_used.connect(_on_ability_used)
		ability_system.ability_ready.connect(_on_ability_ready)
	
	if companion_coordinator:
		companion_coordinator.companion_command_issued.connect(_on_companion_command_issued)
		companion_coordinator.formation_changed.connect(_on_formation_changed)
	
	if combat_controller:
		combat_controller.dodge_performed.connect(_on_dodge_performed)
		combat_controller.block_started.connect(_on_block_started)
		combat_controller.block_ended.connect(_on_block_ended)
		combat_controller.perfect_dodge_achieved.connect(_on_perfect_dodge_achieved)
		combat_controller.invincibility_started.connect(_on_invincibility_started)
		combat_controller.invincibility_ended.connect(_on_invincibility_ended)

func setup_animation_player():
	"""Set up animation player (from original Player3D)"""
	fighter_model = $FighterModel/Animation_Running_withSkin
	if fighter_model:
		fighter_model.rotation_degrees.y = 180
		
		animation_player = fighter_model.get_node("AnimationPlayer")
		if animation_player:
			print("Available animations:")
			var animation_list = animation_player.get_animation_list()
			for anim_name in animation_list:
				print("  - ", anim_name)
			
			if animation_list.size() > 0:
				var first_animation = animation_list[0]
				animation_player.play(first_animation)
				var animation_resource = animation_player.get_animation(first_animation)
				if animation_resource:
					animation_resource.loop_mode = Animation.LOOP_LINEAR
				print("Playing looped animation: ", first_animation)
		else:
			print("AnimationPlayer not found in fighter model")
	else:
		print("Fighter model not found")

func setup_collision_shape():
	"""Set up player collision shape"""
	var shape = BoxShape3D.new()
	shape.size = Vector3(0.8, 1.8, 0.8)
	$CollisionShape3D.shape = shape

func setup_camera():
	"""Set up camera positioning"""
	var camera = $Camera3D
	if camera:
		camera.position = Vector3(0, 8, 8)
		camera.rotation_degrees = Vector3(-25, 0, 0)
		camera.fov = 65.0
		print("3D Camera configured for RPG gameplay")

func create_rpg_ui():
	"""Create RPG-specific UI elements"""
	var main_scene = get_tree().current_scene
	var ui_layer = main_scene.get_node_or_null("UI")
	
	if not ui_layer:
		print("Warning: UI CanvasLayer not found, creating UI on main scene")
		ui_layer = main_scene
	
	# Health bar background
	health_bg = ColorRect.new()
	health_bg.name = "PlayerHealthBG"
	health_bg.size = Vector2(200, 20)
	health_bg.position = Vector2(20, 20)
	health_bg.color = Color.BLACK
	ui_layer.add_child(health_bg)
	
	# Health bar foreground
	health_bar = ColorRect.new()
	health_bar.name = "PlayerHealthBar"
	health_bar.size = Vector2(196, 16)
	health_bar.position = Vector2(22, 22)
	health_bar.color = Color.GREEN
	ui_layer.add_child(health_bar)
	
	# Mana bar background
	mana_bg = ColorRect.new()
	mana_bg.name = "PlayerManaBG"
	mana_bg.size = Vector2(200, 15)
	mana_bg.position = Vector2(20, 45)
	mana_bg.color = Color.BLACK
	ui_layer.add_child(mana_bg)
	
	# Mana bar foreground
	mana_bar = ColorRect.new()
	mana_bar.name = "PlayerManaBar"
	mana_bar.size = Vector2(196, 11)
	mana_bar.position = Vector2(22, 47)
	mana_bar.color = Color.BLUE
	ui_layer.add_child(mana_bar)
	
	# XP bar background
	xp_bg = ColorRect.new()
	xp_bg.name = "PlayerXPBG"
	xp_bg.size = Vector2(200, 10)
	xp_bg.position = Vector2(20, 65)
	xp_bg.color = Color.BLACK
	ui_layer.add_child(xp_bg)
	
	# XP bar foreground
	xp_bar = ColorRect.new()
	xp_bar.name = "PlayerXPBar"
	xp_bar.size = Vector2(196, 6)
	xp_bar.position = Vector2(22, 67)
	xp_bar.color = Color.YELLOW
	ui_layer.add_child(xp_bar)
	
	# Level label
	level_label = Label.new()
	level_label.name = "PlayerLevelLabel"
	level_label.position = Vector2(25, 80)
	level_label.add_theme_color_override("font_color", Color.WHITE)
	ui_layer.add_child(level_label)
	
	# Update UI with current stats
	update_rpg_ui()
	
	print("RPG UI created successfully")

func update_rpg_ui():
	"""Update all RPG UI elements"""
	if not player_data or not player_data.stats:
		return
	
	var stats = player_data.stats
	
	# Update health bar
	if health_bar:
		var health_ratio = stats.get_health_percentage()
		health_bar.size.x = 196 * health_ratio
		
		if health_ratio > 0.6:
			health_bar.color = Color.GREEN
		elif health_ratio > 0.3:
			health_bar.color = Color.YELLOW
		else:
			health_bar.color = Color.RED
	
	# Update mana bar
	if mana_bar:
		var mana_ratio = stats.get_mana_percentage()
		mana_bar.size.x = 196 * mana_ratio
	
	# Update XP bar
	if xp_bar:
		var xp_ratio = float(stats.experience) / float(stats.experience_to_next_level)
		xp_bar.size.x = 196 * xp_ratio
	
	# Update level label
	if level_label:
		level_label.text = "Level " + str(stats.level) + " | HP: " + str(int(stats.current_health)) + "/" + str(int(stats.max_health)) + " | MP: " + str(int(stats.current_mana)) + "/" + str(int(stats.max_mana))

func _input(event):
	"""Handle input events"""
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_H:
				debug_rpg_stats()
			KEY_T:
				take_damage(10)
				print("Test damage applied!")
			KEY_Y:
				heal(10)
				print("Test heal applied!")
			KEY_L:
				gain_experience(50)
				print("Test XP gained!")
			KEY_1:
				use_ability_by_key("warrior_charge")
			KEY_2:
				use_ability_by_key("mage_fireball")
			KEY_3:
				use_ability_by_key("rogue_dash")
			KEY_K:
				toggle_skill_tree_ui()
			KEY_F:
				cycle_formation()
			KEY_G:
				issue_companion_command("follow")
			KEY_B:
				issue_companion_command("defend")
			KEY_V:
				issue_companion_command("attack")
			KEY_C:
				issue_companion_command("ability")
			KEY_M:
				toggle_music()
			KEY_EQUAL:
				adjust_music_volume(0.1)
			KEY_MINUS:
				adjust_music_volume(-0.1)
			KEY_Z:
				test_combat_dodge("left")
			KEY_X:
				test_combat_dodge("right")
			KEY_N:
				test_combat_dodge("backward")
			KEY_SPACE:
				if event.pressed:
					test_combat_block()

func _physics_process(delta):
	"""Main physics update loop"""
	# Handle gravity
	if not is_on_floor():
		var gravity_multiplier = jump_gravity_multiplier if velocity.y < 0 else 1.8
		velocity.y -= gravity * gravity_multiplier * delta
		velocity.y = max(velocity.y, -50.0)
	
	# Update timers
	movement_cooldown -= delta
	update_input_buffers(delta)
	
	# Handle movement input
	handle_movement_input()
	
	# Handle action input
	handle_action_input()
	
	# Update action states
	update_action_states(delta)
	
	# Smooth movement to target positions
	var movement_lerp_speed = 20.0
	position.x = lerp(position.x, target_x, movement_lerp_speed * delta)
	position.z = lerp(position.z, target_z, movement_lerp_speed * delta)
	
	# Regenerate mana
	regenerate_mana(delta)
	
	# Update UI
	update_rpg_ui()
	
	# Move and slide
	move_and_slide()

func handle_movement_input():
	"""Handle lane and row movement input"""
	if movement_cooldown > 0:
		# Buffer inputs if in cooldown
		if Input.is_action_just_pressed("move_left"):
			buffer_input("move_left")
		elif Input.is_action_just_pressed("move_right"):
			buffer_input("move_right")
		elif Input.is_action_just_pressed("move_forward"):
			buffer_input("move_forward")
		elif Input.is_action_just_pressed("move_backward"):
			buffer_input("move_backward")
		return
	
	# Lane switching
	if (Input.is_action_just_pressed("move_left") or has_buffered_input("move_left")) and current_lane > 0 and not is_sliding:
		current_lane -= 1
		target_x = LANE_POSITIONS[current_lane]
		print("Moving to lane ", current_lane, " (X: ", target_x, ")")
		create_movement_effect("left")
		movement_cooldown = MOVEMENT_COOLDOWN_TIME
		clear_buffered_input("move_left")
	elif (Input.is_action_just_pressed("move_right") or has_buffered_input("move_right")) and current_lane < 2 and not is_sliding:
		current_lane += 1
		target_x = LANE_POSITIONS[current_lane]
		print("Moving to lane ", current_lane, " (X: ", target_x, ")")
		create_movement_effect("right")
		movement_cooldown = MOVEMENT_COOLDOWN_TIME
		clear_buffered_input("move_right")
	
	# Row movement
	elif (Input.is_action_just_pressed("move_forward") or has_buffered_input("move_forward")) and current_row < 3 and not is_sliding:
		current_row += 1
		target_z = ROW_POSITIONS[current_row]
		print("Moving to row ", current_row, " (Z: ", target_z, ")")
		create_movement_effect("forward")
		movement_cooldown = MOVEMENT_COOLDOWN_TIME
		clear_buffered_input("move_forward")
	elif (Input.is_action_just_pressed("move_backward") or has_buffered_input("move_backward")) and current_row > 0 and not is_sliding:
		current_row -= 1
		target_z = ROW_POSITIONS[current_row]
		print("Moving to row ", current_row, " (Z: ", target_z, ")")
		create_movement_effect("backward")
		movement_cooldown = MOVEMENT_COOLDOWN_TIME
		clear_buffered_input("move_backward")

func handle_action_input():
	"""Handle jump and slide actions"""
	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor() and not is_jumping and can_use_stamina(20):
		velocity.y = JUMP_VELOCITY
		is_jumping = true
		jump_timer = JUMP_DURATION
		use_stamina(20)
		print("Jumping! Remaining stamina: ", get_current_stamina())
		create_movement_effect("jump")
		play_jump_animation()
	
	# Slide
	if Input.is_action_just_pressed("slide") and not is_sliding and can_use_stamina(15):
		is_sliding = true
		slide_timer = SLIDE_DURATION
		use_stamina(15)
		print("Sliding! Remaining stamina: ", get_current_stamina())
		create_movement_effect("slide")

func update_action_states(delta):
	"""Update jump and slide states"""
	if is_jumping:
		jump_timer -= delta
		if jump_timer <= 0 or is_on_floor():
			is_jumping = false
			print("Jump ended")
			play_running_animation()
	
	if is_sliding:
		slide_timer -= delta
		scale.y = lerp(scale.y, 0.5, 15.0 * delta)
		if slide_timer <= 0:
			is_sliding = false
			print("Slide ended")
	else:
		scale.y = lerp(scale.y, 1.0, 15.0 * delta)

# RPG-specific methods

func get_current_health() -> float:
	"""Get current health from RPG stats"""
	if player_data and player_data.stats:
		return player_data.stats.current_health
	return 100.0  # Fallback

func get_max_health() -> float:
	"""Get max health from RPG stats"""
	if player_data and player_data.stats:
		return player_data.stats.max_health
	return 100.0  # Fallback

func get_current_mana() -> float:
	"""Get current mana from RPG stats"""
	if player_data and player_data.stats:
		return player_data.stats.current_mana
	return 50.0  # Fallback

func get_max_mana() -> float:
	"""Get max mana from RPG stats"""
	if player_data and player_data.stats:
		return player_data.stats.max_mana
	return 50.0  # Fallback

func get_current_stamina() -> float:
	"""Get current stamina (using mana as stamina for now)"""
	return get_current_mana()

func can_use_stamina(amount: float) -> bool:
	"""Check if player has enough stamina"""
	return get_current_stamina() >= amount

func use_stamina(amount: float) -> bool:
	"""Use stamina for actions"""
	if player_data and player_data.stats:
		return player_data.stats.use_mana(amount)
	return false

func regenerate_mana(delta: float):
	"""Regenerate mana over time"""
	if player_data and player_data.stats:
		var regen_rate = 10.0  # Mana per second
		player_data.stats.restore_mana(regen_rate * delta)

func take_damage(damage: float):
	"""Take damage using RPG stats system"""
	if player_data and player_data.stats:
		var actual_damage = player_data.stats.take_damage(damage)
		create_damage_effect(actual_damage)
		
		print("Player took ", actual_damage, " damage! Health: ", player_data.stats.current_health, "/", player_data.stats.max_health)
		
		if not player_data.stats.is_alive():
			player_died.emit()
			print("Player died!")
	else:
		# Fallback to original system
		print("RPG stats not available, using fallback damage system")

func heal(amount: float):
	"""Heal using RPG stats system"""
	if player_data and player_data.stats:
		var actual_heal = player_data.stats.heal(amount)
		create_heal_effect(actual_heal)
		print("Player healed ", actual_heal, " HP! Health: ", player_data.stats.current_health, "/", player_data.stats.max_health)
	else:
		print("RPG stats not available, using fallback heal system")

func gain_experience(amount: int):
	"""Gain experience points"""
	if player_data and player_data.stats:
		player_data.stats.gain_experience(amount)
		print("Gained ", amount, " XP! Total: ", player_data.stats.experience)

func equip_item(item: Equipment, slot: String) -> bool:
	"""Equip an item"""
	if player_data:
		var success = player_data.equip_item(item, slot)
		if success and equipment_manager:
			equipment_manager.update_visual_equipment()
		return success
	return false

func get_equipped_item(slot: String) -> Equipment:
	"""Get currently equipped item in slot"""
	if not player_data:
		return null
	
	match slot:
		"weapon":
			return player_data.equipped_weapon
		"armor":
			return player_data.equipped_armor
		"accessory":
			return player_data.equipped_accessory
		_:
			return null

# Signal handlers

func _on_player_level_up(new_level: int):
	"""Handle level up event"""
	print("LEVEL UP! New level: ", new_level)
	level_up.emit(new_level)
	
	# Create level up effect
	create_level_up_effect()

func _on_stats_changed():
	"""Handle stats change event"""
	stats_changed.emit()
	update_rpg_ui()

func _on_experience_gained(amount: int):
	"""Handle experience gained event"""
	print("Experience gained: ", amount)

func _on_equipment_changed(slot: String, item: Equipment):
	"""Handle equipment change event"""
	equipment_changed.emit(slot, item)
	print("Equipment changed in slot ", slot, ": ", item.name if item else "None")

func _on_equipment_visual_update():
	"""Handle equipment visual update"""
	print("Equipment visuals updated")

func _on_ability_used(ability_id: String, success: bool):
	"""Handle ability use event"""
	if success:
		print("Successfully used ability: ", ability_id)
		create_ability_effect(ability_id)
	else:
		print("Failed to use ability: ", ability_id)

func _on_ability_ready(ability_id: String):
	"""Handle ability ready event"""
	print("Ability ready: ", ability_id)

func _on_companion_command_issued(companion_id: String, command):
	"""Handle companion command issued event"""
	print("Companion command issued to ", companion_id, ": ", command)

func _on_formation_changed(formation_type):
	"""Handle formation change event"""
	print("Formation changed to: ", formation_type)

func _on_dodge_performed(direction: String, perfect: bool):
	"""Handle dodge performed event"""
	print("Dodge performed: ", direction, " (perfect: ", perfect, ")")
	if perfect:
		create_perfect_dodge_visual_effect()

func _on_block_started():
	"""Handle block started event"""
	print("Block started")
	create_block_visual_effect()

func _on_block_ended(successful: bool):
	"""Handle block ended event"""
	print("Block ended (successful: ", successful, ")")
	end_block_visual_effect()

func _on_perfect_dodge_achieved(bonus_reward: int):
	"""Handle perfect dodge achievement"""
	print("PERFECT DODGE! Bonus reward: ", bonus_reward)
	# Award bonus XP
	gain_experience(bonus_reward)
	create_perfect_dodge_celebration_effect()

func _on_invincibility_started(duration: float):
	"""Handle invincibility started event"""
	print("Invincibility started for ", duration, " seconds")
	create_invincibility_visual_effect()

func _on_invincibility_ended():
	"""Handle invincibility ended event"""
	print("Invincibility ended")
	end_invincibility_visual_effect()

# Utility methods (from original Player3D)

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
	"""Create visual feedback for movement"""
	print("CRUNCHY movement effect: ", direction)
	
	var camera = $Camera3D
	if camera:
		var original_pos = camera.position
		camera.position += Vector3(randf_range(-0.1, 0.1), randf_range(-0.1, 0.1), 0)
		
		var tween = create_tween()
		tween.tween_property(camera, "position", original_pos, 0.05)
	
	create_movement_particles(direction)

func create_movement_particles(direction: String):
	"""Create particle effects for movement"""
	var indicator = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.2
	sphere.height = 0.4
	indicator.mesh = sphere
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.CYAN
	material.emission_enabled = true
	material.emission = Color.CYAN * 0.8
	indicator.material_override = material
	
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
	
	var tween = create_tween()
	tween.parallel().tween_property(indicator, "scale", Vector3.ZERO, 0.3)
	tween.parallel().tween_property(indicator, "position:y", indicator.position.y + 1, 0.3)
	tween.tween_callback(indicator.queue_free)

func create_damage_effect(damage: float):
	"""Visual feedback for taking damage"""
	print("Damage effect: ", damage)
	# TODO: Add particle effects, screen shake, etc.

func create_heal_effect(amount: float):
	"""Visual feedback for healing"""
	print("Heal effect: ", amount)
	# TODO: Add healing particle effects

func create_level_up_effect():
	"""Visual feedback for level up"""
	print("LEVEL UP EFFECT!")
	# TODO: Add dramatic level up effects

func play_animation(animation_name: String):
	"""Play a specific animation"""
	if animation_player and animation_player.has_animation(animation_name):
		animation_player.play(animation_name)
		var animation_resource = animation_player.get_animation(animation_name)
		if animation_resource:
			animation_resource.loop_mode = Animation.LOOP_LINEAR
		print("Playing looped animation: ", animation_name)

func play_running_animation():
	"""Play running animation"""
	var possible_names = ["Running", "run", "Run", "Animation_Running_withSkin", "Armature|Running"]
	for name in possible_names:
		if animation_player and animation_player.has_animation(name):
			play_animation(name)
			return
	print("No running animation found")

func play_jump_animation():
	"""Play jump animation"""
	var possible_names = ["Jump", "jump", "Regular_Jump", "Animation_Regular_Jump_withSkin", "Armature|Jump"]
	for name in possible_names:
		if animation_player and animation_player.has_animation(name):
			play_animation(name)
			return
	play_running_animation()

func reset_position():
	"""Reset player to starting position"""
	current_lane = 1
	current_row = 1
	target_x = LANE_POSITIONS[current_lane]
	target_z = ROW_POSITIONS[current_row]
	position.x = target_x
	position.z = target_z
	position.y = original_y_position
	
	is_jumping = false
	is_sliding = false
	jump_timer = 0.0
	slide_timer = 0.0
	velocity = Vector3.ZERO
	
	# Reset RPG stats to full
	if player_data and player_data.stats:
		player_data.stats.current_health = player_data.stats.max_health
		player_data.stats.current_mana = player_data.stats.max_mana
	
	update_rpg_ui()
	print("Player position and RPG stats reset")

func debug_rpg_stats():
	"""Debug RPG stats information"""
	print("=== RPG STATS DEBUG ===")
	if player_data and player_data.stats:
		var stats = player_data.stats
		print("Level: ", stats.level)
		print("Experience: ", stats.experience, "/", stats.experience_to_next_level)
		print("Health: ", stats.current_health, "/", stats.max_health)
		print("Mana: ", stats.current_mana, "/", stats.max_mana)
		print("Attack: ", stats.total_attack)
		print("Defense: ", stats.total_defense)
		print("Speed: ", stats.total_speed)
		print("Skill Points: ", stats.available_skill_points)
		print("Warrior Points: ", stats.warrior_points)
		print("Mage Points: ", stats.mage_points)
		print("Rogue Points: ", stats.rogue_points)
	else:
		print("No RPG stats available")
	
	# Also debug combat controller
	if combat_controller:
		combat_controller.debug_combat_state()
	
	print("========================")

func toggle_music():
	"""Toggle background music"""
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	if game_manager and game_manager.has_method("toggle_music"):
		game_manager.toggle_music()

func adjust_music_volume(adjustment: float):
	"""Adjust music volume"""
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	if game_manager and game_manager.has_method("set_music_volume"):
		var current_volume = game_manager.get("music_volume")
		if current_volume != null:
			game_manager.set_music_volume(current_volume + adjustment)
			print("Music volume: ", int((current_volume + adjustment) * 100), "%")

# Ability System Methods

func use_ability_by_key(ability_id: String) -> bool:
	"""Use ability via keyboard shortcut"""
	if ability_system:
		return ability_system.use_ability(ability_id)
	return false

func use_ability(ability_id: String, target_lane: int = -1, target_row: int = -1) -> bool:
	"""Use ability with optional targeting"""
	if ability_system:
		return ability_system.use_ability(ability_id, target_lane, target_row)
	return false

func queue_ability(ability_id: String):
	"""Queue an ability for execution"""
	if ability_system:
		ability_system.queue_ability(ability_id)

func get_unlocked_abilities() -> Array[String]:
	"""Get list of unlocked abilities"""
	if ability_system:
		return ability_system.get_unlocked_abilities()
	return []

func is_ability_ready(ability_id: String) -> bool:
	"""Check if ability is ready to use"""
	if ability_system:
		return not ability_system.is_ability_on_cooldown(ability_id)
	return false

func get_ability_cooldown(ability_id: String) -> float:
	"""Get remaining cooldown for ability"""
	if ability_system:
		return ability_system.get_cooldown_remaining(ability_id)
	return 0.0

func create_ability_effect(ability_id: String):
	"""Create visual effects for ability use"""
	print("Creating ability effect for: ", ability_id)
	
	# Create screen shake for abilities
	var camera = $Camera3D
	if camera:
		var shake_intensity = 0.2
		match ability_id:
			"warrior_charge", "warrior_whirlwind":
				shake_intensity = 0.3
			"mage_meteor":
				shake_intensity = 0.4
			"rogue_dash":
				shake_intensity = 0.1
		
		var original_pos = camera.position
		camera.position += Vector3(randf_range(-shake_intensity, shake_intensity), 
								   randf_range(-shake_intensity, shake_intensity), 0)
		
		var tween = create_tween()
		tween.tween_property(camera, "position", original_pos, 0.1)
	
	# Create particle effect
	create_ability_particles(ability_id)

func create_ability_particles(ability_id: String):
	"""Create particle effects for abilities"""
	var particle_color = Color.WHITE
	var particle_size = 0.3
	
	match ability_id:
		"warrior_charge":
			particle_color = Color.ORANGE
		"warrior_shield":
			particle_color = Color.SILVER
		"warrior_berserker":
			particle_color = Color.RED
		"mage_fireball":
			particle_color = Color.ORANGE_RED
		"mage_heal":
			particle_color = Color.GREEN
		"mage_lightning":
			particle_color = Color.CYAN
		"rogue_dash":
			particle_color = Color.PURPLE
		"rogue_stealth":
			particle_color = Color.DARK_GRAY
		"rogue_poison":
			particle_color = Color.LIME_GREEN
	
	# Create particle indicator
	var indicator = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = particle_size
	sphere.height = particle_size * 2
	indicator.mesh = sphere
	
	var material = StandardMaterial3D.new()
	material.albedo_color = particle_color
	material.emission_enabled = true
	material.emission = particle_color * 0.8
	indicator.material_override = material
	
	indicator.position = position + Vector3(0, 1.5, 0)
	get_parent().add_child(indicator)
	
	# Animate particle
	var tween = create_tween()
	tween.parallel().tween_property(indicator, "scale", Vector3.ZERO, 0.5)
	tween.parallel().tween_property(indicator, "position:y", indicator.position.y + 2, 0.5)
	tween.tween_callback(indicator.queue_free)

func toggle_skill_tree_ui():
	"""Toggle skill tree UI (placeholder)"""
	print("Skill tree UI toggle requested")
	# This would show/hide the skill tree UI when implemented

# Companion Coordination Methods

func issue_companion_command(command_name: String):
	"""Issue a command to companions via string name"""
	if not companion_coordinator:
		return
	
	var command = CompanionCoordinator.CompanionCommand.FOLLOW
	match command_name:
		"follow":
			command = CompanionCoordinator.CompanionCommand.FOLLOW
		"hold":
			command = CompanionCoordinator.CompanionCommand.HOLD
		"attack":
			command = CompanionCoordinator.CompanionCommand.ATTACK
		"defend":
			command = CompanionCoordinator.CompanionCommand.DEFEND
		"retreat":
			command = CompanionCoordinator.CompanionCommand.RETREAT
		"ability":
			command = CompanionCoordinator.CompanionCommand.ABILITY
	
	companion_coordinator.issue_command(command)

func cycle_formation():
	"""Cycle through available formations"""
	if companion_coordinator:
		companion_coordinator.cycle_formation()

# Combat System Visual Effects

func create_perfect_dodge_visual_effect():
	"""Create visual effect for perfect dodge"""
	var effect = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.8
	sphere.height = 1.6
	effect.mesh = sphere
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.GOLD
	material.emission_enabled = true
	material.emission = Color.GOLD * 1.2
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	effect.material_override = material
	
	effect.position = position + Vector3(0, 1.0, 0)
	get_parent().add_child(effect)
	
	var tween = create_tween()
	tween.parallel().tween_property(effect, "scale", Vector3(1.5, 1.5, 1.5), 0.4)
	tween.parallel().tween_property(material, "albedo_color:a", 0.0, 0.4)
	tween.tween_callback(effect.queue_free)

func create_block_visual_effect():
	"""Create visual effect for blocking"""
	var effect = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(1.8, 1.8, 0.1)
	effect.mesh = box
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.CYAN
	material.emission_enabled = true
	material.emission = Color.CYAN * 0.6
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color.a = 0.8
	effect.material_override = material
	
	effect.position = position + Vector3(0, 1.0, -0.8)
	effect.name = "PlayerBlockEffect"
	add_child(effect)

func end_block_visual_effect():
	"""End block visual effect"""
	var effect = get_node_or_null("PlayerBlockEffect")
	if effect:
		var tween = create_tween()
		tween.tween_property(effect.material_override, "albedo_color:a", 0.0, 0.2)
		tween.tween_callback(effect.queue_free)

func create_perfect_dodge_celebration_effect():
	"""Create celebration effect for perfect dodge achievement"""
	# Create multiple particle bursts
	for i in range(5):
		var effect = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		sphere.radius = 0.3
		sphere.height = 0.6
		effect.mesh = sphere
		
		var material = StandardMaterial3D.new()
		material.albedo_color = Color.YELLOW
		material.emission_enabled = true
		material.emission = Color.YELLOW * 1.5
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		effect.material_override = material
		
		var offset = Vector3(randf_range(-1.0, 1.0), randf_range(0.5, 2.0), randf_range(-1.0, 1.0))
		effect.position = position + offset
		get_parent().add_child(effect)
		
		var tween = create_tween()
		tween.parallel().tween_property(effect, "position:y", effect.position.y + 2.0, 0.6)
		tween.parallel().tween_property(material, "albedo_color:a", 0.0, 0.6)
		tween.tween_callback(effect.queue_free)

func create_invincibility_visual_effect():
	"""Create visual effect for invincibility frames"""
	var effect = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 1.2
	sphere.height = 2.4
	effect.mesh = sphere
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.WHITE
	material.emission_enabled = true
	material.emission = Color.WHITE * 0.8
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color.a = 0.3
	effect.material_override = material
	
	effect.position = position
	effect.name = "PlayerInvincibilityEffect"
	add_child(effect)
	
	# Pulsing animation
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(material, "emission", Color.WHITE * 1.2, 0.1)
	tween.tween_property(material, "emission", Color.WHITE * 0.4, 0.1)

func end_invincibility_visual_effect():
	"""End invincibility visual effect"""
	var effect = get_node_or_null("PlayerInvincibilityEffect")
	if effect:
		var tween = create_tween()
		tween.tween_property(effect.material_override, "albedo_color:a", 0.0, 0.2)
		tween.tween_callback(effect.queue_free)

# Combat System Methods

func test_combat_dodge(direction: String = "left"):
	"""Test method for combat dodge system"""
	if combat_controller:
		# Register a test attack first
		combat_controller.test_incoming_attack("frontal")
		
		# Wait a moment then try to dodge
		await get_tree().create_timer(0.8).timeout
		
		var dodge_dir = CombatController.DodgeDirection.LEFT
		match direction:
			"left":
				dodge_dir = CombatController.DodgeDirection.LEFT
			"right":
				dodge_dir = CombatController.DodgeDirection.RIGHT
			"backward":
				dodge_dir = CombatController.DodgeDirection.BACKWARD
		
		combat_controller.attempt_dodge(dodge_dir)

func test_combat_block():
	"""Test method for combat block system"""
	if combat_controller:
		combat_controller.start_block()
		
		# End block after 1 second
		await get_tree().create_timer(1.0).timeout
		combat_controller.end_block(true)

func is_invincible() -> bool:
	"""Check if player is currently invincible"""
	if combat_controller:
		return combat_controller.is_invincible()
	return false

func is_dodging() -> bool:
	"""Check if player is currently dodging"""
	if combat_controller:
		return combat_controller.is_dodging()
	return false

func register_incoming_attack(attack_id: String, telegraph_time: float, damage: float, attack_type: String, required_dodge_direction: String):
	"""Register an incoming attack for the combat system"""
	if not combat_controller:
		return
	
	var dodge_dir = CombatController.DodgeDirection.BACKWARD
	match required_dodge_direction:
		"left":
			dodge_dir = CombatController.DodgeDirection.LEFT
		"right":
			dodge_dir = CombatController.DodgeDirection.RIGHT
		"backward":
			dodge_dir = CombatController.DodgeDirection.BACKWARD
	
	combat_controller.register_incoming_attack(attack_id, telegraph_time, damage, attack_type, dodge_dir)
