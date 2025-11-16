# Quick Start Guide - Modular Game Components

Welcome! This guide will get you started with the modular game framework in **5 minutes**.

## What You'll Build

By following this guide, you'll create:
- ✅ A main menu with multiple options
- ✅ A playable arena level with enemies
- ✅ Wave-based combat system
- ✅ Game modes with objectives

All using pre-built modular components!

---

## Step 1: Try the Tutorial Arena (2 minutes)

The fastest way to see the system in action:

### Option A: Using Godot Editor

1. **Open Godot** and load this project
2. **Create a new scene**:
   - Scene → New Scene
   - Add `Node3D` as root
   - Attach script: `scripts/tutorial/TutorialArenaLevel.gd`
   - Save as `scenes/TutorialArena.tscn`
3. **Run the scene** (Press F6)
4. **Press SPACE** to start Wave 1

You'll see:
- 3D geometric enemies (cubes, cones, spheres)
- Wave-based combat
- UI showing progress
- Modular enemy AI in action

### Option B: From Main Menu

1. **Create main menu scene**:
   - Scene → New Scene
   - Add `Control` as root
   - Attach script: `scripts/tutorial/TutorialMainMenu.gd`
   - Save as `scenes/TutorialMenu.tscn`
2. **Set as main scene**:
   - Project → Project Settings → Application → Run → Main Scene
   - Select `scenes/TutorialMenu.tscn`
3. **Run the project** (Press F5)
4. **Click "Start Tutorial Arena"**

---

## Step 2: Understanding the Components (5 minutes)

### Key Modular Components

**1. Enemy System** (`scripts/enemies/`)
- Pre-built enemy types: Melee, Archer, Heavy, Rogue, Mage, Boss
- Each extends `EnemyAI.gd` base class
- Simple to customize or extend

**Example - Spawn an enemy:**
```gdscript
const BasicMeleeEnemy = preload("res://scripts/enemies/BasicMeleeEnemy.gd")

var enemy_ai = BasicMeleeEnemy.new()
enemy_ai.max_health = 50
enemy_ai.target_player = player
enemy_node.add_child(enemy_ai)
```

**2. Game Mode System** (`scripts/game_modes/`)
- Objective tracking
- Star ratings
- Win/loss conditions
- Progress saving

**Example - Create a custom mode:**
```gdscript
extends "res://scripts/game_modes/BaseGameMode.gd"

func _init():
    mode_name = "My Custom Mode"
    objectives = {
        "score": {"target": 1000, "current": 0}
    }
    lives_type = "limited"
    starting_lives = 3
```

**3. Combat System** (`scripts/combat/`)
- Auto-attack with skill charging
- Boss mechanics (stagger, break mode)
- Grid-based positioning
- Telegraphed attacks

**Example - Initialize combat:**
```gdscript
var combat_controller = DaiCombatController.new()
combat_controller.initialize(player)
combat_controller.register_enemy(enemy)
```

**4. Menu/UI System** (`scripts/ui/`)
- Mode selection UI
- Objectives display
- Combat HUD
- Easy to extend

---

## Step 3: Create Your First Custom Level (10 minutes)

Let's create a simple level from scratch!

### Create the Script

Create `my_first_level.gd`:

```gdscript
extends Node3D

const BasicMeleeEnemy = preload("res://scripts/enemies/BasicMeleeEnemy.gd")

@onready var player = $Player3D
var enemies = []

func _ready():
    print("My First Level Started!")

    # Spawn 3 enemies
    for i in range(3):
        var pos = Vector3(i * 2 - 2, 0, 5)
        spawn_enemy(pos)

func spawn_enemy(position: Vector3):
    # Create visual (red cube)
    var enemy_visual = CharacterBody3D.new()
    var mesh = MeshInstance3D.new()
    var box = BoxMesh.new()
    box.size = Vector3(1, 2, 1)
    mesh.mesh = box

    var material = StandardMaterial3D.new()
    material.albedo_color = Color(1, 0, 0)
    mesh.set_surface_override_material(0, material)

    enemy_visual.add_child(mesh)
    enemy_visual.global_position = position
    add_child(enemy_visual)

    # Add AI
    var enemy_ai = BasicMeleeEnemy.new()
    enemy_ai.target_player = player
    enemy_ai.max_health = 30
    enemy_ai.current_health = 30
    enemy_visual.add_child(enemy_ai)

    # Connect death signal
    enemy_ai.enemy_died.connect(_on_enemy_died.bind(enemy_ai))

    enemies.append(enemy_ai)

func _on_enemy_died(enemy):
    enemies.erase(enemy)
    print("Enemy defeated! %d remaining" % enemies.size())

    if enemies.is_empty():
        print("All enemies defeated! Victory!")
```

### Create the Scene

1. **New Scene** → Add `Node3D` as root
2. **Add Player**: Instance `scenes/Player3D.tscn` as child
3. **Add Ground**: `MeshInstance3D` → PlaneMesh (30x30)
4. **Add Light**: `DirectionalLight3D`
5. **Add Environment**: `WorldEnvironment` with default environment
6. **Attach Script**: `my_first_level.gd` to root
7. **Save**: `scenes/MyFirstLevel.tscn`
8. **Run** (F6)

---

## Step 4: Add a Game Mode (5 minutes)

Let's add objectives to your level!

### Update Your Script

Add this to `my_first_level.gd`:

```gdscript
# At the top
const TutorialGameModeExample = preload("res://examples/TutorialGameModeExample.gd")

var game_mode

func _ready():
    # Create game mode
    game_mode = TutorialGameModeExample.TutorialCombatMode.create()

    # Connect signals
    game_mode.objectives_updated.connect(_on_objectives_updated)
    game_mode.mode_completed.connect(_on_victory)

    # ... rest of your _ready() code

func _on_enemy_died(enemy):
    enemies.erase(enemy)

    # Update game mode
    game_mode.update_progress("enemy_defeated", 1)

    if enemies.is_empty():
        print("All enemies defeated!")

func _on_objectives_updated(objectives):
    print("Progress: %d/%d enemies" % [
        objectives["enemies_defeated"]["current"],
        objectives["enemies_defeated"]["target"]
    ])

func _on_victory():
    var stars = game_mode.get_star_rating()
    print("Victory! Earned %d stars!" % stars)
```

Now your level has:
- Objective tracking
- Star ratings
- Win conditions

---

## Step 5: Explore More (Optional)

### Existing Scenes to Study

**Tutorial Arena** (`scripts/tutorial/TutorialArenaLevel.gd`)
- Complete wave-based combat
- UI integration
- Enemy variety
- Boss fights

**Combat Level** (`scenes/CombatLevel.tscn`)
- Full DQ Dai combat system
- Multiple enemy types
- Formation-based encounters

**Main 3D Runner** (`scenes/Main3D.tscn`)
- Endless runner mode
- Obstacle spawning
- RPG progression

**Main Menu** (`scripts/tutorial/TutorialMainMenu.gd`)
- Menu system
- Mode selection
- Scene transitions

### Example Files

**Game Mode Examples** (`examples/TutorialGameModeExample.gd`)
- 5 pre-built game mode templates
- Distance challenge
- Coin collection
- Combat mastery
- Multi-objective
- Progressive difficulty

**Quick Start Modes** (`examples/QuickStartGameModes.gd`)
- Pre-configured game modes ready to use

---

## Common Tasks

### Add a New Enemy Type

```gdscript
# my_custom_enemy.gd
extends "res://scripts/EnemyAI.gd"

func _init():
    max_health = 100
    attack_damage = 15
    movement_speed = 4.0

func choose_attack_pattern():
    return "my_attack"

func execute_pursuing_behavior(delta):
    # Custom movement logic
    pass
```

### Create a Custom Ability

```gdscript
var fireball = AbilityData.new()
fireball.ability_name = "Fireball"
fireball.cost_amount = 20
fireball.damage = 50
fireball.cooldown = 3.0
```

### Save Player Progress

```gdscript
var save_manager = SaveDataManager.new()
save_manager.save_game(player_data, "slot1")
```

---

## Next Steps

📖 **Read Full Tutorial**: `TUTORIAL_MODULAR_SETUP.md`
- In-depth component documentation
- Advanced patterns
- Complete examples

🎮 **Try Existing Scenes**:
- Run `scenes/CombatLevel.tscn`
- Run `scenes/Main3D.tscn`
- Explore `scenes/DemoLauncher.tscn`

💻 **Experiment**:
- Mix different enemy types
- Create hybrid runner-combat levels
- Design custom game modes
- Build your own progression system

---

## Architecture Overview

```
Game
├── Menus (ModeSelectionUI, TutorialMainMenu)
├── Game Modes (Story, Challenge, Timed, Custom)
├── Levels (Runner, Combat, Arena, Custom)
│   ├── Player (RPGPlayer3D with modular systems)
│   ├── Enemies (6 types, all extend EnemyAI)
│   ├── Combat System (DaiCombatController)
│   └── Spawn System (EnemySpawner, ObstacleSpawner)
└── Progression (XP, Equipment, Abilities, Save/Load)
```

### Key Principles

**1. Signal-Driven**: Components communicate via signals, no tight coupling
**2. Resource-Based**: Game modes, abilities, equipment are Resources
**3. Composition**: Systems are composed, not monolithic
**4. Inheritance**: Clear base classes (EnemyAI, BaseGameMode)
**5. Extensible**: Easy to add new enemies, modes, abilities

---

## Troubleshooting

**Q: Enemy isn't attacking**
- Check `target_player` is set
- Ensure player is in `detection_range`
- Verify collision layers/masks

**Q: Game mode not tracking progress**
- Call `update_progress()` with correct event type
- Check objective names match
- Connect to `objectives_updated` signal

**Q: Scene won't load**
- Verify file path is correct
- Check scene has required nodes
- Look for errors in Output panel

**Q: Player can't move**
- Ensure Player3D scene is properly configured
- Check input map settings (Project → Project Settings → Input Map)
- Verify CharacterBody3D has collision

---

## Resources

- **Full Documentation**: `TUTORIAL_MODULAR_SETUP.md`
- **Game Mode Examples**: `examples/TutorialGameModeExample.gd`
- **Tutorial Scripts**: `scripts/tutorial/`
- **Component Scripts**: `scripts/enemies/`, `scripts/game_modes/`, `scripts/combat/`

---

## Getting Help

1. Check the **Output** panel in Godot for error messages
2. Review example scenes and scripts
3. Read component documentation in script files
4. Test individual components in isolation

---

**Happy Building! 🎮**

The modular system is designed to be flexible and easy to extend. Start small, experiment often, and build amazing games!
