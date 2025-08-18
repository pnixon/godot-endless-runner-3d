extends Node

## Test script for mobile combat controls integration
## Tests touch gestures, haptic feedback, and visual indicators

var mobile_input_manager: MobileInputManager
var combat_controller: CombatController
var player: RPGPlayer3D
var touch_zones: TouchZoneIndicator

func _ready():
	print("=== MOBILE COMBAT INTEGRATION TEST ===")
	
	# Find components
	mobile_input_manager = get_node("/root/MobileInputManager")
	player = get_tree().get_first_node_in_group("rpg_player")
	
	if player:
		combat_controller = player.get_node_or_null("CombatController")
	
	var ui_layer = get_tree().current_scene.get_node_or_null("UI")
	if ui_layer:
		touch_zones = ui_layer.get_node_or_null("TouchZoneIndicator")
	
	# Run tests
	test_component_availability()
	test_signal_connections()
	test_combat_gestures()
	test_haptic_feedback()
	test_visual_indicators()
	
	print("=== TEST COMPLETE ===")
	print("Press F9 to run gesture simulation tests")

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_F9:
				run_gesture_simulation_tests()
			KEY_F10:
				test_touch_zone_highlighting()
			KEY_F11:
				test_haptic_patterns()
			KEY_F12:
				debug_all_systems()

func test_component_availability():
	"""Test that all required components are available"""
	print("\n--- Component Availability Test ---")
	
	if mobile_input_manager:
		print("✅ MobileInputManager found")
		print("  Combat mode: ", mobile_input_manager.is_combat_mode_enabled())
		print("  Haptic enabled: ", mobile_input_manager.haptic_enabled)
	else:
		print("❌ MobileInputManager not found")
	
	if player:
		print("✅ RPGPlayer3D found")
	else:
		print("❌ RPGPlayer3D not found")
	
	if combat_controller:
		print("✅ CombatController found")
		print("  Current state: ", combat_controller.get_current_state())
	else:
		print("❌ CombatController not found")
	
	if touch_zones:
		print("✅ TouchZoneIndicator found")
		print("  Zones visible: ", touch_zones.show_zones)
	else:
		print("❌ TouchZoneIndicator not found")

func test_signal_connections():
	"""Test that signals are properly connected"""
	print("\n--- Signal Connection Test ---")
	
	if mobile_input_manager and combat_controller:
		# Check if signals are connected
		var dodge_connected = mobile_input_manager.is_connected("dodge_gesture", combat_controller._on_dodge_gesture)
		var block_start_connected = mobile_input_manager.is_connected("block_gesture_started", combat_controller._on_block_gesture_started)
		var block_end_connected = mobile_input_manager.is_connected("block_gesture_ended", combat_controller._on_block_gesture_ended)
		var dash_connected = mobile_input_manager.is_connected("dash_gesture", combat_controller._on_dash_gesture)
		
		print("✅ Dodge gesture signal: ", "connected" if dodge_connected else "not connected")
		print("✅ Block start signal: ", "connected" if block_start_connected else "not connected")
		print("✅ Block end signal: ", "connected" if block_end_connected else "not connected")
		print("✅ Dash gesture signal: ", "connected" if dash_connected else "not connected")
	else:
		print("❌ Cannot test signal connections - components missing")

func test_combat_gestures():
	"""Test combat gesture recognition"""
	print("\n--- Combat Gesture Test ---")
	
	if mobile_input_manager:
		print("Testing gesture thresholds:")
		print("  Dodge swipe threshold: ", mobile_input_manager.dodge_swipe_threshold)
		print("  Dash swipe threshold: ", mobile_input_manager.dash_swipe_threshold)
		print("  Block hold threshold: ", mobile_input_manager.block_hold_threshold)
		
		# Enable combat mode for testing
		mobile_input_manager.set_combat_mode(true)
		print("✅ Combat mode enabled for testing")
	else:
		print("❌ Cannot test gestures - MobileInputManager missing")

func test_haptic_feedback():
	"""Test haptic feedback system"""
	print("\n--- Haptic Feedback Test ---")
	
	if mobile_input_manager:
		print("Testing haptic feedback patterns...")
		
		# Test different combat haptic patterns
		mobile_input_manager.trigger_combat_haptic_feedback("dodge")
		await get_tree().create_timer(0.2).timeout
		
		mobile_input_manager.trigger_combat_haptic_feedback("block_start")
		await get_tree().create_timer(0.2).timeout
		
		mobile_input_manager.trigger_combat_haptic_feedback("perfect_dodge")
		await get_tree().create_timer(0.2).timeout
		
		print("✅ Haptic feedback patterns tested")
	else:
		print("❌ Cannot test haptic feedback - MobileInputManager missing")

func test_visual_indicators():
	"""Test visual touch zone indicators"""
	print("\n--- Visual Indicator Test ---")
	
	if touch_zones:
		print("Testing touch zone indicators...")
		
		# Test zone highlighting
		touch_zones.highlight_zone(TouchZoneIndicator.ZoneType.DODGE_LEFT, 1.0)
		await get_tree().create_timer(0.5).timeout
		
		touch_zones.highlight_zone(TouchZoneIndicator.ZoneType.DODGE_RIGHT, 1.0)
		await get_tree().create_timer(0.5).timeout
		
		touch_zones.highlight_zone(TouchZoneIndicator.ZoneType.BLOCK_HOLD, 1.0)
		
		print("✅ Visual indicators tested")
	else:
		print("❌ Cannot test visual indicators - TouchZoneIndicator missing")

func run_gesture_simulation_tests():
	"""Run gesture simulation tests"""
	print("\n--- Gesture Simulation Test ---")
	
	if not mobile_input_manager or not combat_controller:
		print("❌ Cannot run simulation - components missing")
		return
	
	print("Simulating combat gestures...")
	
	# Test dodge left
	print("Testing dodge left...")
	mobile_input_manager.emit_signal("dodge_gesture", "left")
	await get_tree().create_timer(0.5).timeout
	
	# Test dodge right
	print("Testing dodge right...")
	mobile_input_manager.emit_signal("dodge_gesture", "right")
	await get_tree().create_timer(0.5).timeout
	
	# Test dodge back
	print("Testing dodge back...")
	mobile_input_manager.emit_signal("dodge_gesture", "backward")
	await get_tree().create_timer(0.5).timeout
	
	# Test dash forward
	print("Testing dash forward...")
	mobile_input_manager.emit_signal("dash_gesture")
	await get_tree().create_timer(0.5).timeout
	
	# Test block start/end
	print("Testing block gesture...")
	mobile_input_manager.emit_signal("block_gesture_started")
	await get_tree().create_timer(1.0).timeout
	mobile_input_manager.emit_signal("block_gesture_ended")
	
	print("✅ Gesture simulation tests complete")

func test_touch_zone_highlighting():
	"""Test touch zone highlighting"""
	print("\n--- Touch Zone Highlighting Test ---")
	
	if not touch_zones:
		print("❌ TouchZoneIndicator not available")
		return
	
	print("Testing zone highlighting...")
	
	# Highlight each zone type
	var zone_types = [
		TouchZoneIndicator.ZoneType.DODGE_LEFT,
		TouchZoneIndicator.ZoneType.DODGE_RIGHT,
		TouchZoneIndicator.ZoneType.DODGE_BACK,
		TouchZoneIndicator.ZoneType.DASH_FORWARD,
		TouchZoneIndicator.ZoneType.BLOCK_HOLD
	]
	
	for zone_type in zone_types:
		touch_zones.highlight_zone(zone_type, 0.8)
		await get_tree().create_timer(0.3).timeout
	
	print("✅ Zone highlighting test complete")

func test_haptic_patterns():
	"""Test all haptic feedback patterns"""
	print("\n--- Haptic Pattern Test ---")
	
	if not mobile_input_manager:
		print("❌ MobileInputManager not available")
		return
	
	var patterns = ["dodge", "dash", "block_start", "block_end", "perfect_dodge", "successful_block"]
	
	for pattern in patterns:
		print("Testing haptic pattern: ", pattern)
		mobile_input_manager.trigger_combat_haptic_feedback(pattern)
		await get_tree().create_timer(0.4).timeout
	
	print("✅ Haptic pattern test complete")

func debug_all_systems():
	"""Debug all mobile combat systems"""
	print("\n--- FULL SYSTEM DEBUG ---")
	
	if mobile_input_manager:
		print("MobileInputManager Debug:")
		print("  Combat mode: ", mobile_input_manager.is_combat_mode_enabled())
		print("  Haptic enabled: ", mobile_input_manager.haptic_enabled)
		print("  Block gesture active: ", mobile_input_manager.block_gesture_active)
		print("  Gesture sensitivity: ", mobile_input_manager.gesture_sensitivity)
	
	if combat_controller:
		print("CombatController Debug:")
		combat_controller.debug_combat_state()
	
	if touch_zones:
		print("TouchZoneIndicator Debug:")
		touch_zones.debug_zones()
	
	if player:
		print("RPGPlayer3D Debug:")
		player.debug_rpg_stats()
	
	print("--- DEBUG COMPLETE ---")