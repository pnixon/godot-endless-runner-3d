extends Node

## Quick Start Example: Game Mode System
## This script demonstrates how to quickly integrate and use the game mode system
## Attach this to a node in your scene to test the game mode system

## References
var current_mode: BaseGameMode = null

func _ready() -> void:
	print("\n=== GAME MODE SYSTEM - QUICK START ===\n")

	# Wait a frame for GameModeManager to initialize
	await get_tree().process_frame

	# Example 1: Start a story level
	example_start_story_level()

	# Example 2: Start a challenge mode (uncomment to try)
	# example_start_challenge_mode()

	# Example 3: Start a timed challenge (uncomment to try)
	# example_start_timed_challenge()

	# Example 4: Create a custom mode (uncomment to try)
	# example_custom_mode()

## Example 1: Starting a Story Level

func example_start_story_level() -> void:
	print("Example 1: Starting Tutorial Story Level")

	# Start the tutorial level
	if GameModeManager.start_story_level("tutorial"):
		print("✅ Tutorial level started!")

		# Get the current mode
		current_mode = GameModeManager.get_current_mode()

		# Connect to signals
		current_mode.mode_completed.connect(_on_mode_completed)
		current_mode.mode_failed.connect(_on_mode_failed)
		current_mode.objective_completed.connect(_on_objective_completed)

		# Print mode info
		print("\nMode: ", current_mode.mode_name)
		print("Description: ", current_mode.mode_description)
		print("\nPrimary Objectives:")
		for obj in current_mode.get_primary_objectives():
			print("  - ", obj.description)
		print("\nBonus Objectives:")
		for obj in current_mode.get_secondary_objectives():
			print("  - ", obj.description)
	else:
		print("❌ Failed to start tutorial level")

## Example 2: Starting a Challenge Mode

func example_start_challenge_mode() -> void:
	print("\nExample 2: Starting Classic Challenge Mode")

	if GameModeManager.start_challenge("classic"):
		print("✅ Classic challenge started!")
		current_mode = GameModeManager.get_current_mode()
		current_mode.mode_failed.connect(_on_mode_failed)

		print("This is an infinite mode - play until you die!")
		print("Press keys 1-6 to try different challenge variants")
	else:
		print("❌ Failed to start challenge mode")

## Example 3: Starting a Timed Challenge

func example_start_timed_challenge() -> void:
	print("\nExample 3: Starting Quick Sprint Timed Challenge")

	if GameModeManager.start_timed_challenge("quick_sprint"):
		print("✅ Quick sprint started!")
		current_mode = GameModeManager.get_current_mode()
		current_mode.mode_completed.connect(_on_mode_completed)
		current_mode.mode_failed.connect(_on_mode_failed)

		print("Reach 500 distance in 60 seconds!")
	else:
		print("❌ Failed to start timed challenge")

## Example 4: Creating a Custom Mode

func example_custom_mode() -> void:
	print("\nExample 4: Creating Custom Story Mode")

	# Create a custom story level
	var custom_level = StoryMode.new()
	custom_level.mode_name = "Custom Challenge"
	custom_level.level_id = "custom_test"
	custom_level.mode_description = "A quick test level"

	# Add objectives
	custom_level.add_objective(
		BaseGameMode.ObjectiveType.DISTANCE,
		300.0,
		"Reach 300 distance",
		true  # Primary
	)

	custom_level.add_objective(
		BaseGameMode.ObjectiveType.COLLECT_COINS,
		25.0,
		"Collect 25 coins",
		false  # Bonus
	)

	# Configure
	custom_level.max_lives = 3
	custom_level.starting_difficulty = 1.0

	# Start it
	GameModeManager.start_mode(custom_level)
	current_mode = custom_level
	current_mode.mode_completed.connect(_on_mode_completed)

	print("✅ Custom mode started!")

## Game Loop Integration

func _process(delta: float) -> void:
	# In your actual game, you'd call this from GameManager3D
	if GameModeManager.is_mode_active():
		# Build game state from your game
		var game_state = _build_example_game_state()

		# Update the mode
		GameModeManager.update_current_mode(delta, game_state)

func _build_example_game_state() -> Dictionary:
	"""
	In your actual game, extract this from GameManager3D.
	This is just example/test data.
	"""
	return {
		"distance": 100.0,  # Would come from GameManager3D.distance_traveled
		"score": 500,       # Would come from GameManager3D.score
		"coins": 10,        # Would come from GameManager3D.coins
		"enemies_defeated": 2,
		"perfect_dodges": 5,
		"damage_taken": 0,
		"max_combo": 5,
	}

## Event Handlers

func _on_mode_completed(results: Dictionary) -> void:
	print("\n🎉 MODE COMPLETED! 🎉")
	print("Mode: ", results.get("mode_name", "Unknown"))
	print("Time: %.1f seconds" % results.get("time_elapsed", 0))

	if results.has("stars_earned"):
		print("Stars: ", results["stars_earned"], "/3")

	if results.has("time_bonus_score"):
		print("Time Bonus: ", results["time_bonus_score"])

	print("\nObjectives Completed:")
	for obj in results.get("objectives", []):
		if obj.is_complete:
			print("  ✅ ", obj.description)

func _on_mode_failed(reason: String) -> void:
	print("\n❌ MODE FAILED")
	print("Reason: ", reason)

func _on_objective_completed(objective: BaseGameMode.Objective) -> void:
	print("✅ Objective completed: ", objective.description)

## Keyboard Shortcuts for Testing

func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed:
		return

	match event.keycode:
		KEY_1:
			print("\n--- Switching to Tutorial Story Level ---")
			GameModeManager.start_story_level("tutorial")
			_connect_current_mode()

		KEY_2:
			print("\n--- Switching to Classic Challenge ---")
			GameModeManager.start_challenge("classic")
			_connect_current_mode()

		KEY_3:
			print("\n--- Switching to Hardcore Challenge ---")
			if not GameModeManager.is_mode_unlocked("hardcore"):
				print("Unlocking hardcore for testing...")
				GameModeManager.unlock_mode("hardcore")
			GameModeManager.start_challenge("hardcore")
			_connect_current_mode()

		KEY_4:
			print("\n--- Switching to Quick Sprint ---")
			GameModeManager.start_timed_challenge("quick_sprint")
			_connect_current_mode()

		KEY_5:
			print("\n--- Creating Custom Mode ---")
			example_custom_mode()

		KEY_P:
			print("\n--- Progress Info ---")
			var stats = GameModeManager.get_total_stats()
			print("Total Playtime: %.1f seconds" % stats["playtime"])
			print("Total Distance: %.1f" % stats["distance"])
			print("Total Stars: ", stats["total_stars"])
			print("Story Levels Completed: ", stats["story_levels_completed"])

		KEY_U:
			print("\n--- Unlocking All Modes (Testing) ---")
			for level_id in GameModeManager.story_levels.keys():
				GameModeManager.unlock_mode(level_id)
			for challenge_id in GameModeManager.challenge_modes.keys():
				GameModeManager.unlock_mode(challenge_id)
			for timed_id in GameModeManager.timed_challenges.keys():
				GameModeManager.unlock_mode(timed_id)
			print("✅ All modes unlocked!")

		KEY_R:
			print("\n--- Resetting Progress ---")
			GameModeManager.reset_progress()
			print("✅ Progress reset!")

		KEY_H:
			print_help()

func _connect_current_mode() -> void:
	"""Helper to connect signals to current mode"""
	current_mode = GameModeManager.get_current_mode()
	if current_mode:
		if not current_mode.mode_completed.is_connected(_on_mode_completed):
			current_mode.mode_completed.connect(_on_mode_completed)
		if not current_mode.mode_failed.is_connected(_on_mode_failed):
			current_mode.mode_failed.connect(_on_mode_failed)
		if not current_mode.objective_completed.is_connected(_on_objective_completed):
			current_mode.objective_completed.connect(_on_objective_completed)

		print("Mode: ", current_mode.mode_name)

func print_help() -> void:
	print("\n=== GAME MODE TESTING KEYBOARD SHORTCUTS ===")
	print("1 - Start Tutorial Story Level")
	print("2 - Start Classic Challenge")
	print("3 - Start Hardcore Challenge")
	print("4 - Start Quick Sprint Timed Challenge")
	print("5 - Create Custom Mode")
	print("P - Print Progress Info")
	print("U - Unlock All Modes (Testing)")
	print("R - Reset All Progress")
	print("H - Show This Help")
	print("==========================================\n")
