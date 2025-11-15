extends Resource
class_name BaseGameMode

## Base class for all game modes
## Defines the structure for objectives, win/lose conditions, and progression

## Mode identification
@export var mode_name: String = "Base Mode"
@export_multiline var mode_description: String = "Base game mode"
@export var mode_icon: Texture2D

## Objective tracking
enum ObjectiveType {
	DISTANCE,        # Reach a certain distance
	SCORE,           # Reach a score target
	TIME_SURVIVE,    # Survive for X seconds
	COLLECT_COINS,   # Collect X coins
	DEFEAT_ENEMIES,  # Defeat X enemies
	PERFECT_DODGES,  # Perform X perfect dodges
	NO_DAMAGE,       # Complete without taking damage
	COMBO,           # Achieve X combo streak
}

class Objective:
	var type: ObjectiveType
	var target_value: float
	var current_value: float = 0.0
	var description: String
	var is_primary: bool = true  # Primary objectives required to win
	var is_complete: bool = false

	func _init(obj_type: ObjectiveType, target: float, desc: String, primary: bool = true):
		type = obj_type
		target_value = target
		description = desc
		is_primary = primary

	func update_progress(value: float) -> void:
		current_value = value
		if current_value >= target_value:
			is_complete = true

	func get_progress_percent() -> float:
		return (current_value / target_value) * 100.0 if target_value > 0 else 0.0

## Mode settings
@export var max_lives: int = 3  # -1 for infinite
@export var has_time_limit: bool = false
@export var time_limit: float = 0.0  # In seconds
@export var allow_combat: bool = true
@export var starting_difficulty: float = 1.0
@export var difficulty_scaling_enabled: bool = true

## Progression
@export var unlocks_next_level: bool = false
@export var next_level_id: String = ""

## Runtime state (not exported)
var objectives: Array[Objective] = []
var current_lives: int
var elapsed_time: float = 0.0
var is_active: bool = false
var is_completed: bool = false
var is_failed: bool = false

## Signals for game manager integration
signal mode_started()
signal mode_completed(results: Dictionary)
signal mode_failed(reason: String)
signal objective_completed(objective: Objective)
signal objective_updated(objective: Objective)

## Lifecycle methods (to be overridden by subclasses)

func start_mode() -> void:
	"""Called when the mode begins"""
	is_active = true
	is_completed = false
	is_failed = false
	current_lives = max_lives
	elapsed_time = 0.0
	reset_objectives()
	mode_started.emit()

func update_mode(delta: float, game_state: Dictionary) -> void:
	"""Called every frame with current game state"""
	if not is_active or is_completed or is_failed:
		return

	elapsed_time += delta

	# Check time limit
	if has_time_limit and elapsed_time >= time_limit:
		fail_mode("Time limit reached")
		return

	# Update objectives based on game state
	update_objectives(game_state)

	# Check completion
	if check_all_objectives_complete():
		complete_mode()

func complete_mode() -> void:
	"""Called when all primary objectives are met"""
	is_active = false
	is_completed = true

	var results = {
		"mode_name": mode_name,
		"time_elapsed": elapsed_time,
		"lives_remaining": current_lives,
		"objectives": objectives,
		"success": true
	}

	mode_completed.emit(results)

func fail_mode(reason: String) -> void:
	"""Called when failure conditions are met"""
	is_active = false
	is_failed = true
	mode_failed.emit(reason)

func on_player_death() -> void:
	"""Called when player dies"""
	if max_lives == -1:  # Infinite lives
		return

	current_lives -= 1
	if current_lives <= 0:
		fail_mode("No lives remaining")

func reset_objectives() -> void:
	"""Reset all objective progress"""
	for objective in objectives:
		objective.current_value = 0.0
		objective.is_complete = false

func update_objectives(game_state: Dictionary) -> void:
	"""Update objective progress based on game state - override in subclasses"""
	for objective in objectives:
		var value = get_objective_value(objective.type, game_state)
		var was_complete = objective.is_complete
		objective.update_progress(value)

		if objective.is_complete and not was_complete:
			objective_completed.emit(objective)
		else:
			objective_updated.emit(objective)

func get_objective_value(type: ObjectiveType, game_state: Dictionary) -> float:
	"""Extract objective value from game state"""
	match type:
		ObjectiveType.DISTANCE:
			return game_state.get("distance", 0.0)
		ObjectiveType.SCORE:
			return game_state.get("score", 0.0)
		ObjectiveType.TIME_SURVIVE:
			return elapsed_time
		ObjectiveType.COLLECT_COINS:
			return game_state.get("coins", 0.0)
		ObjectiveType.DEFEAT_ENEMIES:
			return game_state.get("enemies_defeated", 0.0)
		ObjectiveType.PERFECT_DODGES:
			return game_state.get("perfect_dodges", 0.0)
		ObjectiveType.NO_DAMAGE:
			return 1.0 if game_state.get("damage_taken", 0) == 0 else 0.0
		ObjectiveType.COMBO:
			return game_state.get("max_combo", 0.0)

	return 0.0

func check_all_objectives_complete() -> bool:
	"""Check if all primary objectives are complete"""
	for objective in objectives:
		if objective.is_primary and not objective.is_complete:
			return false
	return true

func get_primary_objectives() -> Array[Objective]:
	"""Get list of primary objectives"""
	var primary: Array[Objective] = []
	for objective in objectives:
		if objective.is_primary:
			primary.append(objective)
	return primary

func get_secondary_objectives() -> Array[Objective]:
	"""Get list of secondary (bonus) objectives"""
	var secondary: Array[Objective] = []
	for objective in objectives:
		if not objective.is_primary:
			secondary.append(objective)
	return secondary

func get_time_remaining() -> float:
	"""Get remaining time if time limit is active"""
	if not has_time_limit:
		return -1.0
	return max(0.0, time_limit - elapsed_time)

func get_lives_remaining() -> int:
	"""Get current lives remaining"""
	return current_lives

func add_objective(type: ObjectiveType, target: float, description: String, is_primary: bool = true) -> Objective:
	"""Helper to add a new objective"""
	var obj = Objective.new(type, target, description, is_primary)
	objectives.append(obj)
	return obj

## Virtual methods for subclasses to override
func get_mode_config() -> Dictionary:
	"""Return mode-specific configuration for game manager"""
	return {
		"difficulty": starting_difficulty,
		"difficulty_scaling": difficulty_scaling_enabled,
		"allow_combat": allow_combat,
		"max_lives": max_lives,
	}

func get_ui_data() -> Dictionary:
	"""Return data for UI display"""
	return {
		"mode_name": mode_name,
		"description": mode_description,
		"objectives": objectives,
		"time_remaining": get_time_remaining(),
		"lives_remaining": get_lives_remaining(),
		"elapsed_time": elapsed_time,
	}
