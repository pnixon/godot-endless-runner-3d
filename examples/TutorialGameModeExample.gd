## Tutorial: Creating Custom Game Modes
## This file demonstrates how to create custom game modes using the modular BaseGameMode system

extends Node

## Example 1: Simple Distance Challenge
## Goal: Travel a specific distance
class TutorialDistanceMode extends "res://scripts/game_modes/BaseGameMode.gd":
	func _init():
		# Basic info
		mode_name = "Distance Challenge"
		description = "Travel 500 meters to win!"
		mode_type = "challenge"

		# Define objective
		objectives = {
			"distance": {"target": 500.0, "current": 0.0}
		}

		# Star thresholds (distance in meters)
		star_thresholds = {
			1: 300.0,  # 1 star
			2: 400.0,  # 2 stars
			3: 500.0   # 3 stars (complete)
		}

		# Game rules
		lives_type = "limited"
		starting_lives = 3
		time_limit = 0  # No time limit

	# Update when player travels
	func update_progress(event_type: String, value):
		if event_type == "distance_traveled":
			objectives["distance"]["current"] = value
			emit_signal("objectives_updated", objectives)

	# Check if player won
	func check_completion() -> bool:
		return objectives["distance"]["current"] >= objectives["distance"]["target"]

	# Check if player lost
	func check_failure_condition(game_state: Dictionary) -> bool:
		return game_state.get("lives", 3) <= 0

	# Factory method
	static func create() -> TutorialDistanceMode:
		return TutorialDistanceMode.new()


## Example 2: Coin Collection Mode
## Goal: Collect a specific number of coins
class TutorialCoinMode extends "res://scripts/game_modes/BaseGameMode.gd":
	func _init():
		mode_name = "Coin Collector"
		description = "Collect 100 coins!"
		mode_type = "challenge"

		objectives = {
			"coins": {"target": 100, "current": 0}
		}

		star_thresholds = {
			1: 50,   # 1 star = 50 coins
			2: 75,   # 2 stars = 75 coins
			3: 100   # 3 stars = 100 coins
		}

		lives_type = "infinite"  # Can't die, just collect coins
		time_limit = 120  # 2 minutes

	func update_progress(event_type: String, value):
		if event_type == "coin_collected":
			objectives["coins"]["current"] += value
			emit_signal("objectives_updated", objectives)

	func check_completion() -> bool:
		return objectives["coins"]["current"] >= objectives["coins"]["target"]

	func check_failure_condition(game_state: Dictionary) -> bool:
		# Fail if time runs out
		return game_state.get("time_remaining", 120) <= 0

	static func create() -> TutorialCoinMode:
		return TutorialCoinMode.new()


## Example 3: Combat Mastery Mode
## Goal: Defeat enemies with specific requirements
class TutorialCombatMode extends "res://scripts/game_modes/BaseGameMode.gd":
	func _init():
		mode_name = "Combat Master"
		description = "Defeat 10 enemies without taking damage!"
		mode_type = "challenge"

		objectives = {
			"enemies_defeated": {"target": 10, "current": 0},
			"damage_taken": {"target": 0, "current": 0}  # Must stay at 0
		}

		star_thresholds = {
			1: 5,   # Defeat 5 enemies
			2: 7,   # Defeat 7 enemies
			3: 10   # Defeat 10 enemies with no damage
		}

		lives_type = "one_life"  # Hardcore mode
		time_limit = 0

	func update_progress(event_type: String, value):
		match event_type:
			"enemy_defeated":
				objectives["enemies_defeated"]["current"] += 1
			"damage_taken":
				objectives["damage_taken"]["current"] += value

		emit_signal("objectives_updated", objectives)

	func check_completion() -> bool:
		return (objectives["enemies_defeated"]["current"] >= objectives["enemies_defeated"]["target"]
			and objectives["damage_taken"]["current"] == 0)

	func check_failure_condition(game_state: Dictionary) -> bool:
		# Fail if took any damage
		return objectives["damage_taken"]["current"] > 0

	static func create() -> TutorialCombatMode:
		return TutorialCombatMode.new()


## Example 4: Multi-Objective Mode
## Goal: Complete multiple objectives
class TutorialMultiObjectiveMode extends "res://scripts/game_modes/BaseGameMode.gd":
	func _init():
		mode_name = "Triple Threat"
		description = "Complete all 3 challenges!"
		mode_type = "challenge"

		# Multiple objectives
		objectives = {
			"distance": {"target": 200.0, "current": 0.0},
			"coins": {"target": 50, "current": 0},
			"enemies": {"target": 5, "current": 0}
		}

		# Stars based on objectives completed
		star_thresholds = {
			1: 1,  # Complete any 1 objective
			2: 2,  # Complete any 2 objectives
			3: 3   # Complete all 3 objectives
		}

		lives_type = "limited"
		starting_lives = 5
		time_limit = 180  # 3 minutes

	func update_progress(event_type: String, value):
		match event_type:
			"distance_traveled":
				objectives["distance"]["current"] = value
			"coin_collected":
				objectives["coins"]["current"] += value
			"enemy_defeated":
				objectives["enemies"]["current"] += 1

		emit_signal("objectives_updated", objectives)

	func check_completion() -> bool:
		# All objectives must be met
		return (objectives["distance"]["current"] >= objectives["distance"]["target"]
			and objectives["coins"]["current"] >= objectives["coins"]["target"]
			and objectives["enemies"]["current"] >= objectives["enemies"]["target"])

	func check_failure_condition(game_state: Dictionary) -> bool:
		return (game_state.get("lives", 5) <= 0
			or game_state.get("time_remaining", 180) <= 0)

	func get_completed_objectives() -> int:
		"""Helper to count completed objectives for star rating"""
		var completed = 0
		if objectives["distance"]["current"] >= objectives["distance"]["target"]:
			completed += 1
		if objectives["coins"]["current"] >= objectives["coins"]["target"]:
			completed += 1
		if objectives["enemies"]["current"] >= objectives["enemies"]["target"]:
			completed += 1
		return completed

	static func create() -> TutorialMultiObjectiveMode:
		return TutorialMultiObjectiveMode.new()


## Example 5: Progressive Difficulty Mode
## Goal: Survive as difficulty increases
class TutorialProgressiveMode extends "res://scripts/game_modes/BaseGameMode.gd":
	var difficulty_level: int = 1
	var max_difficulty: int = 5

	func _init():
		mode_name = "Progressive Gauntlet"
		description = "Survive through 5 difficulty levels!"
		mode_type = "challenge"

		objectives = {
			"current_level": {"target": 5, "current": 1},
			"time_survived": {"target": 300.0, "current": 0.0}
		}

		star_thresholds = {
			1: 2,  # Reach level 2
			2: 4,  # Reach level 4
			3: 5   # Complete all 5 levels
		}

		lives_type = "limited"
		starting_lives = 3
		time_limit = 0

	func update_progress(event_type: String, value):
		match event_type:
			"time_survived":
				objectives["time_survived"]["current"] = value
				# Every 60 seconds, increase difficulty
				var new_level = int(value / 60.0) + 1
				if new_level > difficulty_level and new_level <= max_difficulty:
					_level_up(new_level)
			"level_completed":
				difficulty_level = value
				objectives["current_level"]["current"] = value

		emit_signal("objectives_updated", objectives)

	func _level_up(new_level: int):
		"""Called when difficulty increases"""
		difficulty_level = new_level
		objectives["current_level"]["current"] = new_level
		emit_signal("difficulty_increased", new_level)
		print("Difficulty increased to level %d!" % new_level)

	func get_difficulty_multiplier() -> float:
		"""Returns difficulty scaling multiplier"""
		return 1.0 + (difficulty_level - 1) * 0.3

	func check_completion() -> bool:
		return difficulty_level >= max_difficulty

	func check_failure_condition(game_state: Dictionary) -> bool:
		return game_state.get("lives", 3) <= 0

	static func create() -> TutorialProgressiveMode:
		return TutorialProgressiveMode.new()


## HOW TO USE THESE MODES
##
## In your game/menu script:
##
## # Create the mode
## var distance_mode = TutorialDistanceMode.create()
##
## # Register with GameModeManager (if using)
## GameModeManager.set_active_mode(distance_mode)
##
## # Connect to signals
## distance_mode.objectives_updated.connect(_on_objectives_updated)
## distance_mode.mode_completed.connect(_on_mode_completed)
## distance_mode.mode_failed.connect(_on_mode_failed)
##
## # During gameplay, update progress
## distance_mode.update_progress("distance_traveled", player.distance)
## distance_mode.update_progress("coin_collected", 10)
## distance_mode.update_progress("enemy_defeated", 1)
##
## # Check status
## if distance_mode.check_completion():
##     print("Mode completed!")
##     var stars = distance_mode.get_star_rating()
##     print("Earned %d stars!" % stars)
##


## FACTORY HELPER
## Convenient way to get all tutorial modes
class TutorialModeFactory:
	static func get_all_modes() -> Array:
		"""Returns all tutorial game modes"""
		return [
			TutorialDistanceMode.create(),
			TutorialCoinMode.create(),
			TutorialCombatMode.create(),
			TutorialMultiObjectiveMode.create(),
			TutorialProgressiveMode.create()
		]

	static func get_mode_by_name(mode_name: String):
		"""Get specific mode by name"""
		match mode_name.to_lower():
			"distance":
				return TutorialDistanceMode.create()
			"coin":
				return TutorialCoinMode.create()
			"combat":
				return TutorialCombatMode.create()
			"multi":
				return TutorialMultiObjectiveMode.create()
			"progressive":
				return TutorialProgressiveMode.create()
			_:
				return null


## EXAMPLE INTEGRATION IN GAME MANAGER
##
## extends Node
##
## var current_mode
## var player
##
## func _ready():
##     # Select a mode
##     current_mode = TutorialDistanceMode.create()
##
##     # Connect signals
##     current_mode.objectives_updated.connect(_update_ui)
##     current_mode.mode_completed.connect(_on_victory)
##     current_mode.mode_failed.connect(_on_game_over)
##
##     # Start game
##     _start_game()
##
## func _process(delta):
##     if player:
##         # Update mode progress
##         current_mode.update_progress("distance_traveled", player.distance_traveled)
##         current_mode.update_progress("time_survived", player.time_alive)
##
##         # Check win/loss conditions
##         var game_state = {
##             "lives": player.lives,
##             "time_remaining": current_mode.time_limit - player.time_alive
##         }
##
##         if current_mode.check_completion():
##             _on_victory()
##         elif current_mode.check_failure_condition(game_state):
##             _on_game_over()
##
## func _update_ui(objectives):
##     print("Objectives updated: ", objectives)
##
## func _on_victory():
##     var stars = current_mode.get_star_rating()
##     print("Victory! Earned %d stars!" % stars)
##
## func _on_game_over():
##     print("Game Over!")
