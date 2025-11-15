extends BaseGameMode
class_name StoryMode

## Story Mode - Level-based progression with narrative and specific objectives
## Each level has unique objectives, story elements, and unlocks the next level

## Story level configuration
@export var level_id: String = "story_1"
@export var level_number: int = 1
@export_multiline var story_intro: String = ""
@export_multiline var story_outro: String = ""
@export var required_biome: int = 0  # Which biome this level takes place in

## Star rating system (1-3 stars based on secondary objectives)
var stars_earned: int = 0

## Level presets - static methods to create story levels
static func create_tutorial_level() -> StoryMode:
	var level = StoryMode.new()
	level.mode_name = "Tutorial: First Steps"
	level.level_id = "story_tutorial"
	level.level_number = 1
	level.mode_description = "Learn the basics of endless running"
	level.story_intro = "Welcome, runner! The path ahead is dangerous, but with skill and courage, you can master it. Let's start with the basics."
	level.story_outro = "Excellent! You've mastered the fundamentals. But greater challenges await..."

	# Primary objectives
	level.add_objective(ObjectiveType.DISTANCE, 500.0, "Reach 500 distance", true)
	level.add_objective(ObjectiveType.COLLECT_COINS, 50.0, "Collect 50 coins", true)

	# Secondary objectives (for stars)
	level.add_objective(ObjectiveType.PERFECT_DODGES, 5.0, "Perform 5 perfect dodges", false)
	level.add_objective(ObjectiveType.NO_DAMAGE, 1.0, "Complete without taking damage", false)

	level.max_lives = 3
	level.starting_difficulty = 1.0
	level.difficulty_scaling_enabled = false  # Fixed difficulty for tutorial
	level.allow_combat = false  # No combat in tutorial
	level.unlocks_next_level = true
	level.next_level_id = "story_city_chase"
	level.required_biome = 0  # Tutorial Valley

	return level

static func create_city_chase_level() -> StoryMode:
	var level = StoryMode.new()
	level.mode_name = "Chapter 1: City Chase"
	level.level_id = "story_city_chase"
	level.level_number = 2
	level.mode_description = "Escape through the Mystic City"
	level.story_intro = "The city guards are onto you! Run through the bustling streets and evade capture. The streets are treacherous, but freedom awaits those who are swift."
	level.story_outro = "You've escaped the city! But your journey is far from over. The industrial wastelands lie ahead..."

	# Primary objectives
	level.add_objective(ObjectiveType.DISTANCE, 1200.0, "Reach the city outskirts (1200 distance)", true)
	level.add_objective(ObjectiveType.DEFEAT_ENEMIES, 3.0, "Defeat 3 city guards", true)

	# Secondary objectives
	level.add_objective(ObjectiveType.COLLECT_COINS, 150.0, "Collect 150 coins", false)
	level.add_objective(ObjectiveType.COMBO, 10.0, "Achieve a 10x combo", false)
	level.add_objective(ObjectiveType.SCORE, 5000.0, "Score 5000 points", false)

	level.max_lives = 3
	level.starting_difficulty = 1.5
	level.difficulty_scaling_enabled = true
	level.allow_combat = true
	level.unlocks_next_level = true
	level.next_level_id = "story_wasteland"
	level.required_biome = 1  # Mystic City

	return level

static func create_wasteland_level() -> StoryMode:
	var level = StoryMode.new()
	level.mode_name = "Chapter 2: Industrial Wasteland"
	level.level_id = "story_wasteland"
	level.level_number = 3
	level.mode_description = "Survive the mechanical horrors of the wasteland"
	level.story_intro = "The wasteland is a graveyard of rusted machinery and hostile automatons. Only the strongest survive here. Can you make it through?"
	level.story_outro = "Against all odds, you've conquered the wasteland! You are truly a master runner."

	# Primary objectives
	level.add_objective(ObjectiveType.DISTANCE, 2000.0, "Traverse the wasteland (2000 distance)", true)
	level.add_objective(ObjectiveType.DEFEAT_ENEMIES, 5.0, "Defeat 5 mechanical enemies", true)
	level.add_objective(ObjectiveType.TIME_SURVIVE, 180.0, "Survive for 3 minutes", true)

	# Secondary objectives
	level.add_objective(ObjectiveType.PERFECT_DODGES, 15.0, "Perform 15 perfect dodges", false)
	level.add_objective(ObjectiveType.COLLECT_COINS, 250.0, "Collect 250 coins", false)
	level.add_objective(ObjectiveType.SCORE, 10000.0, "Score 10000 points", false)

	level.max_lives = 5  # Harder level, more lives
	level.starting_difficulty = 2.0
	level.difficulty_scaling_enabled = true
	level.allow_combat = true
	level.unlocks_next_level = false  # Final level
	level.required_biome = 2  # Industrial Wasteland

	return level

static func create_speed_trial_level() -> StoryMode:
	var level = StoryMode.new()
	level.mode_name = "Speed Trial: Against the Clock"
	level.level_id = "story_speed_trial"
	level.level_number = 4
	level.mode_description = "Race against time in this high-speed challenge"
	level.story_intro = "Speed is everything! Can you reach the checkpoint before time runs out?"
	level.story_outro = "Incredible speed! You've proven yourself as one of the fastest runners!"

	# Primary objectives
	level.add_objective(ObjectiveType.DISTANCE, 1000.0, "Reach 1000 distance", true)

	# Secondary objectives
	level.add_objective(ObjectiveType.COLLECT_COINS, 100.0, "Collect 100 coins", false)
	level.add_objective(ObjectiveType.PERFECT_DODGES, 10.0, "Perform 10 perfect dodges", false)
	level.add_objective(ObjectiveType.NO_DAMAGE, 1.0, "Complete without damage", false)

	level.max_lives = 1  # One life for speed trial
	level.has_time_limit = true
	level.time_limit = 120.0  # 2 minutes
	level.starting_difficulty = 2.5
	level.difficulty_scaling_enabled = false
	level.allow_combat = false  # Pure running challenge
	level.unlocks_next_level = true
	level.next_level_id = "story_city_chase"

	return level

static func create_survival_level() -> StoryMode:
	var level = StoryMode.new()
	level.mode_name = "Survival: Last Stand"
	level.level_id = "story_survival"
	level.level_number = 5
	level.mode_description = "Survive endless waves of enemies"
	level.story_intro = "They just keep coming! How long can you last?"
	level.story_outro = "You survived! But barely... The enemy forces retreat, for now."

	# Primary objectives
	level.add_objective(ObjectiveType.TIME_SURVIVE, 180.0, "Survive for 3 minutes", true)
	level.add_objective(ObjectiveType.DEFEAT_ENEMIES, 10.0, "Defeat 10 enemies", true)

	# Secondary objectives
	level.add_objective(ObjectiveType.DISTANCE, 1500.0, "Reach 1500 distance", false)
	level.add_objective(ObjectiveType.NO_DAMAGE, 1.0, "Take no damage", false)
	level.add_objective(ObjectiveType.COMBO, 15.0, "Achieve 15x combo", false)

	level.max_lives = 5
	level.starting_difficulty = 3.0
	level.difficulty_scaling_enabled = true
	level.allow_combat = true
	level.unlocks_next_level = false

	return level

## Override lifecycle methods

func start_mode() -> void:
	super.start_mode()
	stars_earned = 0
	# Story modes can trigger intro dialogue/cutscene here

func complete_mode() -> void:
	# Calculate stars based on completed secondary objectives
	stars_earned = 1  # Base star for completion
	var secondary_complete = 0
	for objective in get_secondary_objectives():
		if objective.is_complete:
			secondary_complete += 1

	# Award additional stars (2 stars for 1-2 secondary, 3 stars for all)
	var total_secondary = get_secondary_objectives().size()
	if total_secondary > 0:
		var completion_rate = float(secondary_complete) / float(total_secondary)
		if completion_rate >= 1.0:
			stars_earned = 3
		elif completion_rate >= 0.4:
			stars_earned = 2

	is_active = false
	is_completed = true

	var results = {
		"mode_name": mode_name,
		"level_id": level_id,
		"level_number": level_number,
		"time_elapsed": elapsed_time,
		"lives_remaining": current_lives,
		"stars_earned": stars_earned,
		"objectives": objectives,
		"story_outro": story_outro,
		"unlocks_next": unlocks_next_level,
		"next_level_id": next_level_id,
		"success": true
	}

	mode_completed.emit(results)

func get_mode_config() -> Dictionary:
	var config = super.get_mode_config()
	config["biome"] = required_biome
	config["is_story_mode"] = true
	config["level_id"] = level_id
	return config

func get_ui_data() -> Dictionary:
	var data = super.get_ui_data()
	data["level_number"] = level_number
	data["stars_earned"] = stars_earned
	data["story_intro"] = story_intro
	data["has_time_limit"] = has_time_limit
	data["time_limit"] = time_limit
	return data

## Helper to get story progress description
func get_progress_summary() -> String:
	var completed_primary = 0
	var total_primary = get_primary_objectives().size()

	for obj in get_primary_objectives():
		if obj.is_complete:
			completed_primary += 1

	return "%d/%d objectives complete" % [completed_primary, total_primary]
