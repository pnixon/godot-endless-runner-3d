extends Node
class_name CombatFeedbackTest

## Test script for Combat Feedback and Timing System
## Run this to test all feedback system features

var player: RPGPlayer3D
var combat_controller: CombatController
var feedback_system: CombatFeedbackSystem

func _ready():
	print("=== COMBAT FEEDBACK SYSTEM TEST ===")
	
	# Find player and systems
	player = get_tree().get_first_node_in_group("rpg_player") as RPGPlayer3D
	if player:
		combat_controller = player.combat_controller
		if combat_controller:
			feedback_system = combat_controller.feedback_system
	
	if not player or not combat_controller or not feedback_system:
		print("ERROR: Required systems not found!")
		print("Player: ", player != null)
		print("Combat Controller: ", combat_controller != null)
		print("Feedback System: ", feedback_system != null)
		return
	
	print("All systems found, starting tests...")
	
	# Connect to feedback system signals for testing
	feedback_system.combo_started.connect(_on_combo_started)
	feedback_system.combo_extended.connect(_on_combo_extended)
	feedback_system.combo_broken.connect(_on_combo_broken)
	feedback_system.perfect_timing_achieved.connect(_on_perfect_timing_achieved)
	feedback_system.screen_effect_triggered.connect(_on_screen_effect_triggered)
	
	# Start test sequence
	start_test_sequence()

func start_test_sequence():
	"""Start automated test sequence"""
	print("\n--- Starting Test Sequence ---")
	
	# Test 1: Basic dodge feedback
	print("Test 1: Basic dodge feedback")
	await get_tree().create_timer(1.0).timeout
	test_basic_dodge()
	
	# Test 2: Perfect dodge feedback
	await get_tree().create_timer(2.0).timeout
	print("Test 2: Perfect dodge feedback")
	test_perfect_dodge()
	
	# Test 3: Block feedback
	await get_tree().create_timer(3.0).timeout
	print("Test 3: Block feedback")
	test_block_feedback()
	
	# Test 4: Combo system
	await get_tree().create_timer(4.0).timeout
	print("Test 4: Combo system")
	test_combo_system()
	
	# Test 5: Screen effects
	await get_tree().create_timer(6.0).timeout
	print("Test 5: Screen effects")
	test_screen_effects()
	
	# Test 6: Audio feedback
	await get_tree().create_timer(8.0).timeout
	print("Test 6: Audio feedback")
	test_audio_feedback()
	
	await get_tree().create_timer(10.0).timeout
	print("\n=== ALL TESTS COMPLETED ===")

func test_basic_dodge():
	"""Test basic dodge feedback"""
	if combat_controller:
		combat_controller.attempt_dodge(CombatController.DodgeDirection.LEFT)
		print("✓ Basic dodge executed")

func test_perfect_dodge():
	"""Test perfect dodge with timing"""
	if combat_controller:
		# Register an incoming attack
		combat_controller.test_incoming_attack("frontal")
		
		# Wait for perfect timing window and dodge
		await get_tree().create_timer(0.8).timeout
		combat_controller.attempt_dodge(CombatController.DodgeDirection.BACKWARD)
		print("✓ Perfect dodge attempted")

func test_block_feedback():
	"""Test block feedback system"""
	if combat_controller:
		# Start blocking
		combat_controller.start_block()
		print("✓ Block started")
		
		# End block after short duration
		await get_tree().create_timer(0.5).timeout
		combat_controller.end_block(true)
		print("✓ Block ended")

func test_combo_system():
	"""Test combo system with multiple actions"""
	if combat_controller:
		print("Building combo with multiple dodges...")
		
		# Perform rapid dodges to build combo
		for i in range(5):
			var direction = CombatController.DodgeDirection.LEFT if i % 2 == 0 else CombatController.DodgeDirection.RIGHT
			combat_controller.attempt_dodge(direction)
			await get_tree().create_timer(0.3).timeout
		
		print("✓ Combo sequence completed")

func test_screen_effects():
	"""Test screen effects directly"""
	if feedback_system:
		print("Testing screen shake...")
		feedback_system.trigger_screen_shake(0.3, 0.5)
		
		await get_tree().create_timer(1.0).timeout
		print("Testing slow motion...")
		feedback_system.trigger_slow_motion(1.0, 0.5)
		
		await get_tree().create_timer(2.0).timeout
		print("Testing screen flash...")
		feedback_system.trigger_screen_flash(0.8, 0.5, Color.GOLD)
		
		print("✓ Screen effects tested")

func test_audio_feedback():
	"""Test audio feedback system"""
	if feedback_system:
		print("Testing combat sounds...")
		
		feedback_system.play_combat_sound("dodge_success")
		await get_tree().create_timer(0.5).timeout
		
		feedback_system.play_combat_sound("perfect_timing")
		await get_tree().create_timer(0.5).timeout
		
		feedback_system.play_combat_sound("combo_extend")
		await get_tree().create_timer(0.5).timeout
		
		print("✓ Audio feedback tested")

# Signal handlers for testing

func _on_combo_started(combo_type: String):
	print("🔥 COMBO STARTED: ", combo_type)

func _on_combo_extended(combo_count: int, multiplier: float):
	print("⚡ COMBO EXTENDED: ", combo_count, "x (", multiplier, " multiplier)")

func _on_combo_broken(final_count: int, final_multiplier: float):
	print("💥 COMBO BROKEN: Final count ", final_count, " with ", final_multiplier, " multiplier")

func _on_perfect_timing_achieved(action_type: String, bonus: int):
	print("✨ PERFECT TIMING: ", action_type, " (+", bonus, " bonus)")

func _on_screen_effect_triggered(effect_type: String, intensity: float):
	print("📺 SCREEN EFFECT: ", effect_type, " at ", intensity, " intensity")

func _input(event):
	"""Handle test input"""
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_F1:
				test_basic_dodge()
			KEY_F2:
				test_perfect_dodge()
			KEY_F3:
				test_block_feedback()
			KEY_F4:
				test_combo_system()
			KEY_F5:
				test_screen_effects()
			KEY_F6:
				test_audio_feedback()
			KEY_F7:
				if feedback_system:
					feedback_system.debug_feedback_system()
			KEY_F8:
				start_test_sequence()

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		# Reset time scale when exiting
		Engine.time_scale = 1.0
		get_tree().quit()