extends BaseGameMode
class_name TimedMode

## Timed Mode - Race against the clock to achieve objectives
## Score targets, distance goals, or survival challenges within time limit

## Timed challenge variants
enum TimedType {
	SCORE_ATTACK,    # Reach target score before time runs out
	DISTANCE_RACE,   # Reach target distance as fast as possible
	COIN_FRENZY,     # Collect as many coins as possible
	ENEMY_RUSH,      # Defeat as many enemies as possible
	SURVIVAL_TRIAL,  # Just survive the time limit
	COMBO_CHALLENGE, # Maintain highest combo streak
}

@export var timed_type: TimedType = TimedType.SCORE_ATTACK
@export var bonus_time_per_objective: float = 10.0  # Extra time for completing objectives
@export var time_bonus_points: int = 100  # Points per second remaining

var time_bonuses_collected: int = 0

static func create_score_attack(target_score: int, time_seconds: float, difficulty: float = 1.5) -> TimedMode:
	var mode = TimedMode.new()
	mode.mode_name = "Score Attack"
	mode.mode_description = "Reach the target score before time runs out!"
	mode.timed_type = TimedType.SCORE_ATTACK

	# Primary objective
	mode.add_objective(ObjectiveType.SCORE, float(target_score), "Reach %d points" % target_score, true)

	# Bonus objectives
	mode.add_objective(ObjectiveType.COMBO, 15.0, "Achieve 15x combo", false)
	mode.add_objective(ObjectiveType.PERFECT_DODGES, 10.0, "10 perfect dodges", false)

	mode.has_time_limit = true
	mode.time_limit = time_seconds
	mode.max_lives = 3
	mode.starting_difficulty = difficulty
	mode.difficulty_scaling_enabled = true
	mode.allow_combat = true

	return mode

static func create_distance_race(target_distance: float, time_seconds: float, difficulty: float = 1.5) -> TimedMode:
	var mode = TimedMode.new()
	mode.mode_name = "Distance Race"
	mode.mode_description = "Reach the checkpoint as fast as possible!"
	mode.timed_type = TimedType.DISTANCE_RACE

	# Primary objective
	mode.add_objective(ObjectiveType.DISTANCE, target_distance, "Reach %d distance" % int(target_distance), true)

	# Bonus objectives
	mode.add_objective(ObjectiveType.COLLECT_COINS, 75.0, "Collect 75 coins", false)
	mode.add_objective(ObjectiveType.NO_DAMAGE, 1.0, "No damage taken", false)

	mode.has_time_limit = true
	mode.time_limit = time_seconds
	mode.max_lives = 3
	mode.starting_difficulty = difficulty
	mode.difficulty_scaling_enabled = false  # Fixed difficulty for racing
	mode.allow_combat = true

	return mode

static func create_coin_frenzy(time_seconds: float, difficulty: float = 1.0) -> TimedMode:
	var mode = TimedMode.new()
	mode.mode_name = "Coin Frenzy"
	mode.mode_description = "Collect as many coins as possible in the time limit!"
	mode.timed_type = TimedType.COIN_FRENZY

	# Tiered objectives - collect as many as possible
	mode.add_objective(ObjectiveType.COLLECT_COINS, 50.0, "Collect 50 coins (Bronze)", true)
	mode.add_objective(ObjectiveType.COLLECT_COINS, 100.0, "Collect 100 coins (Silver)", false)
	mode.add_objective(ObjectiveType.COLLECT_COINS, 200.0, "Collect 200 coins (Gold)", false)

	mode.has_time_limit = true
	mode.time_limit = time_seconds
	mode.max_lives = 5
	mode.starting_difficulty = difficulty
	mode.difficulty_scaling_enabled = false
	mode.allow_combat = false  # Focus on collection

	return mode

static func create_enemy_rush(time_seconds: float, difficulty: float = 2.0) -> TimedMode:
	var mode = TimedMode.new()
	mode.mode_name = "Enemy Rush"
	mode.mode_description = "Defeat as many enemies as possible!"
	mode.timed_type = TimedType.ENEMY_RUSH

	# Tiered objectives
	mode.add_objective(ObjectiveType.DEFEAT_ENEMIES, 5.0, "Defeat 5 enemies (Bronze)", true)
	mode.add_objective(ObjectiveType.DEFEAT_ENEMIES, 10.0, "Defeat 10 enemies (Silver)", false)
	mode.add_objective(ObjectiveType.DEFEAT_ENEMIES, 20.0, "Defeat 20 enemies (Gold)", false)

	mode.has_time_limit = true
	mode.time_limit = time_seconds
	mode.max_lives = 5
	mode.starting_difficulty = difficulty
	mode.difficulty_scaling_enabled = true
	mode.allow_combat = true

	return mode

static func create_survival_trial(time_seconds: float, difficulty: float = 2.5) -> TimedMode:
	var mode = TimedMode.new()
	mode.mode_name = "Survival Trial"
	mode.mode_description = "Just survive! Can you make it to the end?"
	mode.timed_type = TimedType.SURVIVAL_TRIAL

	# Primary objective is just surviving
	mode.add_objective(ObjectiveType.TIME_SURVIVE, time_seconds, "Survive %d seconds" % int(time_seconds), true)

	# Bonus objectives
	mode.add_objective(ObjectiveType.DISTANCE, 1000.0, "Reach 1000 distance", false)
	mode.add_objective(ObjectiveType.DEFEAT_ENEMIES, 5.0, "Defeat 5 enemies", false)
	mode.add_objective(ObjectiveType.NO_DAMAGE, 1.0, "Take no damage", false)

	mode.has_time_limit = true
	mode.time_limit = time_seconds
	mode.max_lives = 1  # One life for survival
	mode.starting_difficulty = difficulty
	mode.difficulty_scaling_enabled = true
	mode.allow_combat = true

	return mode

static func create_combo_challenge(time_seconds: float, target_combo: int = 20, difficulty: float = 1.5) -> TimedMode:
	var mode = TimedMode.new()
	mode.mode_name = "Combo Master"
	mode.mode_description = "Build and maintain the highest combo streak!"
	mode.timed_type = TimedType.COMBO_CHALLENGE

	# Primary objective
	mode.add_objective(ObjectiveType.COMBO, float(target_combo), "Achieve %dx combo" % target_combo, true)

	# Bonus objectives
	mode.add_objective(ObjectiveType.PERFECT_DODGES, 20.0, "20 perfect dodges", false)
	mode.add_objective(ObjectiveType.SCORE, 5000.0, "Score 5000 points", false)

	mode.has_time_limit = true
	mode.time_limit = time_seconds
	mode.max_lives = 3
	mode.starting_difficulty = difficulty
	mode.difficulty_scaling_enabled = true
	mode.allow_combat = true

	return mode

## Quick preset levels
static func create_quick_sprint() -> TimedMode:
	return create_distance_race(500.0, 60.0, 1.0)  # 500 distance in 60 seconds

static func create_medium_marathon() -> TimedMode:
	return create_distance_race(1200.0, 120.0, 1.5)  # 1200 distance in 2 minutes

static func create_hard_gauntlet() -> TimedMode:
	return create_survival_trial(180.0, 3.0)  # Survive 3 minutes at high difficulty

static func create_treasure_hunt() -> TimedMode:
	return create_coin_frenzy(90.0, 1.0)  # 90 second coin collection

static func create_battle_royale() -> TimedMode:
	return create_enemy_rush(120.0, 2.0)  # 2 minute enemy gauntlet

## Lifecycle overrides

func update_mode(delta: float, game_state: Dictionary) -> void:
	super.update_mode(delta, game_state)

	# Timed modes automatically fail when time runs out
	# This is handled in BaseGameMode, but we can add warnings here
	if has_time_limit:
		var remaining = get_time_remaining()
		if remaining <= 10.0 and remaining > 9.9:
			# Could emit warning signal for UI
			pass

func complete_mode() -> void:
	"""Calculate time bonus and complete"""
	is_active = false
	is_completed = true

	# Calculate time bonus score
	var time_remaining = get_time_remaining()
	var bonus_score = int(time_remaining) * time_bonus_points

	# Count completed bonus objectives
	var bonus_objectives_complete = 0
	for objective in get_secondary_objectives():
		if objective.is_complete:
			bonus_objectives_complete += 1

	var results = {
		"mode_name": mode_name,
		"timed_type": TimedType.keys()[timed_type],
		"time_elapsed": elapsed_time,
		"time_remaining": time_remaining,
		"time_bonus_score": bonus_score,
		"lives_remaining": current_lives,
		"objectives": objectives,
		"bonus_objectives_complete": bonus_objectives_complete,
		"success": true
	}

	mode_completed.emit(results)

func fail_mode(reason: String) -> void:
	"""Timed mode failure"""
	is_active = false
	is_failed = true

	# Still provide results even on failure
	var completed_primary = 0
	for obj in get_primary_objectives():
		if obj.is_complete:
			completed_primary += 1

	var results = {
		"mode_name": mode_name,
		"timed_type": TimedType.keys()[timed_type],
		"time_elapsed": elapsed_time,
		"reason": reason,
		"objectives_completed": completed_primary,
		"total_objectives": get_primary_objectives().size(),
		"success": false
	}

	mode_failed.emit(reason)

func add_bonus_time(seconds: float) -> void:
	"""Add bonus time for completing objectives or special actions"""
	if has_time_limit:
		time_limit += seconds
		time_bonuses_collected += 1
		print("Bonus time! +", seconds, " seconds")

func get_mode_config() -> Dictionary:
	var config = super.get_mode_config()
	config["is_timed_mode"] = true
	config["timed_type"] = timed_type
	config["time_limit"] = time_limit
	config["has_time_limit"] = true
	return config

func get_ui_data() -> Dictionary:
	var data = super.get_ui_data()
	data["timed_type"] = TimedType.keys()[timed_type]
	data["time_bonuses_collected"] = time_bonuses_collected
	data["time_bonus_points"] = time_bonus_points

	# Calculate potential time bonus
	if is_completed:
		data["time_bonus_score"] = int(get_time_remaining()) * time_bonus_points
	else:
		data["potential_time_bonus"] = int(get_time_remaining()) * time_bonus_points

	return data

func get_rank() -> String:
	"""Get rank based on performance (for UI display)"""
	var completed_bonus = 0
	for obj in get_secondary_objectives():
		if obj.is_complete:
			completed_bonus += 1

	var total_bonus = get_secondary_objectives().size()

	if not is_completed:
		return "FAILED"
	elif completed_bonus == total_bonus and current_lives == max_lives:
		return "S-RANK"
	elif completed_bonus == total_bonus:
		return "A-RANK"
	elif completed_bonus >= total_bonus / 2:
		return "B-RANK"
	else:
		return "C-RANK"
