extends BaseGameMode
class_name ChallengeMode

## Challenge Mode - Infinite endless runner with high score tracking
## Progressive difficulty, no win condition, play until death

## High score tracking
var high_score: int = 0
var high_distance: float = 0.0
var longest_survival_time: float = 0.0

## Challenge variants
enum ChallengeType {
	CLASSIC,        # Standard endless runner
	HARDCORE,       # One life, higher difficulty
	SPEED_DEMON,    # Faster speed, more points
	COIN_RUSH,      # Extra coins, coin-focused scoring
	COMBAT_MASTER,  # More enemy encounters, combat-focused
	PERFECTIONIST,  # Bonus for perfect dodges, no mistakes
}

@export var challenge_type: ChallengeType = ChallengeType.CLASSIC
@export var score_multiplier: float = 1.0
@export var speed_multiplier: float = 1.0
@export var coin_multiplier: float = 1.0
@export var enemy_spawn_multiplier: float = 1.0

## Milestone tracking for achievements/unlocks
var milestones_reached: Array[String] = []

static func create_classic_challenge() -> ChallengeMode:
	var mode = ChallengeMode.new()
	mode.mode_name = "Classic Endless"
	mode.mode_description = "The original endless runner experience. How far can you go?"
	mode.challenge_type = ChallengeType.CLASSIC

	# No specific objectives, just survive
	mode.max_lives = 3
	mode.has_time_limit = false
	mode.starting_difficulty = 1.0
	mode.difficulty_scaling_enabled = true
	mode.allow_combat = true

	mode.score_multiplier = 1.0
	mode.speed_multiplier = 1.0
	mode.coin_multiplier = 1.0
	mode.enemy_spawn_multiplier = 1.0

	return mode

static func create_hardcore_challenge() -> ChallengeMode:
	var mode = ChallengeMode.new()
	mode.mode_name = "Hardcore Mode"
	mode.mode_description = "One life. Maximum difficulty. Only for the brave."
	mode.challenge_type = ChallengeType.HARDCORE

	mode.max_lives = 1
	mode.has_time_limit = false
	mode.starting_difficulty = 2.0
	mode.difficulty_scaling_enabled = true
	mode.allow_combat = true

	mode.score_multiplier = 2.0  # Double points for hardcore
	mode.speed_multiplier = 1.2
	mode.coin_multiplier = 1.0
	mode.enemy_spawn_multiplier = 1.5

	return mode

static func create_speed_demon_challenge() -> ChallengeMode:
	var mode = ChallengeMode.new()
	mode.mode_name = "Speed Demon"
	mode.mode_description = "Everything moves faster! Can you keep up?"
	mode.challenge_type = ChallengeType.SPEED_DEMON

	mode.max_lives = 3
	mode.has_time_limit = false
	mode.starting_difficulty = 1.5
	mode.difficulty_scaling_enabled = true
	mode.allow_combat = true

	mode.score_multiplier = 1.5
	mode.speed_multiplier = 1.5
	mode.coin_multiplier = 1.0
	mode.enemy_spawn_multiplier = 1.2

	return mode

static func create_coin_rush_challenge() -> ChallengeMode:
	var mode = ChallengeMode.new()
	mode.mode_name = "Coin Rush"
	mode.mode_description = "Coins everywhere! Collect as many as you can!"
	mode.challenge_type = ChallengeType.COIN_RUSH

	mode.max_lives = 5
	mode.has_time_limit = false
	mode.starting_difficulty = 1.0
	mode.difficulty_scaling_enabled = true
	mode.allow_combat = false  # Focus on collecting

	mode.score_multiplier = 0.5  # Less score from distance
	mode.speed_multiplier = 1.0
	mode.coin_multiplier = 3.0  # Triple coins
	mode.enemy_spawn_multiplier = 0.5

	return mode

static func create_combat_master_challenge() -> ChallengeMode:
	var mode = ChallengeMode.new()
	mode.mode_name = "Combat Master"
	mode.mode_description = "Endless combat encounters. Prove your battle prowess!"
	mode.challenge_type = ChallengeType.COMBAT_MASTER

	mode.max_lives = 5
	mode.has_time_limit = false
	mode.starting_difficulty = 1.5
	mode.difficulty_scaling_enabled = true
	mode.allow_combat = true

	mode.score_multiplier = 1.0
	mode.speed_multiplier = 0.8  # Slower to focus on combat
	mode.coin_multiplier = 1.0
	mode.enemy_spawn_multiplier = 2.5  # Lots of enemies

	return mode

static func create_perfectionist_challenge() -> ChallengeMode:
	var mode = ChallengeMode.new()
	mode.mode_name = "Perfectionist"
	mode.mode_description = "Perfect dodges only. One mistake ends it all."
	mode.challenge_type = ChallengeType.PERFECTIONIST

	mode.max_lives = 1
	mode.has_time_limit = false
	mode.starting_difficulty = 1.0
	mode.difficulty_scaling_enabled = true
	mode.allow_combat = true

	mode.score_multiplier = 3.0  # Triple points for perfect play
	mode.speed_multiplier = 1.0
	mode.coin_multiplier = 1.0
	mode.enemy_spawn_multiplier = 1.0

	return mode

## Milestones for achievements
const MILESTONES = {
	"distance_100": {"value": 100.0, "type": "distance", "name": "First Steps"},
	"distance_500": {"value": 500.0, "type": "distance", "name": "Getting Started"},
	"distance_1000": {"value": 1000.0, "type": "distance", "name": "Veteran Runner"},
	"distance_2500": {"value": 2500.0, "type": "distance", "name": "Marathon Master"},
	"distance_5000": {"value": 5000.0, "type": "distance", "name": "Legendary"},
	"score_1000": {"value": 1000.0, "type": "score", "name": "Rookie Scorer"},
	"score_5000": {"value": 5000.0, "type": "score", "name": "Point Collector"},
	"score_10000": {"value": 10000.0, "type": "score", "name": "Score Champion"},
	"score_25000": {"value": 25000.0, "type": "score", "name": "Elite Scorer"},
	"coins_100": {"value": 100.0, "type": "coins", "name": "Treasure Hunter"},
	"coins_500": {"value": 500.0, "type": "coins", "name": "Gold Collector"},
	"survival_60": {"value": 60.0, "type": "time", "name": "One Minute"},
	"survival_300": {"value": 300.0, "type": "time", "name": "Five Minutes"},
	"survival_600": {"value": 600.0, "type": "time", "name": "Ten Minutes"},
	"enemies_10": {"value": 10.0, "type": "enemies", "name": "Warrior"},
	"enemies_50": {"value": 50.0, "type": "enemies", "name": "Slayer"},
}

func start_mode() -> void:
	super.start_mode()
	milestones_reached.clear()
	# Challenge mode never "completes" - it only fails
	# But we track milestones for achievements

func update_mode(delta: float, game_state: Dictionary) -> void:
	super.update_mode(delta, game_state)

	# Check milestones
	check_milestones(game_state)

func check_milestones(game_state: Dictionary) -> void:
	"""Check if any new milestones have been reached"""
	for milestone_id in MILESTONES:
		if milestone_id in milestones_reached:
			continue

		var milestone = MILESTONES[milestone_id]
		var current_value = 0.0

		match milestone["type"]:
			"distance":
				current_value = game_state.get("distance", 0.0)
			"score":
				current_value = game_state.get("score", 0.0)
			"coins":
				current_value = game_state.get("coins", 0.0)
			"time":
				current_value = elapsed_time
			"enemies":
				current_value = game_state.get("enemies_defeated", 0.0)

		if current_value >= milestone["value"]:
			milestones_reached.append(milestone_id)
			# Could emit signal for achievement notification
			print("Milestone reached: ", milestone["name"])

func fail_mode(reason: String) -> void:
	"""Challenge mode ends when player dies"""
	is_active = false
	is_failed = true

	# Get final stats for display
	var final_results = {
		"mode_name": mode_name,
		"challenge_type": ChallengeType.keys()[challenge_type],
		"reason": reason,
		"milestones": milestones_reached,
		"time_survived": elapsed_time,
		"success": false
	}

	# Update personal bests (would be saved to file in real implementation)
	mode_failed.emit(reason)

func on_player_death() -> void:
	"""In challenge mode, death always ends the run"""
	if max_lives == -1:
		return

	current_lives -= 1
	if current_lives <= 0:
		fail_mode("Runner defeated")
	# Note: Some challenge modes might have revival mechanics

func get_mode_config() -> Dictionary:
	var config = super.get_mode_config()
	config["is_challenge_mode"] = true
	config["challenge_type"] = challenge_type
	config["score_multiplier"] = score_multiplier
	config["speed_multiplier"] = speed_multiplier
	config["coin_multiplier"] = coin_multiplier
	config["enemy_spawn_multiplier"] = enemy_spawn_multiplier
	config["difficulty_scaling"] = true  # Always scale in challenge mode
	return config

func get_ui_data() -> Dictionary:
	var data = super.get_ui_data()
	data["challenge_type"] = ChallengeType.keys()[challenge_type]
	data["milestones_reached"] = milestones_reached.size()
	data["score_multiplier"] = score_multiplier
	data["is_infinite"] = true
	return data

func save_high_scores(distance: float, score: int, survival_time: float) -> void:
	"""Update high scores if new records were set"""
	var new_records = []

	if distance > high_distance:
		high_distance = distance
		new_records.append("distance")

	if score > high_score:
		high_score = score
		new_records.append("score")

	if survival_time > longest_survival_time:
		longest_survival_time = survival_time
		new_records.append("time")

	# Would save to file here
	if new_records.size() > 0:
		print("New records set: ", new_records)
