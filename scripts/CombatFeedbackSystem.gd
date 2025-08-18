extends Node
class_name CombatFeedbackSystem

## Combat Feedback and Timing System
## Provides visual, audio, and screen effects for combat actions
## Manages combo system and perfect timing rewards

signal combo_started(combo_type: String)
signal combo_extended(combo_count: int, multiplier: float)
signal combo_broken(final_count: int, final_multiplier: float)
signal perfect_timing_achieved(action_type: String, bonus: int)
signal screen_effect_triggered(effect_type: String, intensity: float)

# Combo system
enum ComboType { DODGE, BLOCK, ATTACK, MIXED }
var current_combo_type: ComboType = ComboType.DODGE
var combo_count: int = 0
var combo_multiplier: float = 1.0
var combo_timer: float = 0.0
var combo_window: float = 3.0  # Time window to extend combo
var max_combo_multiplier: float = 5.0

# Perfect timing tracking
var perfect_actions_in_row: int = 0
var perfect_timing_bonus_base: int = 25
var perfect_timing_streak: int = 0

# Screen effects
var screen_shake_intensity: float = 0.0
var screen_shake_duration: float = 0.0
var slow_motion_factor: float = 1.0
var slow_motion_duration: float = 0.0
var flash_intensity: float = 0.0
var flash_duration: float = 0.0

# Audio system
var audio_player: AudioStreamPlayer
var combat_sounds: Dictionary = {}

# Visual effects
var active_effects: Array[Node3D] = []
var camera_ref: Camera3D

# References
var player: RPGPlayer3D
var combat_controller: CombatController

func _ready():
	# Find references
	player = get_tree().get_first_node_in_group("rpg_player") as RPGPlayer3D
	combat_controller = get_parent() as CombatController
	
	if player:
		camera_ref = player.get_node_or_null("Camera3D")
	
	# Set up audio system
	setup_audio_system()
	
	# Connect to combat controller signals
	if combat_controller:
		combat_controller.dodge_performed.connect(_on_dodge_performed)
		combat_controller.block_started.connect(_on_block_started)
		combat_controller.block_ended.connect(_on_block_ended)
		combat_controller.perfect_dodge_achieved.connect(_on_perfect_dodge_achieved)
		combat_controller.invincibility_started.connect(_on_invincibility_started)
	
	print("CombatFeedbackSystem initialized")

func _process(delta):
	update_combo_timer(delta)
	update_screen_effects(delta)
	update_time_scale(delta)
	cleanup_expired_effects()

func setup_audio_system():
	"""Initialize audio system with combat sound effects"""
	audio_player = AudioStreamPlayer.new()
	audio_player.name = "CombatFeedbackAudio"
	add_child(audio_player)
	
	# Load combat sound effects (using existing audio files as placeholders)
	# In a full implementation, these would be specific combat sound files
	var base_audio_path = "res://audio/"
	
	# Create sound effect mappings using available audio files
	combat_sounds = {
		"dodge_success": load_audio_file(base_audio_path + "chiptunes awesomeness.mp3"),
		"dodge_perfect": load_audio_file(base_audio_path + "chiptunes awesomeness 2.mp3"),
		"block_start": load_audio_file(base_audio_path + "chiptunes awesomeness.mp3"),
		"block_success": load_audio_file(base_audio_path + "chiptunes awesomeness 2.mp3"),
		"block_perfect": load_audio_file(base_audio_path + "chiptunes awesomeness 2.mp3"),
		"combo_start": load_audio_file(base_audio_path + "chiptunes awesomeness.mp3"),
		"combo_extend": load_audio_file(base_audio_path + "chiptunes awesomeness 2.mp3"),
		"combo_break": load_audio_file(base_audio_path + "chiptunes awesomeness.mp3"),
		"perfect_timing": load_audio_file(base_audio_path + "chiptunes awesomeness 2.mp3"),
		"screen_shake": load_audio_file(base_audio_path + "chiptunes awesomeness.mp3"),
		"slow_motion": load_audio_file(base_audio_path + "chiptunes awesomeness 2.mp3")
	}
	
	print("Combat audio system loaded with ", combat_sounds.size(), " sound effects")

func load_audio_file(path: String) -> AudioStream:
	"""Load audio file with error handling"""
	if ResourceLoader.exists(path):
		return load(path) as AudioStream
	else:
		print("Warning: Audio file not found: ", path)
		return null

# Combat Action Handlers

func _on_dodge_performed(direction: String, perfect: bool):
	"""Handle dodge performed event"""
	if perfect:
		handle_perfect_dodge(direction)
	else:
		handle_regular_dodge(direction)
	
	# Update combo system
	update_combo_system(ComboType.DODGE, perfect)

func _on_block_started():
	"""Handle block started event"""
	play_combat_sound("block_start", 0.6)
	create_block_start_effect()
	trigger_screen_shake(0.1, 0.1)

func _on_block_ended(successful: bool):
	"""Handle block ended event"""
	if successful:
		handle_successful_block()
		update_combo_system(ComboType.BLOCK, false)
	else:
		handle_failed_block()

func _on_perfect_dodge_achieved(bonus_reward: int):
	"""Handle perfect dodge achievement"""
	perfect_actions_in_row += 1
	perfect_timing_streak += 1
	
	# Trigger enhanced effects for perfect dodge
	trigger_slow_motion(0.3, 0.8)  # 30% speed for 0.8 seconds
	trigger_screen_flash(0.8, 0.3, Color.GOLD)
	play_combat_sound("perfect_timing", 0.8)
	
	# Create enhanced visual effect
	create_perfect_timing_effect("dodge", Color.GOLD)
	
	perfect_timing_achieved.emit("dodge", bonus_reward + (perfect_timing_streak * 5))

func _on_invincibility_started(duration: float):
	"""Handle invincibility started event"""
	create_invincibility_effect(duration)

# Combat Feedback Methods

func handle_regular_dodge(direction: String):
	"""Handle regular (non-perfect) dodge feedback"""
	play_combat_sound("dodge_success", 0.5)
	create_dodge_effect(direction, false)
	trigger_screen_shake(0.05, 0.1)

func handle_perfect_dodge(direction: String):
	"""Handle perfect dodge feedback"""
	play_combat_sound("dodge_perfect", 0.7)
	create_dodge_effect(direction, true)
	trigger_screen_shake(0.15, 0.2)
	
	# Perfect dodge gets enhanced visual effects
	create_perfect_timing_effect("dodge", Color.GOLD)

func handle_successful_block():
	"""Handle successful block feedback"""
	play_combat_sound("block_success", 0.6)
	create_block_success_effect()
	trigger_screen_shake(0.2, 0.15)

func handle_failed_block():
	"""Handle failed block feedback"""
	# No positive feedback for failed blocks
	trigger_screen_shake(0.05, 0.05)

# Combo System

func update_combo_system(action_type: ComboType, was_perfect: bool):
	"""Update the combo system based on performed action"""
	var combo_bonus = 1.0
	if was_perfect:
		combo_bonus = 2.0
	
	if combo_count == 0:
		# Start new combo
		start_combo(action_type)
	elif current_combo_type == action_type or current_combo_type == ComboType.MIXED:
		# Extend existing combo
		extend_combo(combo_bonus)
	elif combo_count > 0:
		# Different action type, convert to mixed combo or break
		if combo_count >= 3:
			current_combo_type = ComboType.MIXED
			extend_combo(combo_bonus)
		else:
			break_combo()
			start_combo(action_type)
	
	# Reset combo timer
	combo_timer = combo_window

func start_combo(combo_type: ComboType):
	"""Start a new combo"""
	current_combo_type = combo_type
	combo_count = 1
	combo_multiplier = 1.0
	combo_timer = combo_window
	
	play_combat_sound("combo_start", 0.4)
	create_combo_start_effect()
	
	combo_started.emit(get_combo_type_string(combo_type))
	print("Combo started: ", get_combo_type_string(combo_type))

func extend_combo(bonus_multiplier: float = 1.0):
	"""Extend current combo"""
	combo_count += 1
	combo_multiplier = min(combo_multiplier + (0.2 * bonus_multiplier), max_combo_multiplier)
	combo_timer = combo_window
	
	play_combat_sound("combo_extend", 0.5 + (combo_count * 0.05))
	create_combo_extend_effect()
	
	# Enhanced effects for higher combos
	if combo_count >= 5:
		trigger_screen_flash(0.3, 0.2, Color.ORANGE)
	if combo_count >= 10:
		trigger_slow_motion(0.1, 0.5)
		trigger_screen_flash(0.5, 0.3, Color.RED)
	
	combo_extended.emit(combo_count, combo_multiplier)
	print("Combo extended! Count: ", combo_count, " Multiplier: ", combo_multiplier)

func break_combo():
	"""Break current combo"""
	if combo_count > 0:
		var final_count = combo_count
		var final_multiplier = combo_multiplier
		
		play_combat_sound("combo_break", 0.3)
		create_combo_break_effect()
		
		combo_broken.emit(final_count, final_multiplier)
		print("Combo broken! Final count: ", final_count, " Final multiplier: ", final_multiplier)
		
		# Award bonus XP based on combo
		if player and final_count >= 3:
			var bonus_xp = int(final_count * final_multiplier * 10)
			player.gain_experience(bonus_xp)
			print("Combo bonus XP: ", bonus_xp)
	
	reset_combo()

func reset_combo():
	"""Reset combo system"""
	combo_count = 0
	combo_multiplier = 1.0
	combo_timer = 0.0
	current_combo_type = ComboType.DODGE

func update_combo_timer(delta: float):
	"""Update combo timer and break combo if expired"""
	if combo_count > 0:
		combo_timer -= delta
		if combo_timer <= 0:
			break_combo()

func get_combo_type_string(combo_type: ComboType) -> String:
	"""Convert combo type to string"""
	match combo_type:
		ComboType.DODGE:
			return "dodge"
		ComboType.BLOCK:
			return "block"
		ComboType.ATTACK:
			return "attack"
		ComboType.MIXED:
			return "mixed"
		_:
			return "unknown"

# Screen Effects

func trigger_screen_shake(intensity: float, duration: float):
	"""Trigger screen shake effect"""
	screen_shake_intensity = max(screen_shake_intensity, intensity)
	screen_shake_duration = max(screen_shake_duration, duration)
	
	screen_effect_triggered.emit("shake", intensity)

func trigger_slow_motion(duration: float, time_scale: float = 0.3):
	"""Trigger slow motion effect"""
	slow_motion_duration = duration
	slow_motion_factor = time_scale
	
	play_combat_sound("slow_motion", 0.4)
	screen_effect_triggered.emit("slow_motion", time_scale)
	print("Slow motion activated: ", time_scale, "x for ", duration, "s")

func trigger_screen_flash(intensity: float, duration: float, color: Color = Color.WHITE):
	"""Trigger screen flash effect"""
	flash_intensity = max(flash_intensity, intensity)
	flash_duration = max(flash_duration, duration)
	
	create_screen_flash_effect(color, intensity, duration)
	screen_effect_triggered.emit("flash", intensity)

func update_screen_effects(delta: float):
	"""Update screen shake and other effects"""
	if camera_ref and screen_shake_intensity > 0:
		# Apply screen shake
		var shake_offset = Vector3(
			randf_range(-screen_shake_intensity, screen_shake_intensity),
			randf_range(-screen_shake_intensity, screen_shake_intensity),
			0
		)
		
		# Store original position if not shaking
		if not camera_ref.has_meta("original_position"):
			camera_ref.set_meta("original_position", camera_ref.position)
		
		var original_pos = camera_ref.get_meta("original_position")
		camera_ref.position = original_pos + shake_offset
		
		# Reduce shake over time
		screen_shake_duration -= delta
		if screen_shake_duration <= 0:
			screen_shake_intensity = 0.0
			camera_ref.position = original_pos
			camera_ref.remove_meta("original_position")

func update_time_scale(delta: float):
	"""Update time scale for slow motion effects"""
	if slow_motion_duration > 0:
		Engine.time_scale = slow_motion_factor
		slow_motion_duration -= delta
		
		if slow_motion_duration <= 0:
			Engine.time_scale = 1.0
			print("Slow motion ended")

# Visual Effects

func create_dodge_effect(direction: String, perfect: bool):
	"""Create visual effect for dodge"""
	var effect_color = Color.CYAN if not perfect else Color.GOLD
	var effect_size = 0.3 if not perfect else 0.5
	
	create_action_effect("dodge_" + direction, effect_color, effect_size, perfect)

func create_block_start_effect():
	"""Create visual effect for block start"""
	create_action_effect("block_start", Color.BLUE, 0.4, false)

func create_block_success_effect():
	"""Create visual effect for successful block"""
	create_action_effect("block_success", Color.SILVER, 0.6, true)

func create_perfect_timing_effect(action_type: String, color: Color):
	"""Create enhanced visual effect for perfect timing"""
	if not player:
		return
	
	# Create glowing ring effect
	var effect = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.inner_radius = 0.8
	torus.outer_radius = 1.2
	effect.mesh = torus
	
	# Create glowing material
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color * 2.0
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.rim_enabled = true
	material.rim = Color.WHITE
	material.rim_tint = 0.8
	effect.material_override = material
	
	effect.position = player.position + Vector3(0, 0.5, 0)
	effect.name = "PerfectTimingEffect_" + action_type
	player.get_parent().add_child(effect)
	active_effects.append(effect)
	
	# Animate effect
	var tween = create_tween()
	tween.parallel().tween_property(effect, "scale", Vector3(2.0, 0.1, 2.0), 0.5)
	tween.parallel().tween_property(material, "albedo_color:a", 0.0, 0.5)
	tween.parallel().tween_property(effect, "rotation_degrees:y", 360, 0.5)
	tween.tween_callback(func(): remove_effect(effect))

func create_action_effect(action_name: String, color: Color, size: float, enhanced: bool):
	"""Create generic action visual effect"""
	if not player:
		return
	
	var effect = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = size
	sphere.height = size * 2
	effect.mesh = sphere
	
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color * (2.0 if enhanced else 1.0)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	if enhanced:
		material.rim_enabled = true
		material.rim = Color.WHITE
		material.rim_tint = 0.5
	
	effect.material_override = material
	effect.position = player.position + Vector3(0, 1.0, 0)
	effect.name = "ActionEffect_" + action_name
	player.get_parent().add_child(effect)
	active_effects.append(effect)
	
	# Animate effect
	var tween = create_tween()
	var scale_multiplier = 2.0 if enhanced else 1.5
	tween.parallel().tween_property(effect, "scale", Vector3(scale_multiplier, scale_multiplier, scale_multiplier), 0.3)
	tween.parallel().tween_property(material, "albedo_color:a", 0.0, 0.3)
	tween.parallel().tween_property(effect, "position:y", effect.position.y + 1.5, 0.3)
	tween.tween_callback(func(): remove_effect(effect))

func create_combo_start_effect():
	"""Create visual effect for combo start"""
	create_combo_effect("start", Color.GREEN, 1)

func create_combo_extend_effect():
	"""Create visual effect for combo extension"""
	var intensity = min(combo_count / 5.0, 1.0)
	var color = Color.GREEN.lerp(Color.RED, intensity)
	create_combo_effect("extend", color, combo_count)

func create_combo_break_effect():
	"""Create visual effect for combo break"""
	create_combo_effect("break", Color.GRAY, combo_count)

func create_combo_effect(combo_action: String, color: Color, count: int):
	"""Create visual effect for combo actions"""
	if not player:
		return
	
	# Create multiple particles for higher combos
	var particle_count = min(count, 10)
	
	for i in range(particle_count):
		var effect = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = Vector3(0.1, 0.1, 0.1)
		effect.mesh = box
		
		var material = StandardMaterial3D.new()
		material.albedo_color = color
		material.emission_enabled = true
		material.emission = color * 1.5
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		effect.material_override = material
		
		# Random position around player
		var angle = (i / float(particle_count)) * TAU
		var radius = 1.0 + (count * 0.1)
		var offset = Vector3(cos(angle) * radius, 1.0 + randf() * 0.5, sin(angle) * radius)
		effect.position = player.position + offset
		effect.name = "ComboEffect_" + combo_action + "_" + str(i)
		player.get_parent().add_child(effect)
		active_effects.append(effect)
		
		# Animate effect
		var tween = create_tween()
		tween.parallel().tween_property(effect, "scale", Vector3.ZERO, 0.4 + (i * 0.05))
		tween.parallel().tween_property(effect, "position:y", effect.position.y + 2, 0.4 + (i * 0.05))
		tween.parallel().tween_property(material, "albedo_color:a", 0.0, 0.4 + (i * 0.05))
		tween.tween_callback(func(): remove_effect(effect))

func create_invincibility_effect(duration: float):
	"""Create visual effect for invincibility frames"""
	if not player:
		return
	
	var effect = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 1.2
	sphere.height = 2.4
	effect.mesh = sphere
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.CYAN
	material.emission_enabled = true
	material.emission = Color.CYAN * 0.8
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color.a = 0.3
	effect.material_override = material
	
	effect.position = player.position
	effect.name = "InvincibilityEffect"
	player.add_child(effect)
	active_effects.append(effect)
	
	# Pulsing animation
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(material, "albedo_color:a", 0.1, 0.1)
	tween.tween_property(material, "albedo_color:a", 0.5, 0.1)
	
	# Remove after duration
	get_tree().create_timer(duration).timeout.connect(func(): remove_effect(effect))

func create_screen_flash_effect(color: Color, intensity: float, duration: float):
	"""Create screen flash effect"""
	if not camera_ref:
		return
	
	# Create a ColorRect that covers the screen
	var flash_overlay = ColorRect.new()
	flash_overlay.name = "ScreenFlash"
	flash_overlay.color = color
	flash_overlay.color.a = intensity
	flash_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Add to UI layer
	var ui_layer = get_tree().current_scene.get_node_or_null("UI")
	if not ui_layer:
		ui_layer = get_tree().current_scene
	
	# Make it cover the entire screen
	flash_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_layer.add_child(flash_overlay)
	
	# Fade out animation
	var tween = create_tween()
	tween.tween_property(flash_overlay, "color:a", 0.0, duration)
	tween.tween_callback(flash_overlay.queue_free)

# Audio Methods

func play_combat_sound(sound_name: String, volume: float = 0.5):
	"""Play combat sound effect"""
	if not combat_sounds.has(sound_name) or not combat_sounds[sound_name]:
		return
	
	audio_player.stream = combat_sounds[sound_name]
	audio_player.volume_db = linear_to_db(volume)
	audio_player.pitch_scale = randf_range(0.9, 1.1)  # Slight pitch variation
	audio_player.play()

# Utility Methods

func remove_effect(effect: Node3D):
	"""Remove visual effect from scene"""
	if is_instance_valid(effect):
		if effect in active_effects:
			active_effects.erase(effect)
		effect.queue_free()

func cleanup_expired_effects():
	"""Clean up expired visual effects"""
	for i in range(active_effects.size() - 1, -1, -1):
		var effect = active_effects[i]
		if not is_instance_valid(effect) or not effect.is_inside_tree():
			active_effects.remove_at(i)

# Public Interface

func get_current_combo_count() -> int:
	"""Get current combo count"""
	return combo_count

func get_current_combo_multiplier() -> float:
	"""Get current combo multiplier"""
	return combo_multiplier

func get_perfect_timing_streak() -> int:
	"""Get current perfect timing streak"""
	return perfect_timing_streak

func reset_perfect_timing_streak():
	"""Reset perfect timing streak"""
	perfect_timing_streak = 0
	perfect_actions_in_row = 0

func is_in_combo() -> bool:
	"""Check if currently in a combo"""
	return combo_count > 0

func force_break_combo():
	"""Force break current combo (for external events)"""
	if combo_count > 0:
		break_combo()

# Debug Methods

func debug_feedback_system():
	"""Print debug information about feedback system"""
	print("=== COMBAT FEEDBACK DEBUG ===")
	print("Combo Count: ", combo_count)
	print("Combo Multiplier: ", combo_multiplier)
	print("Combo Type: ", get_combo_type_string(current_combo_type))
	print("Combo Timer: ", combo_timer)
	print("Perfect Timing Streak: ", perfect_timing_streak)
	print("Active Effects: ", active_effects.size())
	print("Screen Shake: ", screen_shake_intensity, " for ", screen_shake_duration)
	print("Slow Motion: ", slow_motion_factor, " for ", slow_motion_duration)
	print("==============================")
