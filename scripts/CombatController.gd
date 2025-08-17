extends Node
class_name CombatController

## Enhanced Combat Controller with Dodge and Block Mechanics
## Extends existing lane-based movement with tactical combat actions

signal dodge_performed(direction: String, perfect: bool)
signal block_started()
signal block_ended(successful: bool)
signal perfect_dodge_achieved(bonus_reward: int)
signal invincibility_started(duration: float)
signal invincibility_ended()
signal stamina_depleted()

enum DodgeDirection { LEFT, RIGHT, BACKWARD }
enum CombatState { NORMAL, DODGING, BLOCKING, INVINCIBLE }

# Combat settings
@export var perfect_dodge_window: float = 0.2  # Perfect dodge timing window in seconds
@export var dodge_duration: float = 0.3  # How long dodge animation lasts
@export var dodge_distance: float = 1.5  # Distance moved during dodge
@export var invincibility_duration: float = 0.15  # Invincibility frames after perfect dodge
@export var block_stamina_cost: float = 10.0  # Stamina cost per second while blocking
@export var dodge_stamina_cost: float = 15.0  # Stamina cost per dodge
@export var perfect_dodge_bonus: int = 50  # Bonus points for perfect dodge

# Block system settings
@export var block_damage_reduction: float = 0.7  # 70% damage reduction when blocking
@export var perfect_block_window: float = 0.3  # Perfect block timing window
@export var perfect_block_reduction: float = 0.9  # 90% damage reduction for perfect block

# Internal state
var current_state: CombatState = CombatState.NORMAL
var dodge_timer: float = 0.0
var invincibility_timer: float = 0.0
var block_timer: float = 0.0
var is_blocking: bool = false
var dodge_direction: DodgeDirection
var original_position: Vector3

# References
var player: RPGPlayer3D
var mobile_input_manager: MobileInputManager
var incoming_attacks: Array[AttackData] = []

# Perfect dodge tracking
var last_attack_time: float = 0.0
var dodge_timing_window_active: bool = false

class AttackData:
	var attack_id: String
	var telegraph_time: float  # Time before attack hits
	var damage: float
	var attack_type: String  # "frontal", "side_left", "side_right", "area"
	var perfect_dodge_direction: DodgeDirection
	var creation_time: float
	
	func _init(id: String, telegraph: float, dmg: float, type: String, dodge_dir: DodgeDirection):
		attack_id = id
		telegraph_time = telegraph
		damage = dmg
		attack_type = type
		perfect_dodge_direction = dodge_dir
		creation_time = Time.get_unix_time_from_system()

func _ready():
	# Find player reference
	player = get_parent() as RPGPlayer3D
	if not player:
		player = get_tree().get_first_node_in_group("rpg_player") as RPGPlayer3D
	
	if not player:
		push_error("CombatController: Could not find RPGPlayer3D reference")
		return
	
	# Find mobile input manager (it's an autoload)
	mobile_input_manager = get_node("/root/MobileInputManager")
	if mobile_input_manager:
		mobile_input_manager.gesture_detected.connect(_on_gesture_detected)
		print("CombatController: Connected to mobile input manager")
	else:
		print("CombatController: Mobile input manager not found, using keyboard only")
	
	# Store original position
	original_position = player.position
	
	print("CombatController initialized with dodge and block mechanics")
	print("  - Perfect dodge window: ", perfect_dodge_window, "s")
	print("  - Dodge duration: ", dodge_duration, "s")
	print("  - Invincibility duration: ", invincibility_duration, "s")
	print("  - Block damage reduction: ", block_damage_reduction * 100, "%")
	print("  - Combat controls: Z/X/N for dodge, Space for block")

func _process(delta):
	update_combat_state(delta)
	process_incoming_attacks(delta)
	handle_keyboard_input()

func update_combat_state(delta):
	"""Update combat state timers and transitions"""
	match current_state:
		CombatState.DODGING:
			dodge_timer -= delta
			if dodge_timer <= 0:
				end_dodge()
		
		CombatState.INVINCIBLE:
			invincibility_timer -= delta
			if invincibility_timer <= 0:
				end_invincibility()
		
		CombatState.BLOCKING:
			if is_blocking:
				block_timer += delta
				# Consume stamina while blocking
				if player.can_use_stamina(block_stamina_cost * delta):
					player.use_stamina(block_stamina_cost * delta)
				else:
					# Out of stamina, stop blocking
					end_block(false)
					stamina_depleted.emit()

func process_incoming_attacks(delta):
	"""Process telegraphed attacks and check for perfect dodge opportunities"""
	var current_time = Time.get_unix_time_from_system()
	
	for i in range(incoming_attacks.size() - 1, -1, -1):
		var attack = incoming_attacks[i]
		var time_since_creation = current_time - attack.creation_time
		
		# Check if attack should hit now
		if time_since_creation >= attack.telegraph_time:
			execute_attack(attack)
			incoming_attacks.remove_at(i)
		# Check if we're in perfect dodge window
		elif time_since_creation >= (attack.telegraph_time - perfect_dodge_window):
			dodge_timing_window_active = true
			last_attack_time = current_time

func handle_keyboard_input():
	"""Handle keyboard input for combat actions"""
	if not player:
		return
	
	# Dodge inputs (WASD for dodge directions)
	if Input.is_action_just_pressed("dodge_left") or Input.is_action_just_pressed("move_left"):
		attempt_dodge(DodgeDirection.LEFT)
	elif Input.is_action_just_pressed("dodge_right") or Input.is_action_just_pressed("move_right"):
		attempt_dodge(DodgeDirection.RIGHT)
	elif Input.is_action_just_pressed("dodge_backward") or Input.is_action_just_pressed("move_backward"):
		attempt_dodge(DodgeDirection.BACKWARD)
	
	# Block input (hold Shift or Space)
	if Input.is_action_pressed("block") or Input.is_action_pressed("slide"):
		if not is_blocking and current_state == CombatState.NORMAL:
			start_block()
	elif is_blocking:
		end_block(true)

func _on_gesture_detected(gesture_type: MobileInputManager.GestureType, position: Vector2):
	"""Handle mobile gesture input for combat actions"""
	match gesture_type:
		MobileInputManager.GestureType.SWIPE_LEFT:
			attempt_dodge(DodgeDirection.LEFT)
		MobileInputManager.GestureType.SWIPE_RIGHT:
			attempt_dodge(DodgeDirection.RIGHT)
		MobileInputManager.GestureType.SWIPE_DOWN:
			attempt_dodge(DodgeDirection.BACKWARD)
		MobileInputManager.GestureType.LONG_PRESS:
			if not is_blocking and current_state == CombatState.NORMAL:
				start_block()
		MobileInputManager.GestureType.TAP:
			if is_blocking:
				end_block(true)

func attempt_dodge(direction: DodgeDirection) -> bool:
	"""Attempt to perform a dodge in the specified direction"""
	if current_state != CombatState.NORMAL and current_state != CombatState.BLOCKING:
		return false
	
	if not player.can_use_stamina(dodge_stamina_cost):
		print("CombatController: Not enough stamina to dodge")
		return false
	
	# End blocking if currently blocking
	if is_blocking:
		end_block(false)
	
	# Check for perfect dodge
	var is_perfect = check_perfect_dodge_timing(direction)
	
	# Execute dodge
	execute_dodge(direction, is_perfect)
	
	return true

func check_perfect_dodge_timing(direction: DodgeDirection) -> bool:
	"""Check if this dodge qualifies as a perfect dodge"""
	if not dodge_timing_window_active:
		return false
	
	var current_time = Time.get_unix_time_from_system()
	var time_since_attack = current_time - last_attack_time
	
	# Check if we're within the perfect dodge window
	if time_since_attack <= perfect_dodge_window:
		# Check if dodge direction matches the required direction for any incoming attack
		for attack in incoming_attacks:
			if attack.perfect_dodge_direction == direction:
				return true
	
	return false

func execute_dodge(direction: DodgeDirection, is_perfect: bool):
	"""Execute the dodge movement and effects"""
	current_state = CombatState.DODGING
	dodge_direction = direction
	dodge_timer = dodge_duration
	
	# Use stamina
	player.use_stamina(dodge_stamina_cost)
	
	# Calculate dodge movement
	var dodge_vector = Vector3.ZERO
	match direction:
		DodgeDirection.LEFT:
			dodge_vector = Vector3(-dodge_distance, 0, 0)
		DodgeDirection.RIGHT:
			dodge_vector = Vector3(dodge_distance, 0, 0)
		DodgeDirection.BACKWARD:
			dodge_vector = Vector3(0, 0, dodge_distance)
	
	# Apply dodge movement
	apply_dodge_movement(dodge_vector)
	
	# Handle perfect dodge
	if is_perfect:
		handle_perfect_dodge()
	
	# Emit signals
	dodge_performed.emit(get_dodge_direction_string(direction), is_perfect)
	
	# Trigger haptic feedback
	if mobile_input_manager:
		var intensity = 0.3 if not is_perfect else 0.5
		mobile_input_manager.trigger_haptic_feedback(intensity, 0.1)
	
	print("CombatController: Executed ", "perfect " if is_perfect else "", "dodge ", get_dodge_direction_string(direction))

func apply_dodge_movement(dodge_vector: Vector3):
	"""Apply dodge movement to player while respecting lane boundaries"""
	if not player:
		return
	
	# Calculate new position
	var new_position = player.position + dodge_vector
	
	# Clamp to lane boundaries for left/right dodges
	if dodge_direction == DodgeDirection.LEFT or dodge_direction == DodgeDirection.RIGHT:
		# Find closest valid lane
		var closest_lane = 1  # Default to center
		var min_distance = 999.0
		
		for i in range(player.LANE_POSITIONS.size()):
			var distance = abs(new_position.x - player.LANE_POSITIONS[i])
			if distance < min_distance:
				min_distance = distance
				closest_lane = i
		
		# Update player lane and target
		player.current_lane = closest_lane
		player.target_x = player.LANE_POSITIONS[closest_lane]
		
		print("CombatController: Dodge moved player to lane ", closest_lane)
	
	# For backward dodges, adjust row if possible
	elif dodge_direction == DodgeDirection.BACKWARD:
		if player.current_row > 0:
			player.current_row -= 1
			player.target_z = player.ROW_POSITIONS[player.current_row]
			print("CombatController: Dodge moved player to row ", player.current_row)

func handle_perfect_dodge():
	"""Handle perfect dodge effects and rewards"""
	# Grant invincibility frames
	current_state = CombatState.INVINCIBLE
	invincibility_timer = invincibility_duration
	
	# Award bonus points
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	if game_manager and game_manager.has_method("perfect_dodge"):
		game_manager.perfect_dodge()
	
	# Emit perfect dodge signal
	perfect_dodge_achieved.emit(perfect_dodge_bonus)
	invincibility_started.emit(invincibility_duration)
	
	# Create visual effect
	create_perfect_dodge_effect()
	
	print("CombatController: PERFECT DODGE! Granted ", invincibility_duration, "s invincibility")

func start_block():
	"""Start blocking state"""
	if current_state != CombatState.NORMAL:
		return
	
	current_state = CombatState.BLOCKING
	is_blocking = true
	block_timer = 0.0
	
	# Emit signal
	block_started.emit()
	
	# Trigger haptic feedback
	if mobile_input_manager:
		mobile_input_manager.trigger_haptic_feedback(0.4, 0.15)
	
	# Create visual effect
	create_block_effect()
	
	print("CombatController: Started blocking")

func end_block(voluntary: bool):
	"""End blocking state"""
	if not is_blocking:
		return
	
	is_blocking = false
	current_state = CombatState.NORMAL
	
	# Check if this was a successful block (blocked an attack)
	var successful = check_successful_block()
	
	# Emit signal
	block_ended.emit(successful)
	
	# End visual effect
	end_block_effect()
	
	print("CombatController: Ended blocking (", "voluntary" if voluntary else "forced", ", successful: ", successful, ")")

func check_successful_block() -> bool:
	"""Check if the block successfully blocked an incoming attack"""
	# This would be called when an attack hits during blocking
	# For now, return true if we blocked for a reasonable duration
	return block_timer >= 0.1

func end_dodge():
	"""End dodge state and return to normal"""
	current_state = CombatState.NORMAL
	dodge_timer = 0.0
	dodge_timing_window_active = false
	
	print("CombatController: Dodge ended, returning to normal state")

func end_invincibility():
	"""End invincibility state"""
	current_state = CombatState.NORMAL
	invincibility_timer = 0.0
	
	# Emit signal
	invincibility_ended.emit()
	
	print("CombatController: Invincibility ended")

func execute_attack(attack: AttackData):
	"""Execute an incoming attack and check for blocks/dodges"""
	if not player:
		return
	
	var damage_taken = attack.damage
	var attack_blocked = false
	var attack_dodged = false
	
	# Check if player is invincible
	if current_state == CombatState.INVINCIBLE:
		print("CombatController: Attack ", attack.attack_id, " blocked by invincibility frames")
		return
	
	# Check if player is blocking
	if is_blocking:
		attack_blocked = true
		var damage_reduction = block_damage_reduction
		
		# Check for perfect block
		if block_timer <= perfect_block_window:
			damage_reduction = perfect_block_reduction
			print("CombatController: PERFECT BLOCK!")
			create_perfect_block_effect()
		
		damage_taken *= (1.0 - damage_reduction)
		print("CombatController: Attack blocked! Damage reduced from ", attack.damage, " to ", damage_taken)
	
	# Check if player is dodging in the correct direction
	elif current_state == CombatState.DODGING:
		if dodge_direction == attack.perfect_dodge_direction:
			attack_dodged = true
			damage_taken = 0.0
			print("CombatController: Attack dodged successfully!")
		else:
			print("CombatController: Wrong dodge direction, taking partial damage")
			damage_taken *= 0.5  # Partial damage for wrong dodge direction
	
	# Apply damage if any
	if damage_taken > 0:
		player.take_damage(damage_taken)
		create_damage_effect(attack.attack_type, damage_taken)
	
	# Create attack effect
	create_attack_effect(attack)

func register_incoming_attack(attack_id: String, telegraph_time: float, damage: float, attack_type: String, required_dodge_direction: DodgeDirection):
	"""Register an incoming telegraphed attack"""
	var attack = AttackData.new(attack_id, telegraph_time, damage, attack_type, required_dodge_direction)
	incoming_attacks.append(attack)
	
	print("CombatController: Registered incoming attack '", attack_id, "' - telegraph: ", telegraph_time, "s, damage: ", damage, ", dodge: ", get_dodge_direction_string(required_dodge_direction))

func get_dodge_direction_string(direction: DodgeDirection) -> String:
	"""Convert dodge direction enum to string"""
	match direction:
		DodgeDirection.LEFT:
			return "left"
		DodgeDirection.RIGHT:
			return "right"
		DodgeDirection.BACKWARD:
			return "backward"
		_:
			return "unknown"

func is_invincible() -> bool:
	"""Check if player is currently invincible"""
	return current_state == CombatState.INVINCIBLE

func is_dodging() -> bool:
	"""Check if player is currently dodging"""
	return current_state == CombatState.DODGING

func get_current_state() -> CombatState:
	"""Get current combat state"""
	return current_state

# Visual Effects Methods

func create_perfect_dodge_effect():
	"""Create visual effect for perfect dodge"""
	if not player:
		return
	
	# Create glowing particle effect
	var effect = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	effect.mesh = sphere
	
	# Create glowing material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.GOLD
	material.emission_enabled = true
	material.emission = Color.GOLD * 1.5
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	effect.material_override = material
	
	effect.position = player.position
	player.get_parent().add_child(effect)
	
	# Animate effect
	var tween = create_tween()
	tween.parallel().tween_property(effect, "scale", Vector3(2.0, 2.0, 2.0), 0.3)
	tween.parallel().tween_property(material, "albedo_color:a", 0.0, 0.3)
	tween.tween_callback(effect.queue_free)

func create_block_effect():
	"""Create visual effect for blocking"""
	if not player:
		return
	
	# Create shield-like effect in front of player
	var effect = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(2.0, 2.0, 0.2)
	effect.mesh = box
	
	# Create shield material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.CYAN
	material.emission_enabled = true
	material.emission = Color.CYAN * 0.5
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color.a = 0.7
	effect.material_override = material
	
	effect.position = player.position + Vector3(0, 0, -1.0)
	effect.name = "BlockEffect"
	player.add_child(effect)

func end_block_effect():
	"""End block visual effect"""
	if not player:
		return
	
	var effect = player.get_node_or_null("BlockEffect")
	if effect:
		effect.queue_free()

func create_perfect_block_effect():
	"""Create visual effect for perfect block"""
	if not player:
		return
	
	# Create bright flash effect
	var effect = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 1.5
	sphere.height = 3.0
	effect.mesh = sphere
	
	# Create bright material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.WHITE
	material.emission_enabled = true
	material.emission = Color.WHITE * 2.0
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	effect.material_override = material
	
	effect.position = player.position
	player.get_parent().add_child(effect)
	
	# Quick flash animation
	var tween = create_tween()
	tween.tween_property(material, "albedo_color:a", 0.0, 0.2)
	tween.tween_callback(effect.queue_free)

func create_damage_effect(attack_type: String, damage: float):
	"""Create visual effect for taking damage"""
	print("CombatController: Creating damage effect for ", attack_type, " (", damage, " damage)")
	# This would create screen shake, red flash, etc.

func create_attack_effect(attack: AttackData):
	"""Create visual effect for incoming attack"""
	print("CombatController: Creating attack effect for ", attack.attack_id)
	# This would create attack animations, screen effects, etc.

# Debug Methods

func debug_combat_state():
	"""Print debug information about combat state"""
	print("=== COMBAT CONTROLLER DEBUG ===")
	print("Current State: ", current_state)
	print("Is Blocking: ", is_blocking)
	print("Dodge Timer: ", dodge_timer)
	print("Invincibility Timer: ", invincibility_timer)
	print("Block Timer: ", block_timer)
	print("Incoming Attacks: ", incoming_attacks.size())
	print("Dodge Timing Window Active: ", dodge_timing_window_active)
	print("================================")

# Test Methods for Development

func test_incoming_attack(attack_type: String = "frontal"):
	"""Test method to simulate an incoming attack"""
	var dodge_dir = DodgeDirection.BACKWARD
	match attack_type:
		"side_left":
			dodge_dir = DodgeDirection.RIGHT
		"side_right":
			dodge_dir = DodgeDirection.LEFT
		"frontal":
			dodge_dir = DodgeDirection.BACKWARD
	
	register_incoming_attack("test_attack", 1.0, 25.0, attack_type, dodge_dir)
	print("CombatController: Test attack registered - ", attack_type)