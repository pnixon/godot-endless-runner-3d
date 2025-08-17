extends Node
class_name EnemyAttackSystem

## Enemy Attack System with Telegraphed Attacks
## Manages enemy attack patterns, telegraphing, and dodge requirements

signal attack_telegraphed(attack_data: AttackData)
signal attack_executed(attack_data: AttackData)
signal attack_pattern_started(pattern_id: String)
signal attack_pattern_completed(pattern_id: String)

# Attack pattern database
var attack_patterns: Dictionary = {}
var active_attacks: Array[AttackData] = []
var current_pattern: AttackPattern = null
var pattern_timer: float = 0.0

# Visual and audio components
var telegraph_effects: Array[Node3D] = []
var audio_player: AudioStreamPlayer3D

# References
var player: RPGPlayer3D

class AttackData:
	var attack_id: String
	var telegraph_time: float
	var damage: float
	var attack_type: AttackType
	var required_dodge_direction: CombatController.DodgeDirection
	var visual_cue: String
	var audio_cue: String
	var creation_time: float
	var telegraph_position: Vector3
	var attack_area: Vector3  # Size of attack area
	
	func _init(id: String, telegraph: float, dmg: float, type: AttackType, dodge_dir: CombatController.DodgeDirection):
		attack_id = id
		telegraph_time = telegraph
		damage = dmg
		attack_type = type
		required_dodge_direction = dodge_dir
		creation_time = Time.get_unix_time_from_system()
		visual_cue = get_default_visual_cue(type)
		audio_cue = get_default_audio_cue(type)
		attack_area = get_default_attack_area(type)
	
	func get_default_visual_cue(type: AttackType) -> String:
		match type:
			AttackType.FRONTAL:
				return "frontal_telegraph"
			AttackType.SIDE_LEFT:
				return "side_left_telegraph"
			AttackType.SIDE_RIGHT:
				return "side_right_telegraph"
			AttackType.AREA:
				return "area_telegraph"
			AttackType.OVERHEAD:
				return "overhead_telegraph"
			_:
				return "default_telegraph"
	
	func get_default_audio_cue(type: AttackType) -> String:
		match type:
			AttackType.FRONTAL:
				return "frontal_windup"
			AttackType.SIDE_LEFT, AttackType.SIDE_RIGHT:
				return "side_windup"
			AttackType.AREA:
				return "area_windup"
			AttackType.OVERHEAD:
				return "overhead_windup"
			_:
				return "default_windup"
	
	func get_default_attack_area(type: AttackType) -> Vector3:
		match type:
			AttackType.FRONTAL:
				return Vector3(1.0, 2.0, 2.0)  # Wide frontal attack
			AttackType.SIDE_LEFT, AttackType.SIDE_RIGHT:
				return Vector3(3.0, 2.0, 1.0)  # Wide side swipe
			AttackType.AREA:
				return Vector3(4.0, 2.0, 4.0)  # Large area attack
			AttackType.OVERHEAD:
				return Vector3(1.5, 3.0, 1.5)  # Overhead slam
			_:
				return Vector3(1.0, 1.0, 1.0)

class AttackPattern:
	var pattern_id: String
	var attacks: Array[AttackData]
	var timing_sequence: Array[float]  # When each attack should trigger
	var loop_pattern: bool = false
	var current_attack_index: int = 0
	var pattern_duration: float = 0.0
	
	func _init(id: String, attack_list: Array[AttackData], timings: Array[float], should_loop: bool = false):
		pattern_id = id
		attacks = attack_list
		timing_sequence = timings
		loop_pattern = should_loop
		
		# Calculate total pattern duration
		if timing_sequence.size() > 0:
			pattern_duration = timing_sequence.max()

enum AttackType {
	FRONTAL,      # Straight forward attack - dodge backward
	SIDE_LEFT,    # Attack from left side - dodge right
	SIDE_RIGHT,   # Attack from right side - dodge left
	AREA,         # Area of effect attack - dodge to specific safe zone
	OVERHEAD,     # Overhead slam - dodge to sides
	COMBO_SEQUENCE, # Multi-hit combo requiring multiple dodges
	BOSS_SPECIAL   # Special boss attack with unique mechanics
}

enum EnemyType {
	BASIC_MELEE,
	RANGED_ARCHER,
	HEAVY_BRUISER,
	AGILE_ROGUE,
	MAGE_CASTER,
	BOSS_TIER_1,
	BOSS_TIER_2,
	BOSS_FINAL
}

func _ready():
	# Find player reference
	player = get_tree().get_first_node_in_group("rpg_player") as RPGPlayer3D
	
	# Set up audio player
	audio_player = AudioStreamPlayer3D.new()
	audio_player.name = "AttackAudioPlayer"
	add_child(audio_player)
	
	# Initialize attack patterns database
	initialize_attack_patterns()
	
	print("EnemyAttackSystem initialized with ", attack_patterns.size(), " attack patterns")
	if player:
		print("EnemyAttackSystem: Found player for combat integration")
	else:
		print("EnemyAttackSystem: WARNING - No player found!")

func _process(delta):
	update_active_attacks(delta)
	update_current_pattern(delta)
	update_telegraph_effects(delta)

func initialize_attack_patterns():
	"""Initialize the database of attack patterns for different enemy types"""
	
	# Basic Melee Enemy Patterns
	create_basic_melee_patterns()
	
	# Ranged Archer Patterns
	create_ranged_archer_patterns()
	
	# Heavy Bruiser Patterns
	create_heavy_bruiser_patterns()
	
	# Agile Rogue Patterns
	create_agile_rogue_patterns()
	
	# Mage Caster Patterns
	create_mage_caster_patterns()
	
	# Boss Patterns
	create_boss_patterns()
	
	print("Attack patterns initialized: ", attack_patterns.keys())

func create_basic_melee_patterns():
	"""Create attack patterns for basic melee enemies"""
	
	# Simple frontal attack
	var frontal_attack = AttackData.new("basic_slash", 1.5, 20.0, AttackType.FRONTAL, CombatController.DodgeDirection.BACKWARD)
	var pattern = AttackPattern.new("basic_melee_simple", [frontal_attack], [0.0])
	attack_patterns["basic_melee_simple"] = pattern
	
	# Left-right combo
	var left_swipe = AttackData.new("left_swipe", 1.2, 15.0, AttackType.SIDE_LEFT, CombatController.DodgeDirection.RIGHT)
	var right_swipe = AttackData.new("right_swipe", 1.2, 15.0, AttackType.SIDE_RIGHT, CombatController.DodgeDirection.LEFT)
	var combo_pattern = AttackPattern.new("basic_melee_combo", [left_swipe, right_swipe], [0.0, 2.0])
	attack_patterns["basic_melee_combo"] = combo_pattern

func create_ranged_archer_patterns():
	"""Create attack patterns for ranged archer enemies"""
	
	# Single arrow shot
	var arrow_shot = AttackData.new("arrow_shot", 2.0, 18.0, AttackType.FRONTAL, CombatController.DodgeDirection.LEFT)
	arrow_shot.visual_cue = "arrow_telegraph"
	arrow_shot.audio_cue = "bow_draw"
	var pattern = AttackPattern.new("archer_single_shot", [arrow_shot], [0.0])
	attack_patterns["archer_single_shot"] = pattern
	
	# Triple arrow volley
	var arrow1 = AttackData.new("arrow_volley_1", 2.5, 12.0, AttackType.SIDE_LEFT, CombatController.DodgeDirection.RIGHT)
	var arrow2 = AttackData.new("arrow_volley_2", 2.5, 12.0, AttackType.FRONTAL, CombatController.DodgeDirection.BACKWARD)
	var arrow3 = AttackData.new("arrow_volley_3", 2.5, 12.0, AttackType.SIDE_RIGHT, CombatController.DodgeDirection.LEFT)
	var volley_pattern = AttackPattern.new("archer_triple_volley", [arrow1, arrow2, arrow3], [0.0, 0.5, 1.0])
	attack_patterns["archer_triple_volley"] = volley_pattern

func create_heavy_bruiser_patterns():
	"""Create attack patterns for heavy bruiser enemies"""
	
	# Overhead slam
	var overhead_slam = AttackData.new("overhead_slam", 2.5, 35.0, AttackType.OVERHEAD, CombatController.DodgeDirection.LEFT)
	overhead_slam.visual_cue = "slam_telegraph"
	overhead_slam.audio_cue = "heavy_windup"
	var pattern = AttackPattern.new("bruiser_slam", [overhead_slam], [0.0])
	attack_patterns["bruiser_slam"] = pattern
	
	# Ground pound area attack
	var ground_pound = AttackData.new("ground_pound", 3.0, 40.0, AttackType.AREA, CombatController.DodgeDirection.BACKWARD)
	ground_pound.visual_cue = "area_telegraph"
	ground_pound.audio_cue = "ground_pound_windup"
	ground_pound.attack_area = Vector3(5.0, 2.0, 5.0)  # Large area
	var area_pattern = AttackPattern.new("bruiser_ground_pound", [ground_pound], [0.0])
	attack_patterns["bruiser_ground_pound"] = area_pattern

func create_agile_rogue_patterns():
	"""Create attack patterns for agile rogue enemies"""
	
	# Quick side dash attack
	var dash_left = AttackData.new("dash_left", 0.8, 22.0, AttackType.SIDE_LEFT, CombatController.DodgeDirection.RIGHT)
	dash_left.visual_cue = "dash_telegraph"
	dash_left.audio_cue = "dash_windup"
	var pattern = AttackPattern.new("rogue_dash_left", [dash_left], [0.0])
	attack_patterns["rogue_dash_left"] = pattern
	
	# Multi-hit combo sequence
	var combo1 = AttackData.new("rogue_combo_1", 1.0, 12.0, AttackType.SIDE_LEFT, CombatController.DodgeDirection.RIGHT)
	var combo2 = AttackData.new("rogue_combo_2", 0.8, 12.0, AttackType.SIDE_RIGHT, CombatController.DodgeDirection.LEFT)
	var combo3 = AttackData.new("rogue_combo_3", 1.2, 15.0, AttackType.FRONTAL, CombatController.DodgeDirection.BACKWARD)
	var combo_pattern = AttackPattern.new("rogue_triple_combo", [combo1, combo2, combo3], [0.0, 1.2, 2.5])
	attack_patterns["rogue_triple_combo"] = combo_pattern

func create_mage_caster_patterns():
	"""Create attack patterns for mage caster enemies"""
	
	# Fireball spell
	var fireball = AttackData.new("fireball", 2.8, 25.0, AttackType.FRONTAL, CombatController.DodgeDirection.LEFT)
	fireball.visual_cue = "fireball_telegraph"
	fireball.audio_cue = "spell_charge"
	var pattern = AttackPattern.new("mage_fireball", [fireball], [0.0])
	attack_patterns["mage_fireball"] = pattern
	
	# Lightning storm area attack
	var lightning = AttackData.new("lightning_storm", 3.5, 30.0, AttackType.AREA, CombatController.DodgeDirection.BACKWARD)
	lightning.visual_cue = "lightning_telegraph"
	lightning.audio_cue = "storm_buildup"
	lightning.attack_area = Vector3(4.0, 3.0, 4.0)
	var storm_pattern = AttackPattern.new("mage_lightning_storm", [lightning], [0.0])
	attack_patterns["mage_lightning_storm"] = storm_pattern

func create_boss_patterns():
	"""Create complex attack patterns for boss enemies"""
	
	# Boss Tier 1: Three-phase attack
	var phase1 = AttackData.new("boss_phase1", 2.0, 30.0, AttackType.FRONTAL, CombatController.DodgeDirection.BACKWARD)
	var phase2 = AttackData.new("boss_phase2", 1.5, 25.0, AttackType.SIDE_LEFT, CombatController.DodgeDirection.RIGHT)
	var phase3 = AttackData.new("boss_phase3", 2.5, 35.0, AttackType.AREA, CombatController.DodgeDirection.LEFT)
	
	phase1.visual_cue = "boss_charge_telegraph"
	phase2.visual_cue = "boss_sweep_telegraph"
	phase3.visual_cue = "boss_area_telegraph"
	
	var boss_pattern = AttackPattern.new("boss_tier1_combo", [phase1, phase2, phase3], [0.0, 3.0, 6.0])
	attack_patterns["boss_tier1_combo"] = boss_pattern
	
	# Boss Tier 2: Complex multi-phase sequence
	var multi1 = AttackData.new("boss_multi1", 1.8, 20.0, AttackType.SIDE_LEFT, CombatController.DodgeDirection.RIGHT)
	var multi2 = AttackData.new("boss_multi2", 1.8, 20.0, AttackType.SIDE_RIGHT, CombatController.DodgeDirection.LEFT)
	var multi3 = AttackData.new("boss_multi3", 2.2, 40.0, AttackType.OVERHEAD, CombatController.DodgeDirection.BACKWARD)
	var multi4 = AttackData.new("boss_multi4", 3.0, 50.0, AttackType.AREA, CombatController.DodgeDirection.LEFT)
	
	var complex_pattern = AttackPattern.new("boss_tier2_complex", [multi1, multi2, multi3, multi4], [0.0, 2.0, 4.5, 7.0])
	attack_patterns["boss_tier2_complex"] = complex_pattern
	
	# Final Boss: Ultimate combo sequence
	var ultimate1 = AttackData.new("final_ultimate1", 2.5, 35.0, AttackType.FRONTAL, CombatController.DodgeDirection.BACKWARD)
	var ultimate2 = AttackData.new("final_ultimate2", 1.5, 25.0, AttackType.SIDE_LEFT, CombatController.DodgeDirection.RIGHT)
	var ultimate3 = AttackData.new("final_ultimate3", 1.5, 25.0, AttackType.SIDE_RIGHT, CombatController.DodgeDirection.LEFT)
	var ultimate4 = AttackData.new("final_ultimate4", 3.5, 60.0, AttackType.AREA, CombatController.DodgeDirection.BACKWARD)
	
	ultimate1.visual_cue = "final_boss_charge"
	ultimate2.visual_cue = "final_boss_left_sweep"
	ultimate3.visual_cue = "final_boss_right_sweep"
	ultimate4.visual_cue = "final_boss_ultimate"
	
	var ultimate_pattern = AttackPattern.new("final_boss_ultimate", [ultimate1, ultimate2, ultimate3, ultimate4], [0.0, 3.0, 4.5, 7.0])
	attack_patterns["final_boss_ultimate"] = ultimate_pattern

func start_attack_pattern(pattern_id: String, enemy_position: Vector3 = Vector3.ZERO) -> bool:
	"""Start executing an attack pattern"""
	if not attack_patterns.has(pattern_id):
		print("EnemyAttackSystem: Unknown attack pattern: ", pattern_id)
		return false
	
	current_pattern = attack_patterns[pattern_id]
	pattern_timer = 0.0
	current_pattern.current_attack_index = 0
	
	# Set telegraph positions relative to enemy
	for attack in current_pattern.attacks:
		attack.telegraph_position = enemy_position + get_attack_offset(attack.attack_type)
	
	attack_pattern_started.emit(pattern_id)
	print("EnemyAttackSystem: Started attack pattern '", pattern_id, "' with ", current_pattern.attacks.size(), " attacks")
	
	return true

func get_attack_offset(attack_type: AttackType) -> Vector3:
	"""Get position offset for attack telegraph based on attack type"""
	match attack_type:
		AttackType.FRONTAL:
			return Vector3(0, 0, -2.0)  # In front of enemy
		AttackType.SIDE_LEFT:
			return Vector3(-2.0, 0, 0)  # To the left
		AttackType.SIDE_RIGHT:
			return Vector3(2.0, 0, 0)   # To the right
		AttackType.OVERHEAD:
			return Vector3(0, 2.0, 0)   # Above
		AttackType.AREA:
			return Vector3(0, 0, 0)     # Centered on enemy
		_:
			return Vector3.ZERO

func update_current_pattern(delta: float):
	"""Update the current attack pattern execution"""
	if not current_pattern:
		return
	
	pattern_timer += delta
	
	# Check if we should trigger the next attack in the sequence
	if current_pattern.current_attack_index < current_pattern.timing_sequence.size():
		var next_attack_time = current_pattern.timing_sequence[current_pattern.current_attack_index]
		
		if pattern_timer >= next_attack_time:
			var attack = current_pattern.attacks[current_pattern.current_attack_index]
			telegraph_attack(attack)
			current_pattern.current_attack_index += 1
	
	# Check if pattern is complete
	if pattern_timer >= current_pattern.pattern_duration and current_pattern.current_attack_index >= current_pattern.attacks.size():
		if current_pattern.loop_pattern:
			# Restart the pattern
			pattern_timer = 0.0
			current_pattern.current_attack_index = 0
		else:
			# Pattern complete
			attack_pattern_completed.emit(current_pattern.pattern_id)
			current_pattern = null
			pattern_timer = 0.0

func telegraph_attack(attack: AttackData):
	"""Start telegraphing an attack"""
	active_attacks.append(attack)
	
	# Create visual telegraph effect
	create_telegraph_visual(attack)
	
	# Play audio cue
	play_attack_audio(attack.audio_cue)
	
	# Register with player's combat system
	if player and player.has_method("register_incoming_attack"):
		player.register_incoming_attack(
			attack.attack_id,
			attack.telegraph_time,
			attack.damage,
			get_attack_type_string(attack.attack_type),
			get_dodge_direction_string(attack.required_dodge_direction)
		)
		print("EnemyAttackSystem: Registered attack with player combat system")
	else:
		print("EnemyAttackSystem: WARNING - Cannot register attack, no player or combat system!")
	
	attack_telegraphed.emit(attack)
	print("EnemyAttackSystem: Telegraphed attack '", attack.attack_id, "' - dodge ", get_dodge_direction_string(attack.required_dodge_direction), " in ", attack.telegraph_time, "s")

func update_active_attacks(delta: float):
	"""Update all active telegraphed attacks"""
	for i in range(active_attacks.size() - 1, -1, -1):
		var attack = active_attacks[i]
		var elapsed_time = Time.get_unix_time_from_system() - attack.creation_time
		
		if elapsed_time >= attack.telegraph_time:
			# Attack should execute now
			execute_attack(attack)
			active_attacks.remove_at(i)

func execute_attack(attack: AttackData):
	"""Execute an attack that has finished telegraphing"""
	# Remove telegraph visual
	remove_telegraph_visual(attack)
	
	# Create attack execution effect
	create_attack_execution_visual(attack)
	
	# Play attack sound
	play_attack_audio("attack_hit")
	
	attack_executed.emit(attack)
	print("EnemyAttackSystem: Executed attack '", attack.attack_id, "'")

func create_telegraph_visual(attack: AttackData):
	"""Create visual telegraph effect for an attack"""
	var telegraph_effect = MeshInstance3D.new()
	telegraph_effect.name = "Telegraph_" + attack.attack_id
	
	# Create appropriate mesh based on attack type
	var mesh: Mesh
	var material = StandardMaterial3D.new()
	
	match attack.attack_type:
		AttackType.FRONTAL:
			mesh = BoxMesh.new()
			(mesh as BoxMesh).size = Vector3(2.0, 0.1, 3.0)
			material.albedo_color = Color.RED
		AttackType.SIDE_LEFT, AttackType.SIDE_RIGHT:
			mesh = BoxMesh.new()
			(mesh as BoxMesh).size = Vector3(4.0, 0.1, 1.5)
			material.albedo_color = Color.ORANGE
		AttackType.AREA:
			mesh = CylinderMesh.new()
			(mesh as CylinderMesh).top_radius = attack.attack_area.x / 2.0
			(mesh as CylinderMesh).bottom_radius = attack.attack_area.x / 2.0
			(mesh as CylinderMesh).height = 0.1
			material.albedo_color = Color.PURPLE
		AttackType.OVERHEAD:
			mesh = SphereMesh.new()
			(mesh as SphereMesh).radius = 1.0
			(mesh as SphereMesh).height = 2.0
			material.albedo_color = Color.YELLOW
		_:
			mesh = BoxMesh.new()
			material.albedo_color = Color.WHITE
	
	# Set up material properties
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color.a = 0.6
	material.emission_enabled = true
	material.emission = material.albedo_color * 0.5
	
	telegraph_effect.mesh = mesh
	telegraph_effect.material_override = material
	telegraph_effect.position = attack.telegraph_position
	
	# Add to scene
	get_tree().current_scene.add_child(telegraph_effect)
	telegraph_effects.append(telegraph_effect)
	
	# Animate the telegraph effect
	animate_telegraph_effect(telegraph_effect, attack.telegraph_time)

func animate_telegraph_effect(effect: MeshInstance3D, duration: float):
	"""Animate a telegraph effect with pulsing and intensity changes"""
	if not is_instance_valid(effect) or not effect.material_override:
		return
		
	# Store weak reference to avoid lambda capture issues
	var effect_ref = weakref(effect)
	var material_ref = weakref(effect.material_override)
	
	var tween = create_tween()
	tween.set_loops()
	
	# Pulsing alpha animation
	tween.tween_method(
		func(alpha: float): 
			var eff = effect_ref.get_ref()
			var mat = material_ref.get_ref()
			if eff and mat and is_instance_valid(eff) and eff.is_inside_tree():
				mat.albedo_color.a = alpha,
		0.3, 0.8, 0.5
	)
	tween.tween_method(
		func(alpha: float): 
			var eff = effect_ref.get_ref()
			var mat = material_ref.get_ref()
			if eff and mat and is_instance_valid(eff) and eff.is_inside_tree():
				mat.albedo_color.a = alpha,
		0.8, 0.3, 0.5
	)
	
	# Increase intensity as attack approaches
	var intensity_tween = create_tween()
	intensity_tween.tween_method(
		func(intensity: float):
			var eff = effect_ref.get_ref()
			var mat = material_ref.get_ref()
			if eff and mat and is_instance_valid(eff) and eff.is_inside_tree():
				mat.emission = mat.albedo_color * intensity,
		0.5, 2.0, duration
	)

func remove_telegraph_visual(attack: AttackData):
	"""Remove telegraph visual effect for an attack"""
	for i in range(telegraph_effects.size() - 1, -1, -1):
		var effect = telegraph_effects[i]
		if is_instance_valid(effect) and effect.name == "Telegraph_" + attack.attack_id:
			effect.queue_free()
			telegraph_effects.remove_at(i)
			break

func create_attack_execution_visual(attack: AttackData):
	"""Create visual effect when attack executes"""
	var execution_effect = MeshInstance3D.new()
	execution_effect.name = "Execution_" + attack.attack_id
	
	# Create flash effect
	var mesh = SphereMesh.new()
	mesh.radius = 1.5
	mesh.height = 3.0
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.WHITE
	material.emission_enabled = true
	material.emission = Color.WHITE * 2.0
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	execution_effect.mesh = mesh
	execution_effect.material_override = material
	execution_effect.position = attack.telegraph_position
	
	get_tree().current_scene.add_child(execution_effect)
	
	# Quick flash animation
	var tween = create_tween()
	tween.tween_property(material, "albedo_color:a", 0.0, 0.3)
	tween.tween_callback(execution_effect.queue_free)

func update_telegraph_effects(delta: float):
	"""Update all active telegraph effects"""
	# Clean up invalid effects
	for i in range(telegraph_effects.size() - 1, -1, -1):
		var effect = telegraph_effects[i]
		if not is_instance_valid(effect):
			telegraph_effects.remove_at(i)

func play_attack_audio(audio_cue: String):
	"""Play audio cue for attack"""
	if not audio_player:
		return
	
	# This would load and play appropriate audio files
	# For now, just print the audio cue
	print("EnemyAttackSystem: Playing audio cue: ", audio_cue)
	
	# In a full implementation, you would:
	# var audio_stream = load("res://audio/combat/" + audio_cue + ".ogg")
	# if audio_stream:
	#     audio_player.stream = audio_stream
	#     audio_player.play()

func get_attack_type_string(attack_type: AttackType) -> String:
	"""Convert AttackType enum to string"""
	match attack_type:
		AttackType.FRONTAL:
			return "frontal"
		AttackType.SIDE_LEFT:
			return "side_left"
		AttackType.SIDE_RIGHT:
			return "side_right"
		AttackType.AREA:
			return "area"
		AttackType.OVERHEAD:
			return "overhead"
		AttackType.COMBO_SEQUENCE:
			return "combo"
		AttackType.BOSS_SPECIAL:
			return "boss_special"
		_:
			return "unknown"

func get_dodge_direction_string(direction: CombatController.DodgeDirection) -> String:
	"""Convert dodge direction enum to string"""
	match direction:
		CombatController.DodgeDirection.LEFT:
			return "left"
		CombatController.DodgeDirection.RIGHT:
			return "right"
		CombatController.DodgeDirection.BACKWARD:
			return "backward"
		_:
			return "unknown"

# Public API methods for enemy AI to use

func get_available_patterns_for_enemy_type(enemy_type: EnemyType) -> Array[String]:
	"""Get list of available attack patterns for a specific enemy type"""
	var patterns: Array[String] = []
	
	match enemy_type:
		EnemyType.BASIC_MELEE:
			patterns = ["basic_melee_simple", "basic_melee_combo"]
		EnemyType.RANGED_ARCHER:
			patterns = ["archer_single_shot", "archer_triple_volley"]
		EnemyType.HEAVY_BRUISER:
			patterns = ["bruiser_slam", "bruiser_ground_pound"]
		EnemyType.AGILE_ROGUE:
			patterns = ["rogue_dash_left", "rogue_triple_combo"]
		EnemyType.MAGE_CASTER:
			patterns = ["mage_fireball", "mage_lightning_storm"]
		EnemyType.BOSS_TIER_1:
			patterns = ["boss_tier1_combo"]
		EnemyType.BOSS_TIER_2:
			patterns = ["boss_tier2_complex"]
		EnemyType.BOSS_FINAL:
			patterns = ["final_boss_ultimate"]
	
	return patterns

func get_random_pattern_for_enemy_type(enemy_type: EnemyType) -> String:
	"""Get a random attack pattern for a specific enemy type"""
	var available_patterns = get_available_patterns_for_enemy_type(enemy_type)
	if available_patterns.size() > 0:
		return available_patterns[randi() % available_patterns.size()]
	return ""

func stop_current_pattern():
	"""Stop the currently executing attack pattern"""
	if current_pattern:
		attack_pattern_completed.emit(current_pattern.pattern_id)
		current_pattern = null
		pattern_timer = 0.0
	
	# Clear active attacks
	for attack in active_attacks:
		remove_telegraph_visual(attack)
	active_attacks.clear()

func is_pattern_active() -> bool:
	"""Check if an attack pattern is currently active"""
	return current_pattern != null

func get_current_pattern_id() -> String:
	"""Get the ID of the currently active pattern"""
	if current_pattern:
		return current_pattern.pattern_id
	return ""

# Debug methods

func debug_attack_system():
	"""Print debug information about the attack system"""
	print("=== ENEMY ATTACK SYSTEM DEBUG ===")
	print("Available patterns: ", attack_patterns.size())
	print("Active attacks: ", active_attacks.size())
	print("Current pattern: ", get_current_pattern_id())
	print("Pattern timer: ", pattern_timer)
	print("Telegraph effects: ", telegraph_effects.size())
	print("==================================")

func test_attack_pattern(pattern_id: String):
	"""Test method to trigger a specific attack pattern"""
	if start_attack_pattern(pattern_id, Vector3(0, 0, -5)):
		print("EnemyAttackSystem: Testing pattern '", pattern_id, "'")
	else:
		print("EnemyAttackSystem: Failed to test pattern '", pattern_id, "'")