extends Node

## GameManager Mode Integration
## This script integrates the game mode system with GameManager3D
## Attach this as a child of GameManager3D or use as an autoload

var game_manager: Node3D = null
var mode_objectives_ui: CanvasLayer = null
var mode_selection_ui: CanvasLayer = null

signal game_mode_ready()

func _ready() -> void:
	"""Initialize mode integration"""
	# Wait a frame for everything to be ready
	await get_tree().process_frame

	# Find the game manager
	game_manager = get_parent() if get_parent() is Node3D else get_tree().get_first_node_in_group("game_manager")

	if not game_manager:
		print("Warning: GameManager not found for mode integration")
		return

	# Create mode objectives UI
	_setup_mode_objectives_ui()

	# Connect to GameModeManager signals
	if GameModeManager:
		GameModeManager.mode_changed.connect(_on_mode_changed)
		GameModeManager.mode_completed.connect(_on_mode_completed)
		GameModeManager.mode_failed.connect(_on_mode_failed)

	game_mode_ready.emit()

func _setup_mode_objectives_ui() -> void:
	"""Create the mode objectives UI"""
	var ModeObjectivesUIScript = load("res://scripts/ui/ModeObjectivesUI.gd")
	if ModeObjectivesUIScript:
		mode_objectives_ui = ModeObjectivesUIScript.new()
		mode_objectives_ui.name = "ModeObjectivesUI"
		get_tree().root.add_child(mode_objectives_ui)

func _process(delta: float) -> void:
	"""Update game mode system"""
	if not GameModeManager or not game_manager:
		return

	if GameModeManager.is_mode_active():
		# Build game state from GameManager3D
		var game_state = _get_game_state()

		# Update the current mode
		GameModeManager.update_current_mode(delta, game_state)

func _get_game_state() -> Dictionary:
	"""Extract game state from GameManager3D"""
	if not game_manager:
		return {}

	return {
		"distance": game_manager.get("distance_traveled") if game_manager.has("distance_traveled") else 0.0,
		"score": game_manager.get("score") if game_manager.has("score") else 0,
		"coins": game_manager.get("coins") if game_manager.has("coins") else 0,
		"enemies_defeated": 0,  # Would need to track this
		"perfect_dodges": game_manager.get("perfect_dodge_streak") if game_manager.has("perfect_dodge_streak") else 0,
		"damage_taken": 0,  # Would need to track this
		"max_combo": game_manager.get("perfect_dodge_streak") if game_manager.has("perfect_dodge_streak") else 0,
		"xp": game_manager.get("xp") if game_manager.has("xp") else 0,
	}

## Event Handlers

func _on_mode_changed(mode: BaseGameMode) -> void:
	"""Handle mode change"""
	print("Mode changed to: ", mode.mode_name)

	# Update UI
	if mode_objectives_ui:
		mode_objectives_ui.set_mode(mode)

	# Apply mode configuration to game manager
	_apply_mode_config(mode)

func _on_mode_completed(results: Dictionary) -> void:
	"""Handle mode completion"""
	print("Mode completed: ", results)

	if mode_objectives_ui:
		mode_objectives_ui.show_completion_screen(results)

	# Show results screen
	_show_results_screen(results, true)

func _on_mode_failed(mode_name: String, reason: String) -> void:
	"""Handle mode failure"""
	print("Mode failed: ", mode_name, " - ", reason)

	if mode_objectives_ui:
		mode_objectives_ui.show_failure_screen(reason)

	# Show failure screen
	_show_failure_screen(mode_name, reason)

func _apply_mode_config(mode: BaseGameMode) -> void:
	"""Apply mode configuration to game manager"""
	if not game_manager:
		return

	var config = mode.get_mode_config()

	# Apply difficulty settings
	if config.has("difficulty"):
		if game_manager.has("current_spawn_interval"):
			# Adjust spawn interval based on difficulty
			var base_interval = game_manager.get("base_spawn_interval") if game_manager.has("base_spawn_interval") else 1.8
			game_manager.set("current_spawn_interval", base_interval / config["difficulty"])

	# Apply combat settings
	if config.has("allow_combat"):
		# Could disable enemy spawning if combat is not allowed
		pass

	# Apply biome settings
	if config.has("biome"):
		if game_manager.has("current_biome"):
			game_manager.set("current_biome", config["biome"])

	# Apply challenge mode multipliers
	if config.has("score_multiplier"):
		# Would need to add support for this in GameManager3D
		pass

func _show_results_screen(results: Dictionary, success: bool) -> void:
	"""Show results screen after mode completion"""
	# This would create a more detailed results UI
	# For now, just print the results
	print("\n=== MODE RESULTS ===")
	print("Mode: ", results.get("mode_name", "Unknown"))
	print("Success: ", success)

	if results.has("time_elapsed"):
		var time = results["time_elapsed"]
		print("Time: %d:%02d" % [int(time) / 60, int(time) % 60])

	if results.has("stars_earned"):
		print("Stars: ", results["stars_earned"], "/3")

	if results.has("lives_remaining"):
		print("Lives Remaining: ", results["lives_remaining"])

	if results.has("time_bonus_score"):
		print("Time Bonus: ", results["time_bonus_score"])

	print("==================\n")

func _show_failure_screen(mode_name: String, reason: String) -> void:
	"""Show failure screen"""
	print("\n=== MODE FAILED ===")
	print("Mode: ", mode_name)
	print("Reason: ", reason)
	print("==================\n")

## Public methods for GameManager to call

func start_story_level(level_id: String) -> bool:
	"""Start a story level"""
	if not GameModeManager:
		return false
	return GameModeManager.start_story_level(level_id)

func start_challenge(challenge_id: String) -> bool:
	"""Start a challenge mode"""
	if not GameModeManager:
		return false
	return GameModeManager.start_challenge(challenge_id)

func start_timed_challenge(challenge_id: String) -> bool:
	"""Start a timed challenge"""
	if not GameModeManager:
		return false
	return GameModeManager.start_timed_challenge(challenge_id)

func on_player_death() -> void:
	"""Forward player death to mode manager"""
	if GameModeManager:
		GameModeManager.on_player_death()

func get_current_mode() -> BaseGameMode:
	"""Get current active mode"""
	if GameModeManager:
		return GameModeManager.get_current_mode()
	return null
