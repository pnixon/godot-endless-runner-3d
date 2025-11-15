# Endless Runner - Configuration System Guide

## Overview

This endless runner has been fully abstracted into a highly configurable system that supports multiple camera perspectives, character play styles, and gameplay modes. All core mechanics are data-driven through configuration Resources.

## Architecture

### Core Systems

1. **ConfigurableGameManager** - Main game orchestrator
2. **ConfigurablePlayer** - Player controller with data-driven stats
3. **CameraController** - Multi-perspective camera system
4. **ViewAdapter** - View-specific logic adapter

### Configuration Resources

1. **GameConfig** - Global game settings
2. **CharacterConfig** - Character stats and abilities
3. **SpawnConfig** - Obstacle and collectible spawning
4. **CameraController.ViewMode** - Camera perspective settings

---

## Camera View Modes

The game supports 5 different camera perspectives:

### 1. First Person (FPS Mode)
- Camera attached to player's head
- Limited visibility, requires quick reactions
- Best for immersive gameplay
- Slightly easier difficulty due to limited view

```gdscript
camera_controller.set_view_mode(CameraController.ViewMode.FIRST_PERSON)
```

### 2. Third Person (Default)
- Classic over-the-shoulder chase camera
- Balanced view of obstacles and environment
- Standard difficulty
- Best for traditional endless runner feel

```gdscript
camera_controller.set_view_mode(CameraController.ViewMode.THIRD_PERSON)
```

### 3. Top Down (Strategy View)
- Overhead isometric view
- Full visibility of the playfield
- Slightly harder due to better vision
- Great for strategic gameplay

```gdscript
camera_controller.set_view_mode(CameraController.ViewMode.TOP_DOWN)
```

### 4. Side View (2.5D Platform)
- 2.5D side-scrolling perspective
- Vertical lane movement
- Classic platformer feel
- Works great for precise timing challenges

```gdscript
camera_controller.set_view_mode(CameraController.ViewMode.SIDE_VIEW)
```

### 5. Fixed Angle (Arcade Style)
- Fixed camera position and angle
- Classic arcade game feel
- Customizable position and rotation

```gdscript
camera_controller.set_view_mode(CameraController.ViewMode.FIXED_ANGLE)
```

**Cycle through views in debug mode:** Press **V** during gameplay

---

## Character Presets

### 1. Balanced Runner (Default)
- **Health:** 100
- **Speed:** 1.0x
- **Best for:** General gameplay

```gdscript
CharacterConfig.create_balanced()
```

### 2. Tank
- **Health:** 200
- **Damage Resistance:** 0.5x (takes half damage)
- **Speed:** 0.75x
- **Best for:** Survival modes, beginners

```gdscript
CharacterConfig.create_tank()
```

### 3. Speedster
- **Health:** 75
- **Speed:** 1.5x
- **Lane Switch Speed:** 40.0
- **Can Air Dash:** Yes
- **Best for:** Skilled players, high scores

```gdscript
CharacterConfig.create_speedster()
```

### 4. Acrobat
- **Health:** 100
- **Jump Power:** 1.3x
- **Can Double Jump:** Yes
- **Can Air Dash:** Yes
- **Best for:** Platforming enthusiasts

```gdscript
CharacterConfig.create_acrobat()
```

### 5. Berserker
- **Health:** 150
- **Can Break Obstacles:** Yes
- **Damage Taken:** 1.3x (more damage)
- **Score Multiplier:** 1.25x
- **Best for:** Aggressive playstyle

```gdscript
CharacterConfig.create_berserker()
```

### 6. Collector
- **Magnet Range:** 2.0x
- **Coin Multiplier:** 2.0x
- **Score Multiplier:** 1.5x
- **Best for:** Maximizing coin collection

```gdscript
CharacterConfig.create_collector()
```

### 7. Survivor
- **Health Regen:** 2 HP/sec
- **Has Second Chance:** Yes (revive once)
- **Shield Duration:** 1.5x
- **Best for:** Long survival runs

```gdscript
CharacterConfig.create_survivor()
```

### 8. Glass Cannon
- **Health:** 50
- **Damage Taken:** 1.5x
- **Score Multiplier:** 3.0x
- **Coin Multiplier:** 2.5x
- **Best for:** Risk/reward gameplay, leaderboards

```gdscript
CharacterConfig.create_glass_cannon()
```

---

## Game Configuration Presets

### Easy Mode
```gdscript
var config = GameConfig.create_easy_preset()
# - Slower difficulty increase
# - Longer spawn intervals
# - More power-ups (25% chance)
```

### Normal Mode
```gdscript
var config = GameConfig.create_normal_preset()
# - Balanced settings
# - Standard difficulty progression
```

### Hard Mode
```gdscript
var config = GameConfig.create_hard_preset()
# - Faster difficulty ramp-up
# - Shorter spawn intervals
# - Fewer power-ups (10% chance)
```

### Endless Mode
```gdscript
var config = GameConfig.create_endless_preset()
# - No maximum difficulty
# - Continuous scaling
```

---

## Spawn Configuration Presets

### Easy Spawning
```gdscript
var config = SpawnConfig.create_easy_preset()
# - More coins, fewer obstacles
# - No triple obstacle patterns
# - 80% collectible spawn rate
```

### Coin Collector Mode
```gdscript
var config = SpawnConfig.create_coin_collector_preset()
# - 10x coin spawn weight
# - 8-10 coins per pattern
# - Frequent bonus sections
```

### Survival Mode
```gdscript
var config = SpawnConfig.create_survival_preset()
# - Intense obstacle patterns
# - Wave patterns enabled
# - Challenge sections (15% chance)
```

### Platformer Style
```gdscript
var config = SpawnConfig.create_platformer_preset()
# - Emphasis on ground hazards
# - Minimal walls
# - Vertical challenge patterns
```

### Obstacle Course
```gdscript
var config = SpawnConfig.create_obstacle_course_preset()
# - Complex multi-obstacle patterns
# - No single obstacles
# - Up to 7 obstacles per pattern
```

---

## Using Configurations in Code

### Basic Setup

```gdscript
# Create a configurable game
var game = ConfigurableGameManager.new()

# Set configurations
game.game_config = GameConfig.create_normal_preset()
game.character_config = CharacterConfig.create_speedster()
game.spawn_config = SpawnConfig.create_coin_collector_preset()

# Set camera mode
game.camera_controller.set_view_mode(CameraController.ViewMode.THIRD_PERSON)

# Start the game
game.start_game()
```

### Applying Presets at Runtime

```gdscript
# Change difficulty preset
game_manager.apply_preset("hard")

# Change character
game_manager.set_character_preset("tank")

# Change camera mode
game_manager.set_camera_mode(CameraController.ViewMode.TOP_DOWN)
```

### Creating Custom Configurations

```gdscript
# Custom character
var my_character = CharacterConfig.new()
my_character.character_name = "Custom Hero"
my_character.max_health = 150.0
my_character.speed_multiplier = 1.2
my_character.can_double_jump = true
my_character.score_multiplier = 2.0

# Custom game settings
var my_game = GameConfig.new()
my_game.initial_difficulty = 2.0
my_game.difficulty_increase_interval = 5.0
my_game.powerup_spawn_chance = 0.5

# Custom spawn patterns
var my_spawns = SpawnConfig.new()
my_spawns.coin_weight = 10.0
my_spawns.enable_waves = true
my_spawns.bonus_section_chance = 0.2
```

---

## ViewAdapter Features

The ViewAdapter automatically adjusts gameplay based on camera mode:

### Spawn Distance Adaptation
- **First Person:** 30 units (closer)
- **Third Person:** 40 units (standard)
- **Top Down:** 35 units
- **Side View:** 45 units (further for anticipation)

### Movement Interpretation
- **First/Third Person:** Standard lane controls
- **Top Down:** Free grid movement
- **Side View:** Vertical lane movement (2D)

### Difficulty Adjustments
- **First Person:** 0.85x (easier due to limited view)
- **Third Person:** 1.0x (baseline)
- **Top Down:** 1.15x (harder with full visibility)
- **Side View:** 1.0x

---

## Character Stat Breakdown

### Health & Survival
- `max_health` - Maximum HP (default: 100)
- `starting_health` - Starting HP (-1 = max)
- `health_regen` - HP per second (0 = none)
- `damage_resistance` - Damage multiplier (0.5 = half, 2.0 = double)
- `has_second_chance` - Revive once at 50% HP

### Movement
- `speed_multiplier` - Overall speed (0.5 = slow, 2.0 = fast)
- `lane_switch_speed` - Lane change rate (default: 25)
- `jump_power` - Jump height multiplier
- `slide_duration` - Slide length multiplier
- `can_double_jump` - Enable double jump
- `can_air_dash` - Enable mid-air dash

### Stamina
- `use_stamina` - Enable stamina system
- `max_stamina` - Maximum stamina (default: 100)
- `stamina_regen_rate` - Stamina per second (default: 30)
- `jump_stamina_cost` - Cost to jump (default: 20)
- `slide_stamina_cost` - Cost to slide (default: 15)

### Abilities
- `can_break_obstacles` - Destroy obstacles on contact
- `magnet_range` - Auto-collect radius multiplier
- `shield_duration_multiplier` - Shield power-up length
- `score_multiplier` - Passive score bonus
- `coin_multiplier` - Coin value bonus

---

## Complete Example: Custom Game Mode

```gdscript
extends Node3D

func _ready():
	# Create "Speed Run" mode
	var game = ConfigurableGameManager.new()
	add_child(game)

	# Fast-paced settings
	var config = GameConfig.new()
	config.initial_difficulty = 2.0
	config.difficulty_increase_interval = 8.0
	config.movement_speed_multiplier = 1.5
	game.game_config = config

	# Use Speedster character
	game.character_config = CharacterConfig.create_speedster()

	# Coin-heavy spawning
	game.spawn_config = SpawnConfig.create_coin_collector_preset()

	# Use third-person view
	game.camera_controller.set_view_mode(CameraController.ViewMode.THIRD_PERSON)

	# Start!
	game.start_game()
```

---

## Debug Controls

When running in debug mode (editor):

- **V** - Cycle through camera views
- **1-8** - Quick-test enemy encounters
- **H** - Debug health bar
- **T** - Test damage
- **Y** - Test heal
- **M** - Toggle music
- **+/-** - Adjust music volume
- **N** - Next music track

---

## Tips for Game Design

### Combining Configurations

**Survival Challenge:**
```gdscript
game_config = GameConfig.create_hard_preset()
character_config = CharacterConfig.create_tank()
spawn_config = SpawnConfig.create_survival_preset()
camera = ViewMode.THIRD_PERSON
```

**Coin Rush:**
```gdscript
game_config = GameConfig.create_easy_preset()
character_config = CharacterConfig.create_collector()
spawn_config = SpawnConfig.create_coin_collector_preset()
camera = ViewMode.TOP_DOWN
```

**Platformer Mode:**
```gdscript
game_config = GameConfig.create_normal_preset()
character_config = CharacterConfig.create_acrobat()
spawn_config = SpawnConfig.create_platformer_preset()
camera = ViewMode.SIDE_VIEW
```

**FPS Intensity:**
```gdscript
game_config = GameConfig.create_hard_preset()
character_config = CharacterConfig.create_speedster()
spawn_config = SpawnConfig.create_obstacle_course_preset()
camera = ViewMode.FIRST_PERSON
```

---

## File Structure

```
scripts/
├── config/
│   ├── GameConfig.gd          # Global game settings
│   ├── CharacterConfig.gd     # Character stats/abilities
│   └── SpawnConfig.gd         # Spawn pattern config
├── camera/
│   ├── CameraController.gd    # Multi-view camera system
│   └── ViewAdapter.gd         # View-specific logic
├── player/
│   └── ConfigurablePlayer.gd  # Data-driven player
├── ConfigurableGameManager.gd # Main orchestrator
└── [other systems...]
```

---

## Next Steps

1. **Create Custom Characters** - Define unique stat combinations
2. **Design Game Modes** - Combine configs for specific experiences
3. **Experiment with Views** - Test which perspective fits your vision
4. **Balance Difficulty** - Tune spawn rates and progression curves
5. **Add Content** - Create new obstacle types and collectibles

---

## API Quick Reference

### ConfigurableGameManager
```gdscript
start_game()                           # Start new game
apply_preset(preset_name: String)      # Apply difficulty preset
set_character_preset(name: String)     # Change character
set_camera_mode(mode: ViewMode)        # Change camera view
get_score() -> int                     # Current score
get_current_difficulty() -> float      # Current difficulty level
```

### ConfigurablePlayer
```gdscript
reset_to_spawn_position()              # Reset player
take_damage(amount: float)             # Deal damage
heal(amount: float)                    # Restore health
activate_power_up(type, duration)      # Activate power-up
get_score_multiplier() -> float        # Get score bonus
can_break_obstacles() -> bool          # Check berserker mode
```

### CameraController
```gdscript
set_view_mode(mode: ViewMode)          # Change perspective
cycle_view_mode()                      # Next view
trigger_shake(intensity, duration)     # Camera shake effect
set_target(node: Node3D)               # Set follow target
configure_for_gameplay_style(style)    # Quick setup
```

### ViewAdapter
```gdscript
get_spawn_distance() -> float          # View-adjusted spawn
get_spawn_position(lane, row)          # World spawn pos
get_difficulty_multiplier() -> float   # View difficulty
supports_free_movement() -> bool       # Check movement type
```

---

## Troubleshooting

**Camera not following player:**
```gdscript
camera_controller.set_target(player)
```

**Spawns not appearing:**
```gdscript
# Ensure ViewAdapter has camera reference
view_adapter.set_camera_controller(camera_controller)
```

**Character stats not applying:**
```gdscript
# Set config before calling _ready()
player.character_config = my_config
```

---

**Happy configuring!** 🎮
