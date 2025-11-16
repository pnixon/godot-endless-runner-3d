# Tutorial: Building a Game with Modular Components

This tutorial demonstrates how to use the modular components in this endless runner framework to build your own game. You'll learn how to combine menus, levels, enemies, and game modes into a cohesive experience.

## Table of Contents
1. [Architecture Overview](#architecture-overview)
2. [Quick Start: Your First Level](#quick-start-your-first-level)
3. [Adding Enemies](#adding-enemies)
4. [Creating Custom Game Modes](#creating-custom-game-modes)
5. [Menu Integration](#menu-integration)
6. [Advanced: Combat Integration](#advanced-combat-integration)

---

## Architecture Overview

### Core Modular Components

The framework is built around these reusable systems:

**1. Enemy System** (`scripts/EnemyAI.gd`)
- Base class for all enemy behavior
- Includes: health, detection, attack patterns, state machine
- Extend and override methods to create custom enemies

**2. Game Mode System** (`scripts/game_modes/`)
- `BaseGameMode.gd` - Resource-based mode definition
- `StoryMode`, `ChallengeMode`, `TimedMode` - Pre-built variants
- `GameModeManager.gd` - Singleton for mode progression/saves

**3. Combat System** (`scripts/combat/`)
- `DaiCombatController.gd` - Auto-attack + skill system
- `CombatGrid.gd` - 2D grid positioning for tactics
- `EnemyAttackSystem.gd` - Telegraphed attack patterns

**4. RPG Progression** (`scripts/rpg/`)
- `PlayerData`, `LevelUpSystem`, `EquipmentManager`, `AbilitySystem`
- Modular subsystems you can mix and match

**5. Configuration** (`scripts/config/`)
- `GameConfig.gd` - Difficulty settings
- `SpawnConfig.gd` - Enemy spawn rules
- `CharacterConfig.gd` - Character templates

---

## Quick Start: Your First Level

### Step 1: Create a Basic Runner Level

```gdscript
# scripts/tutorial/MyFirstLevel.gd
extends Node3D

# Required nodes (add as children in scene)
@onready var player = $Player3D
@onready var camera = $CameraController
@onready var ground = $Ground

var scroll_speed = 5.0
var distance_traveled = 0.0

func _ready():
    # Initialize player
    if player:
        player.position = Vector3(0, 1, 0)

    # Connect player signals
    player.player_died.connect(_on_player_died)
    player.coin_collected.connect(_on_coin_collected)

    print("Level started!")

func _process(delta):
    # Move ground/obstacles toward player (endless runner effect)
    distance_traveled += scroll_speed * delta

    # Update difficulty based on distance
    if distance_traveled > 100:
        scroll_speed = 7.0

func _on_player_died():
    print("Game Over! Distance: ", distance_traveled)
    # Show game over screen or restart

func _on_coin_collected(amount):
    print("Collected ", amount, " coins")
```

### Step 2: Scene Structure

Create a scene `MyFirstLevel.tscn` with this hierarchy:

```
MyFirstLevel (Node3D)
├── Player3D (instance of scenes/Player3D.tscn)
├── CameraController (instance or custom)
├── Ground (MeshInstance3D with CollisionShape3D)
├── DirectionalLight3D
└── Environment (WorldEnvironment)
```

**Important**: Set the script to `MyFirstLevel.gd` on the root node.

---

## Adding Enemies

### Option A: Use Pre-Built Enemy Types

The framework includes 6 enemy types ready to use:

```gdscript
# In your level script
const BasicMeleeEnemy = preload("res://scripts/enemies/BasicMeleeEnemy.gd")
const RangedArcherEnemy = preload("res://scripts/enemies/RangedArcherEnemy.gd")
const BossEnemy = preload("res://scripts/enemies/BossEnemy.gd")

func spawn_enemy(type: String, position: Vector3):
    var enemy_scene = create_enemy_visual()  # See below
    var enemy

    match type:
        "melee":
            enemy = BasicMeleeEnemy.new()
        "archer":
            enemy = RangedArcherEnemy.new()
        "boss":
            enemy = BossEnemy.new()

    enemy_scene.add_child(enemy)
    enemy.global_position = position
    add_child(enemy_scene)

    # Connect signals
    enemy.enemy_died.connect(_on_enemy_died)

    return enemy

func create_enemy_visual() -> Node3D:
    """Create a simple 3D geometric enemy"""
    var enemy_root = Node3D.new()

    # Body (cube)
    var mesh_instance = MeshInstance3D.new()
    var box = BoxMesh.new()
    box.size = Vector3(1, 2, 1)
    mesh_instance.mesh = box

    # Material (red for enemy)
    var material = StandardMaterial3D.new()
    material.albedo_color = Color(1, 0, 0)
    mesh_instance.set_surface_override_material(0, material)

    # Collision
    var collision = CollisionShape3D.new()
    var shape = BoxShape3D.new()
    shape.size = Vector3(1, 2, 1)
    collision.shape = shape

    enemy_root.add_child(mesh_instance)
    enemy_root.add_child(collision)

    return enemy_root

func _on_enemy_died(enemy):
    print("Enemy defeated!")
    # Award XP, coins, etc.
```

### Option B: Create Custom Enemy

```gdscript
# scripts/tutorial/MyCustomEnemy.gd
extends "res://scripts/EnemyAI.gd"

func _init():
    super._init()

    # Configure stats
    max_health = 50.0
    current_health = max_health
    movement_speed = 3.0
    detection_range = 15.0
    attack_range = 2.0
    attack_damage = 10.0

# Override to customize attack behavior
func choose_attack_pattern():
    if current_health < max_health * 0.3:
        # Desperate mode - attack more frequently
        return "rapid_attack"
    else:
        return "normal_attack"

# Override to customize movement
func execute_pursuing_behavior(delta):
    # Move toward player
    if target_player:
        var direction = (target_player.global_position - global_position).normalized()
        velocity = direction * movement_speed

        # Face the player
        look_at(target_player.global_position, Vector3.UP)

# Override to define custom attacks
func execute_attack():
    print("Custom enemy attacks!")
    if target_player and target_player.has_method("take_damage"):
        target_player.take_damage(attack_damage)
```

---

## Creating Custom Game Modes

### Example: Survival Mode

```gdscript
# scripts/game_modes/SurvivalMode.gd
extends "res://scripts/game_modes/BaseGameMode.gd"

class_name SurvivalMode

func _init():
    mode_name = "Survival Mode"
    description = "Survive as long as possible against endless waves"

    # Configure objectives
    objectives = {
        "survive_time": {"target": 300.0, "current": 0.0},  # 5 minutes
        "enemies_defeated": {"target": 50, "current": 0},
        "perfect_dodges": {"target": 20, "current": 0}
    }

    # Star rating thresholds (seconds survived)
    star_thresholds = {
        1: 60.0,   # 1 star = 1 minute
        2: 180.0,  # 2 stars = 3 minutes
        3: 300.0   # 3 stars = 5 minutes
    }

    lives_type = "limited"
    starting_lives = 3
    time_limit = 0  # No time limit, just survive

# Override to add custom rules
func check_failure_condition(game_state: Dictionary) -> bool:
    # Fail if lives reach 0
    return game_state.get("lives", 3) <= 0

func update_progress(event_type: String, value):
    match event_type:
        "time_survived":
            objectives["survive_time"]["current"] = value
        "enemy_defeated":
            objectives["enemies_defeated"]["current"] += 1
        "perfect_dodge":
            objectives["perfect_dodges"]["current"] += 1

    # Check if objectives met
    emit_signal("objectives_updated", objectives)

# Static factory method for easy creation
static func create_survival_mode() -> SurvivalMode:
    return SurvivalMode.new()
```

### Integrate with GameModeManager

```gdscript
# In your main menu or game setup
func _ready():
    var mode_manager = GameModeManager  # Singleton

    # Register custom mode
    var survival_mode = SurvivalMode.create_survival_mode()
    mode_manager.register_custom_mode(survival_mode)

    # Or start directly
    mode_manager.set_active_mode(survival_mode)
```

---

## Menu Integration

### Create a Simple Main Menu

```gdscript
# scripts/tutorial/SimpleMainMenu.gd
extends Control

@onready var start_button = $VBoxContainer/StartButton
@onready var mode_select_button = $VBoxContainer/ModeSelectButton
@onready var quit_button = $VBoxContainer/QuitButton

func _ready():
    start_button.pressed.connect(_on_start_pressed)
    mode_select_button.pressed.connect(_on_mode_select_pressed)
    quit_button.pressed.connect(_on_quit_pressed)

func _on_start_pressed():
    # Start with default mode
    var mode_manager = GameModeManager
    var classic_mode = load("res://scripts/game_modes/ChallengeMode.gd").create_classic_challenge()
    mode_manager.set_active_mode(classic_mode)

    # Load main game scene
    get_tree().change_scene_to_file("res://scenes/Main3D.tscn")

func _on_mode_select_pressed():
    # Show mode selection UI
    get_tree().change_scene_to_file("res://scenes/ModeSelectionMenu.tscn")

func _on_quit_pressed():
    get_tree().quit()
```

### Use the Built-In Mode Selection UI

```gdscript
# The framework includes ModeSelectionUI.gd
# Just instance it in your menu scene

# In your scene tree:
# MainMenu (Control)
#   └── ModeSelectionUI (instance of ModeSelectionUI.gd)

# The UI automatically:
# - Shows Story/Challenge/Timed tabs
# - Displays locked/unlocked modes
# - Tracks best scores and star ratings
# - Handles mode selection and starting
```

---

## Advanced: Combat Integration

### Example: Arena with Wave-Based Enemies

```gdscript
# scripts/tutorial/ArenaLevel.gd
extends Node3D

const BasicMeleeEnemy = preload("res://scripts/enemies/BasicMeleeEnemy.gd")
const RangedArcherEnemy = preload("res://scripts/enemies/RangedArcherEnemy.gd")
const BossEnemy = preload("res://scripts/enemies/BossEnemy.gd")

@onready var player = $Player3D
@onready var combat_controller = $DaiCombatController
@onready var combat_grid = $CombatGrid

var current_wave = 0
var enemies_in_wave = []

# Wave definitions
var waves = [
    # Wave 1: 3 basic enemies
    [
        {"type": "melee", "position": Vector3(-2, 0, 5)},
        {"type": "melee", "position": Vector3(0, 0, 5)},
        {"type": "melee", "position": Vector3(2, 0, 5)}
    ],
    # Wave 2: Mix of melee and ranged
    [
        {"type": "melee", "position": Vector3(-3, 0, 5)},
        {"type": "archer", "position": Vector3(0, 0, 7)},
        {"type": "melee", "position": Vector3(3, 0, 5)}
    ],
    # Wave 3: Boss fight
    [
        {"type": "boss", "position": Vector3(0, 0, 8)}
    ]
]

func _ready():
    # Initialize combat system
    combat_controller.initialize(player)
    combat_grid.initialize()

    # Connect signals
    player.player_died.connect(_on_player_died)

    # Start first wave
    start_wave(0)

func start_wave(wave_index: int):
    current_wave = wave_index

    if wave_index >= waves.size():
        _on_all_waves_complete()
        return

    print("Starting wave ", wave_index + 1)
    enemies_in_wave.clear()

    # Spawn enemies for this wave
    for enemy_data in waves[wave_index]:
        var enemy = spawn_enemy(enemy_data["type"], enemy_data["position"])
        enemies_in_wave.append(enemy)
        enemy.enemy_died.connect(_on_enemy_died.bind(enemy))

func spawn_enemy(type: String, position: Vector3):
    # Create visual representation
    var enemy_visual = create_enemy_visual(type)
    add_child(enemy_visual)
    enemy_visual.global_position = position

    # Add AI component
    var enemy
    match type:
        "melee":
            enemy = BasicMeleeEnemy.new()
        "archer":
            enemy = RangedArcherEnemy.new()
        "boss":
            enemy = BossEnemy.new()

    enemy_visual.add_child(enemy)
    enemy.target_player = player

    # Register with combat system
    if combat_controller:
        combat_controller.register_enemy(enemy)

    return enemy

func create_enemy_visual(type: String) -> Node3D:
    """Create geometric shapes for enemies"""
    var root = Node3D.new()
    var mesh_instance = MeshInstance3D.new()
    var material = StandardMaterial3D.new()

    match type:
        "melee":
            # Red cube
            var box = BoxMesh.new()
            box.size = Vector3(1, 2, 1)
            mesh_instance.mesh = box
            material.albedo_color = Color(1, 0, 0)

        "archer":
            # Blue cylinder
            var cylinder = CylinderMesh.new()
            cylinder.height = 2.0
            cylinder.top_radius = 0.5
            cylinder.bottom_radius = 0.5
            mesh_instance.mesh = cylinder
            material.albedo_color = Color(0, 0, 1)

        "boss":
            # Large purple sphere
            var sphere = SphereMesh.new()
            sphere.radius = 1.5
            sphere.height = 3.0
            mesh_instance.mesh = sphere
            material.albedo_color = Color(0.5, 0, 0.5)

    mesh_instance.set_surface_override_material(0, material)

    # Add collision
    var collision = CollisionShape3D.new()
    var shape = BoxShape3D.new()
    shape.size = Vector3(1, 2, 1)
    collision.shape = shape

    root.add_child(mesh_instance)
    root.add_child(collision)

    return root

func _on_enemy_died(enemy):
    enemies_in_wave.erase(enemy)

    # Award rewards
    if player.has_method("add_experience"):
        player.add_experience(50)
    if player.has_method("add_currency"):
        player.add_currency(10)

    # Check if wave complete
    if enemies_in_wave.is_empty():
        _on_wave_complete()

func _on_wave_complete():
    print("Wave ", current_wave + 1, " complete!")

    # Heal player between waves
    if player.has_method("heal"):
        player.heal(50)

    # Wait 3 seconds, then start next wave
    await get_tree().create_timer(3.0).timeout
    start_wave(current_wave + 1)

func _on_all_waves_complete():
    print("Victory! All waves defeated!")
    # Show victory screen, return to menu, etc.

func _on_player_died():
    print("Defeat! Try again.")
    # Show game over screen
```

---

## Complete Example: Tutorial Level Scene

Here's how to set up a complete playable level:

### Scene Hierarchy

```
TutorialLevel (Node3D) [script: ArenaLevel.gd]
├── Player3D (instance)
├── CameraController (instance)
├── DaiCombatController (script: DaiCombatController.gd)
├── CombatGrid (script: CombatGrid.gd)
├── Environment
│   ├── Ground (MeshInstance3D - large plane)
│   ├── DirectionalLight3D
│   └── WorldEnvironment
└── UI
    ├── DaiCombatUI (instance)
    └── HUD (Label for wave counter, health, etc.)
```

### Testing Your Level

1. **Open Godot**
2. **Create the scene** following the hierarchy above
3. **Attach the script** `ArenaLevel.gd` to the root node
4. **Configure Player3D** - ensure it has RPG components
5. **Run the scene** (F6)
6. **Test gameplay**:
   - Player should spawn at origin
   - Wave 1 starts with 3 melee enemies
   - Defeat them to progress to wave 2
   - Final wave is a boss fight

---

## Tips for Extending the System

### 1. Add New Enemy Types

Create a new script extending `EnemyAI.gd`:

```gdscript
extends "res://scripts/EnemyAI.gd"

class_name MyCustomEnemy

func choose_attack_pattern():
    # Your custom logic
    pass

func execute_pursuing_behavior(delta):
    # Your custom movement
    pass
```

### 2. Create Custom Abilities

```gdscript
# Create a resource file or code
var fireball = AbilityData.new()
fireball.ability_name = "Fireball"
fireball.description = "Launch a fireball"
fireball.cost_type = AbilityData.CostType.MANA
fireball.cost_amount = 20
fireball.damage = 50
fireball.cooldown = 3.0
fireball.ability_type = AbilityData.AbilityType.OFFENSIVE
```

### 3. Custom Game Modes

Extend `BaseGameMode` and override:
- `check_completion()` - Win condition
- `check_failure_condition()` - Lose condition
- `update_progress()` - Track custom objectives

### 4. Save/Load Integration

```gdscript
# Save player progress
var save_manager = preload("res://scripts/rpg/SaveDataManager.gd").new()
save_manager.save_game(player_data, "slot1")

# Load player progress
var loaded_data = save_manager.load_game("slot1")
```

---

## Next Steps

1. **Explore Example Scenes**:
   - `scenes/CombatLevel.tscn` - Full combat example
   - `scenes/Main3D.tscn` - Runner mode
   - `scenes/DemoLauncher.tscn` - Menu system

2. **Read Component Documentation**:
   - `scripts/EnemyAI.gd` - Enemy behavior
   - `scripts/game_modes/BaseGameMode.gd` - Mode system
   - `scripts/combat/DaiCombatController.gd` - Combat mechanics

3. **Experiment**:
   - Mix and match components
   - Create hybrid runner-combat levels
   - Design custom progression systems

---

## Common Patterns

### Pattern 1: Signal-Driven Architecture

```gdscript
# Components emit signals
enemy.enemy_died.connect(_on_enemy_died)
player.player_died.connect(_on_player_died)
combat_controller.skill_activated.connect(_on_skill_used)

# No tight coupling between systems
```

### Pattern 2: Resource-Based Configuration

```gdscript
# Define game elements as resources
var enemy_config = CharacterConfig.new()
enemy_config.max_health = 100
enemy_config.movement_speed = 5.0

# Load from files
var ability = load("res://resources/abilities/fireball.tres")
```

### Pattern 3: Composition Over Inheritance

```gdscript
# Player is composed of systems, not a monolithic class
var player_data = PlayerData.new()
var equipment_manager = EquipmentManager.new()
var ability_system = AbilitySystem.new()

# Each system is independent and reusable
```

---

## Support

For questions or issues:
- Check `scripts/` for component documentation
- Review `examples/QuickStartGameModes.gd`
- Explore test scenes in `scenes/`

Happy game building!
