extends Node

## GameModeManager - Singleton to manage game modes
## Handles mode selection, progression, save data, and mode switching

signal mode_changed(new_mode: BaseGameMode)
signal mode_completed(results: Dictionary)
signal mode_failed(mode_name: String, reason: String)
signal progress_saved()
signal progress_loaded()

## Current active mode
var current_mode: BaseGameMode = null
var previous_mode: BaseGameMode = null

## Save data
var save_data = {
	"story_progress": {},      # level_id: {completed: bool, stars: int, best_time: float}
	"challenge_records": {},   # challenge_type: {high_score: int, high_distance: float, ...}
	"timed_records": {},       # timed_type: {best_rank: String, best_time: float, ...}
	"unlocked_modes": [],      # List of unlocked mode IDs
	"total_playtime": 0.0,
	"total_distance": 0.0,
	"total_coins": 0,
	"total_enemies_defeated": 0,
}

const SAVE_PATH = "user://game_mode_progress.save"

## Mode libraries - prebuilt modes
var story_levels: Dictionary = {}
var challenge_modes: Dictionary = {}
var timed_challenges: Dictionary = {}

func _ready() -> void:
	"""Initialize the game mode manager"""
	_initialize_story_levels()
	_initialize_challenge_modes()
	_initialize_timed_challenges()
	load_progress()

## Initialization

func _initialize_story_levels() -> void:
	"""Create all story mode levels"""
	story_levels["tutorial"] = StoryMode.create_tutorial_level()
	story_levels["city_chase"] = StoryMode.create_city_chase_level()
	story_levels["wasteland"] = StoryMode.create_wasteland_level()
	story_levels["speed_trial"] = StoryMode.create_speed_trial_level()
	story_levels["survival"] = StoryMode.create_survival_level()

	# Unlock tutorial by default
	if not "tutorial" in save_data["unlocked_modes"]:
		save_data["unlocked_modes"].append("tutorial")

func _initialize_challenge_modes() -> void:
	"""Create all challenge mode variants"""
	challenge_modes["classic"] = ChallengeMode.create_classic_challenge()
	challenge_modes["hardcore"] = ChallengeMode.create_hardcore_challenge()
	challenge_modes["speed_demon"] = ChallengeMode.create_speed_demon_challenge()
	challenge_modes["coin_rush"] = ChallengeMode.create_coin_rush_challenge()
	challenge_modes["combat_master"] = ChallengeMode.create_combat_master_challenge()
	challenge_modes["perfectionist"] = ChallengeMode.create_perfectionist_challenge()

	# Unlock classic by default
	if not "classic" in save_data["unlocked_modes"]:
		save_data["unlocked_modes"].append("classic")

func _initialize_timed_challenges() -> void:
	"""Create timed challenge presets"""
	timed_challenges["quick_sprint"] = TimedMode.create_quick_sprint()
	timed_challenges["medium_marathon"] = TimedMode.create_medium_marathon()
	timed_challenges["hard_gauntlet"] = TimedMode.create_hard_gauntlet()
	timed_challenges["treasure_hunt"] = TimedMode.create_treasure_hunt()
	timed_challenges["battle_royale"] = TimedMode.create_battle_royale()

	# Unlock quick sprint by default
	if not "quick_sprint" in save_data["unlocked_modes"]:
		save_data["unlocked_modes"].append("quick_sprint")

## Mode Management

func start_mode(mode: BaseGameMode) -> void:
	"""Start a game mode"""
	if current_mode and current_mode.is_active:
		print("Warning: Starting new mode while another is active")
		current_mode.fail_mode("Mode interrupted")

	previous_mode = current_mode
	current_mode = mode

	# Connect signals
	current_mode.mode_completed.connect(_on_mode_completed)
	current_mode.mode_failed.connect(_on_mode_failed)

	current_mode.start_mode()
	mode_changed.emit(current_mode)

func start_story_level(level_id: String) -> bool:
	"""Start a story level by ID"""
	if not level_id in story_levels:
		print("Story level not found: ", level_id)
		return false

	if not is_mode_unlocked(level_id):
		print("Story level locked: ", level_id)
		return false

	start_mode(story_levels[level_id])
	return true

func start_challenge(challenge_id: String) -> bool:
	"""Start a challenge mode by ID"""
	if not challenge_id in challenge_modes:
		print("Challenge mode not found: ", challenge_id)
		return false

	if not is_mode_unlocked(challenge_id):
		print("Challenge mode locked: ", challenge_id)
		return false

	start_mode(challenge_modes[challenge_id])
	return true

func start_timed_challenge(challenge_id: String) -> bool:
	"""Start a timed challenge by ID"""
	if not challenge_id in timed_challenges:
		print("Timed challenge not found: ", challenge_id)
		return false

	if not is_mode_unlocked(challenge_id):
		print("Timed challenge locked: ", challenge_id)
		return false

	start_mode(timed_challenges[challenge_id])
	return true

func update_current_mode(delta: float, game_state: Dictionary) -> void:
	"""Update the active mode - call this from GameManager"""
	if current_mode and current_mode.is_active:
		current_mode.update_mode(delta, game_state)

func get_current_mode() -> BaseGameMode:
	"""Get the currently active mode"""
	return current_mode

func is_mode_active() -> bool:
	"""Check if a mode is currently running"""
	return current_mode != null and current_mode.is_active

## Event Handlers

func _on_mode_completed(results: Dictionary) -> void:
	"""Handle mode completion"""
	print("Mode completed: ", results)

	# Update save data based on mode type
	if current_mode is StoryMode:
		_save_story_progress(current_mode as StoryMode, results)
	elif current_mode is ChallengeMode:
		_save_challenge_record(current_mode as ChallengeMode, results)
	elif current_mode is TimedMode:
		_save_timed_record(current_mode as TimedMode, results)

	# Update totals
	_update_totals(results)

	save_progress()
	mode_completed.emit(results)

func _on_mode_failed(reason: String) -> void:
	"""Handle mode failure"""
	print("Mode failed: ", current_mode.mode_name, " - ", reason)
	mode_failed.emit(current_mode.mode_name, reason)

func on_player_death() -> void:
	"""Forward player death to current mode"""
	if current_mode and current_mode.is_active:
		current_mode.on_player_death()

## Save/Load

func _save_story_progress(mode: StoryMode, results: Dictionary) -> void:
	"""Save story level progress"""
	var level_id = mode.level_id
	var existing = save_data["story_progress"].get(level_id, {})

	var new_data = {
		"completed": true,
		"stars": results.get("stars_earned", 0),
		"best_time": results.get("time_elapsed", 999999.0),
		"lives_remaining": results.get("lives_remaining", 0)
	}

	# Keep best records
	if existing.has("best_time"):
		new_data["best_time"] = min(existing["best_time"], new_data["best_time"])
	if existing.has("stars"):
		new_data["stars"] = max(existing["stars"], new_data["stars"])

	save_data["story_progress"][level_id] = new_data

	# Unlock next level if applicable
	if mode.unlocks_next_level and mode.next_level_id != "":
		unlock_mode(mode.next_level_id)

func _save_challenge_record(mode: ChallengeMode, results: Dictionary) -> void:
	"""Save challenge mode records"""
	var challenge_id = ChallengeMode.ChallengeType.keys()[mode.challenge_type].to_lower()
	var existing = save_data["challenge_records"].get(challenge_id, {})

	# This is called on completion, but challenge mode calls fail_mode instead
	# So this shouldn't normally be called, but we handle it anyway
	pass

func _save_timed_record(mode: TimedMode, results: Dictionary) -> void:
	"""Save timed challenge records"""
	var timed_type = TimedMode.TimedType.keys()[mode.timed_type].to_lower()
	var existing = save_data["timed_records"].get(timed_type, {})

	var new_data = {
		"completed": true,
		"best_time": results.get("time_elapsed", 999999.0),
		"best_rank": mode.get_rank(),
		"bonus_objectives": results.get("bonus_objectives_complete", 0)
	}

	# Keep best records
	if existing.has("best_time"):
		new_data["best_time"] = min(existing["best_time"], new_data["best_time"])

	save_data["timed_records"][timed_type] = new_data

func _update_totals(results: Dictionary) -> void:
	"""Update total stats"""
	if results.has("time_elapsed"):
		save_data["total_playtime"] += results["time_elapsed"]

	# Would extract more stats from game_state if available

func save_progress() -> void:
	"""Save progress to file"""
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_var(save_data)
		file.close()
		progress_saved.emit()
		print("Progress saved")
	else:
		print("Failed to save progress")

func load_progress() -> void:
	"""Load progress from file"""
	if not FileAccess.file_exists(SAVE_PATH):
		print("No save file found, using defaults")
		return

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var loaded_data = file.get_var()
		file.close()

		if loaded_data is Dictionary:
			# Merge with default structure
			for key in loaded_data:
				save_data[key] = loaded_data[key]
			progress_loaded.emit()
			print("Progress loaded")
	else:
		print("Failed to load progress")

func reset_progress() -> void:
	"""Reset all progress (for testing or player request)"""
	save_data = {
		"story_progress": {},
		"challenge_records": {},
		"timed_records": {},
		"unlocked_modes": ["tutorial", "classic", "quick_sprint"],
		"total_playtime": 0.0,
		"total_distance": 0.0,
		"total_coins": 0,
		"total_enemies_defeated": 0,
	}
	save_progress()

## Query Methods

func is_mode_unlocked(mode_id: String) -> bool:
	"""Check if a mode is unlocked"""
	return mode_id in save_data["unlocked_modes"]

func unlock_mode(mode_id: String) -> void:
	"""Unlock a mode"""
	if not is_mode_unlocked(mode_id):
		save_data["unlocked_modes"].append(mode_id)
		print("Mode unlocked: ", mode_id)
		save_progress()

func get_story_progress(level_id: String) -> Dictionary:
	"""Get progress for a story level"""
	return save_data["story_progress"].get(level_id, {})

func get_challenge_record(challenge_type: String) -> Dictionary:
	"""Get records for a challenge mode"""
	return save_data["challenge_records"].get(challenge_type, {})

func get_timed_record(timed_type: String) -> Dictionary:
	"""Get records for a timed challenge"""
	return save_data["timed_records"].get(timed_type, {})

func get_unlocked_story_levels() -> Array:
	"""Get list of unlocked story levels"""
	var unlocked = []
	for level_id in story_levels.keys():
		if is_mode_unlocked(level_id):
			unlocked.append(story_levels[level_id])
	return unlocked

func get_unlocked_challenges() -> Array:
	"""Get list of unlocked challenge modes"""
	var unlocked = []
	for challenge_id in challenge_modes.keys():
		if is_mode_unlocked(challenge_id):
			unlocked.append(challenge_modes[challenge_id])
	return unlocked

func get_unlocked_timed_challenges() -> Array:
	"""Get list of unlocked timed challenges"""
	var unlocked = []
	for timed_id in timed_challenges.keys():
		if is_mode_unlocked(timed_id):
			unlocked.append(timed_challenges[timed_id])
	return unlocked

func get_total_stats() -> Dictionary:
	"""Get total statistics"""
	return {
		"playtime": save_data["total_playtime"],
		"distance": save_data["total_distance"],
		"coins": save_data["total_coins"],
		"enemies_defeated": save_data["total_enemies_defeated"],
		"story_levels_completed": save_data["story_progress"].size(),
		"total_stars": _count_total_stars(),
	}

func _count_total_stars() -> int:
	"""Count total stars earned across all story levels"""
	var total = 0
	for level_data in save_data["story_progress"].values():
		total += level_data.get("stars", 0)
	return total
