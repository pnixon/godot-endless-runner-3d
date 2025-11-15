# Game Mode System

This document describes the new game mode system that allows players to experience different ways to play the endless runner.

## Overview

The game mode system provides three main types of gameplay:

1. **Story Mode** - Level-based progression with narrative and specific objectives
2. **Challenge Mode** - Infinite endless runner with high score tracking and variants
3. **Timed Mode** - Race against the clock to achieve objectives

## Architecture

### Core Components

#### 1. BaseGameMode (`scripts/game_modes/BaseGameMode.gd`)

The abstract base class for all game modes. Provides:
- Objective system with progress tracking
- Win/lose condition management
- Lives and time limit support
- Signal-based event system
- Mode lifecycle methods

**Key Methods:**
- `start_mode()` - Initialize the mode
- `update_mode(delta, game_state)` - Update every frame
- `complete_mode()` - Called when objectives are met
- `fail_mode(reason)` - Called when failure conditions are met
- `on_player_death()` - Handle player death

**Objective Types:**
- `DISTANCE` - Reach a certain distance
- `SCORE` - Reach a score target
- `TIME_SURVIVE` - Survive for X seconds
- `COLLECT_COINS` - Collect X coins
- `DEFEAT_ENEMIES` - Defeat X enemies
- `PERFECT_DODGES` - Perform X perfect dodges
- `NO_DAMAGE` - Complete without taking damage
- `COMBO` - Achieve X combo streak

#### 2. GameModeManager (`scripts/game_modes/GameModeManager.gd`)

Singleton autoload that manages:
- Mode selection and activation
- Save/load progress
- High score tracking
- Mode unlocking system

**Key Methods:**
- `start_story_level(level_id)` - Start a story level
- `start_challenge(challenge_id)` - Start a challenge mode
- `start_timed_challenge(challenge_id)` - Start a timed challenge
- `update_current_mode(delta, game_state)` - Update active mode
- `is_mode_unlocked(mode_id)` - Check if mode is unlocked
- `save_progress()` / `load_progress()` - Persistence

#### 3. UI Components

- **ModeSelectionUI** (`scripts/ui/ModeSelectionUI.gd`) - Mode selection menu
- **ModeObjectivesUI** (`scripts/ui/ModeObjectivesUI.gd`) - In-game objectives display

## Game Modes

### Story Mode

Level-based gameplay with narrative elements and specific objectives.

#### Features:
- 3-star rating system (based on bonus objectives)
- Linear progression (unlock next level on completion)
- Biome-specific levels
- Story intro/outro text
- Lives system

#### Preset Levels:

**Tutorial: First Steps**
- Primary: Reach 500 distance, collect 50 coins
- Bonus: 5 perfect dodges, no damage
- Unlocks: City Chase

**Chapter 1: City Chase**
- Primary: Reach 1200 distance, defeat 3 city guards
- Bonus: Collect 150 coins, 10x combo, 5000 points
- Unlocks: Industrial Wasteland

**Chapter 2: Industrial Wasteland**
- Primary: Reach 2000 distance, defeat 5 enemies, survive 3 minutes
- Bonus: 15 perfect dodges, 250 coins, 10000 points
- Final level

**Speed Trial: Against the Clock**
- Primary: Reach 1000 distance in 2 minutes
- Bonus: 100 coins, 10 perfect dodges, no damage
- One life only

**Survival: Last Stand**
- Primary: Survive 3 minutes, defeat 10 enemies
- Bonus: 1500 distance, no damage, 15x combo
- High difficulty

#### Creating Custom Story Levels:

```gdscript
var custom_level = StoryMode.new()
custom_level.mode_name = "My Custom Level"
custom_level.level_id = "custom_level_1"
custom_level.mode_description = "A challenging custom level"

# Add objectives
custom_level.add_objective(
    BaseGameMode.ObjectiveType.DISTANCE,
    1000.0,
    "Reach 1000 distance",
    true  # Primary objective
)

custom_level.add_objective(
    BaseGameMode.ObjectiveType.COLLECT_COINS,
    100.0,
    "Collect 100 coins",
    false  # Bonus objective
)

# Configure settings
custom_level.max_lives = 3
custom_level.starting_difficulty = 2.0
custom_level.unlocks_next_level = true
custom_level.next_level_id = "next_level"

# Start the level
GameModeManager.start_mode(custom_level)
```

### Challenge Mode

Infinite endless runner with variants and high score tracking.

#### Features:
- No win condition (play until death)
- Progressive difficulty scaling
- Milestone system for achievements
- High score tracking
- Multiple challenge variants

#### Challenge Variants:

**Classic Endless**
- Standard endless runner
- 3 lives
- 1x score multiplier
- Balanced gameplay

**Hardcore Mode**
- 1 life only
- Higher starting difficulty
- 2x score multiplier
- 1.5x enemy spawns

**Speed Demon**
- 1.5x game speed
- 1.5x score multiplier
- Fast-paced action

**Coin Rush**
- 3x coin spawns
- Focus on collection
- 5 lives
- Reduced enemy spawns

**Combat Master**
- 2.5x enemy spawns
- 0.8x game speed
- Combat-focused
- 5 lives

**Perfectionist**
- 1 life
- 3x score multiplier
- Perfect play only

#### Milestones:

Challenge modes track milestones like:
- Distance: 100, 500, 1000, 2500, 5000
- Score: 1000, 5000, 10000, 25000
- Coins: 100, 500
- Survival time: 1min, 5min, 10min
- Enemies: 10, 50

#### Creating Custom Challenges:

```gdscript
var custom_challenge = ChallengeMode.new()
custom_challenge.mode_name = "My Challenge"
custom_challenge.challenge_type = ChallengeMode.ChallengeType.CLASSIC
custom_challenge.score_multiplier = 1.5
custom_challenge.speed_multiplier = 1.2
custom_challenge.max_lives = 5

GameModeManager.start_mode(custom_challenge)
```

### Timed Mode

Race against the clock with specific objectives.

#### Features:
- Time limits
- Time bonus scoring
- Tiered objectives (Bronze/Silver/Gold)
- Rank system (S/A/B/C)
- Multiple challenge types

#### Timed Variants:

**Score Attack**
- Reach target score before time runs out
- 3 lives
- Bonus: High combo, perfect dodges

**Distance Race**
- Reach checkpoint as fast as possible
- Time bonus for finishing early
- Fixed difficulty

**Coin Frenzy**
- Collect as many coins as possible
- 5 lives
- Tiered objectives (50/100/200 coins)

**Enemy Rush**
- Defeat as many enemies as possible
- High difficulty
- Tiered objectives (5/10/20 enemies)

**Survival Trial**
- Just survive the time limit
- 1 life
- Very high difficulty
- Bonus: Distance, no damage

**Combo Challenge**
- Build highest combo streak
- Maintain perfect play

#### Preset Challenges:

```gdscript
# Quick challenges (60-90 seconds)
TimedMode.create_quick_sprint()      # 500 distance in 60s
TimedMode.create_treasure_hunt()     # 90s coin collection

# Medium challenges (2 minutes)
TimedMode.create_medium_marathon()   # 1200 distance in 120s
TimedMode.create_battle_royale()     # 2min enemy gauntlet

# Hard challenges (3 minutes)
TimedMode.create_hard_gauntlet()     # 3min survival at difficulty 3.0
```

#### Creating Custom Timed Challenges:

```gdscript
var timed_mode = TimedMode.create_score_attack(
    5000,    # Target score
    120.0,   # Time limit (seconds)
    2.0      # Difficulty
)

# Or create from scratch
var custom_timed = TimedMode.new()
custom_timed.mode_name = "Speed Run"
custom_timed.timed_type = TimedMode.TimedType.DISTANCE_RACE
custom_timed.has_time_limit = true
custom_timed.time_limit = 90.0

custom_timed.add_objective(
    BaseGameMode.ObjectiveType.DISTANCE,
    800.0,
    "Reach 800 distance",
    true
)

GameModeManager.start_mode(custom_timed)
```

## Integration with GameManager3D

### GameManagerModeIntegration

The `GameManagerModeIntegration.gd` script bridges the game mode system with the existing GameManager3D.

#### Setup:

1. Add as child of GameManager3D node or as autoload:
   ```
   GameManager3D
   └── GameManagerModeIntegration
   ```

2. The integration automatically:
   - Creates mode objectives UI
   - Updates mode with game state
   - Applies mode configuration
   - Handles mode events

#### Game State Tracking:

The integration extracts this state from GameManager3D:
- `distance` - Distance traveled
- `score` - Current score
- `coins` - Coins collected
- `enemies_defeated` - Enemies defeated (needs tracking)
- `perfect_dodges` - Perfect dodge count
- `max_combo` - Maximum combo achieved

### Starting Modes from GameManager

```gdscript
# In GameManager3D or main menu

# Start story level
var integration = $GameManagerModeIntegration
integration.start_story_level("tutorial")

# Start challenge
integration.start_challenge("classic")

# Start timed challenge
integration.start_timed_challenge("quick_sprint")

# Or use GameModeManager directly
GameModeManager.start_story_level("city_chase")
```

### Handling Player Death

```gdscript
# In player death handler
func _on_player_died():
    if GameModeManager.is_mode_active():
        GameModeManager.on_player_death()
```

## UI System

### Mode Selection UI

Shows available modes grouped by type (Story/Challenge/Timed).

Features:
- Tab-based navigation
- Shows locked/unlocked modes
- Displays progress (stars, high scores, ranks)
- Mode descriptions on hover

### Mode Objectives UI

In-game display of current objectives and progress.

Shows:
- Mode name
- Time remaining/elapsed
- Lives remaining
- Primary objectives (required)
- Bonus objectives (optional)
- Real-time progress bars

## Save System

Progress is automatically saved to `user://game_mode_progress.save`.

### Saved Data:
- Story level completion (stars, best time)
- Challenge mode records (high score, distance, time)
- Timed challenge records (rank, best time)
- Unlocked modes
- Total statistics

### Manual Save/Load:

```gdscript
# Save manually
GameModeManager.save_progress()

# Load manually
GameModeManager.load_progress()

# Reset all progress
GameModeManager.reset_progress()
```

### Querying Progress:

```gdscript
# Check if mode is unlocked
if GameModeManager.is_mode_unlocked("city_chase"):
    # Allow access

# Get story progress
var progress = GameModeManager.get_story_progress("tutorial")
print("Stars: ", progress.get("stars", 0))
print("Best time: ", progress.get("best_time", 0))

# Get challenge record
var record = GameModeManager.get_challenge_record("hardcore")
print("High score: ", record.get("high_score", 0))

# Get total stats
var stats = GameModeManager.get_total_stats()
print("Total playtime: ", stats["playtime"])
print("Total stars: ", stats["total_stars"])
```

## Example Usage

### Complete Workflow:

```gdscript
# 1. Player opens mode selection menu
var mode_selection_ui = preload("res://scripts/ui/ModeSelectionUI.gd").new()
mode_selection_ui.mode_selected.connect(_on_mode_selected)
add_child(mode_selection_ui)
mode_selection_ui.show_selection()

# 2. Player selects a mode
func _on_mode_selected(mode: BaseGameMode):
    # Start the mode
    GameModeManager.start_mode(mode)

    # Connect to completion signals
    mode.mode_completed.connect(_on_mode_completed)
    mode.mode_failed.connect(_on_mode_failed)

    # Start game
    start_game()

# 3. Update mode during gameplay
func _process(delta):
    if GameModeManager.is_mode_active():
        var game_state = {
            "distance": distance_traveled,
            "score": score,
            "coins": coins,
            # ... etc
        }
        GameModeManager.update_current_mode(delta, game_state)

# 4. Handle completion
func _on_mode_completed(results: Dictionary):
    print("Completed! Stars: ", results.get("stars_earned", 0))
    show_victory_screen(results)

func _on_mode_failed(reason: String):
    print("Failed: ", reason)
    show_game_over_screen()
```

## Best Practices

1. **Always check if mode is unlocked** before allowing access
2. **Update mode every frame** with current game state
3. **Connect to mode signals** for proper event handling
4. **Save progress** after important events
5. **Use preset modes** as templates for custom modes
6. **Test objectives** to ensure they're achievable
7. **Balance difficulty** for your target audience

## Future Enhancements

Potential additions to the system:
- Daily challenges
- Leaderboards
- Custom mode editor
- Procedurally generated challenges
- Multiplayer modes
- More objective types
- Achievement system integration
- Replay system

## Troubleshooting

### Mode not starting:
- Check if mode is unlocked: `GameModeManager.is_mode_unlocked(mode_id)`
- Verify GameModeManager is in autoload
- Check console for error messages

### Objectives not updating:
- Ensure `update_current_mode()` is called every frame
- Verify game state dictionary has correct keys
- Check objective types match game state

### Progress not saving:
- Check file write permissions
- Verify save path is accessible
- Call `save_progress()` manually if needed

### UI not showing:
- Ensure UI scripts are loaded correctly
- Check if UI is added to scene tree
- Verify UI layer/canvas settings

## File Reference

```
scripts/game_modes/
├── BaseGameMode.gd          # Base class for all modes
├── StoryMode.gd             # Story mode implementation
├── ChallengeMode.gd         # Challenge mode implementation
├── TimedMode.gd             # Timed mode implementation
└── GameModeManager.gd       # Singleton manager (autoload)

scripts/ui/
├── ModeSelectionUI.gd       # Mode selection menu
└── ModeObjectivesUI.gd      # In-game objectives display

scripts/
└── GameManagerModeIntegration.gd  # Integration with GameManager3D

docs/
└── GAME_MODES.md            # This file
```

## License

Part of the Godot Endless Runner 3D project.
