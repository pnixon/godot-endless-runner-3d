# Modular Game Component Tutorial System

This tutorial demonstrates how to build a complete game using the modular components in this framework. Learn how to create menus, levels, enemies, and game modes using pre-built, reusable systems.

## 📚 Tutorial Resources

### Getting Started

1. **[QUICKSTART.md](QUICKSTART.md)** - Start here!
   - 5-minute quick start guide
   - Simple examples to get you building fast
   - Common tasks and troubleshooting

2. **[TUTORIAL_MODULAR_SETUP.md](TUTORIAL_MODULAR_SETUP.md)** - Complete tutorial
   - In-depth component documentation
   - Architecture overview
   - Advanced integration patterns
   - Best practices

### Example Code

3. **[examples/TutorialGameModeExample.gd](examples/TutorialGameModeExample.gd)**
   - 5 pre-built game mode templates
   - Distance, Coin, Combat, Multi-objective, Progressive modes
   - Copy-paste ready code

4. **[scripts/tutorial/TutorialArenaLevel.gd](scripts/tutorial/TutorialArenaLevel.gd)**
   - Complete playable arena level
   - Wave-based combat
   - Enemy spawning
   - UI integration

5. **[scripts/tutorial/TutorialMainMenu.gd](scripts/tutorial/TutorialMainMenu.gd)**
   - Full menu system implementation
   - Mode selection
   - Scene transitions

---

## 🎮 What's Included

### Modular Components

#### 1. **Enemy System**
- **Base Class**: `EnemyAI.gd`
- **6 Enemy Types**:
  - BasicMeleeEnemy - Close-range fighter
  - RangedArcherEnemy - Ranged attacker
  - HeavyBruiserEnemy - Tank
  - AgileRogueEnemy - Fast & evasive
  - MageCasterEnemy - Spell caster
  - BossEnemy - Multi-phase boss with special mechanics

**Key Features**:
- Health system
- State machine (Idle, Pursuing, Attacking, Retreating, Stunned, Dead)
- Attack patterns
- Detection/aggro range
- Signal-driven events

#### 2. **Game Mode System**
- **Base Class**: `BaseGameMode.gd`
- **Pre-built Modes**: Story, Challenge, Timed
- **Custom Modes**: Easy to create your own

**Key Features**:
- Objective tracking
- Star ratings (1-3 stars based on performance)
- Win/loss conditions
- Lives system (infinite, limited, one-life)
- Time limits
- Progress saving

#### 3. **Combat System**
- **DQ Dai Combat Controller**: Auto-attack + skill system
- **Combat Grid**: 2D grid positioning
- **Attack System**: Telegraphed attacks with dodge windows

**Key Features**:
- Skill charging on hit
- Boss stagger/break mechanics
- Party management
- Combo tracking
- Visual/audio feedback

#### 4. **RPG Progression**
- Player stats (HP, Attack, Defense, etc.)
- Level-up system with XP
- Equipment management
- Ability/skill trees
- Companion/party system
- Status effects and buffs
- Save/load system

#### 5. **Menu/UI System**
- Mode selection UI
- Objectives display
- Combat HUD
- Skill trees
- Customizable layouts

---

## 🚀 Quick Start Examples

### Example 1: Spawn an Enemy

```gdscript
const BasicMeleeEnemy = preload("res://scripts/enemies/BasicMeleeEnemy.gd")

func spawn_enemy(position: Vector3):
    # Create visual (simple cube)
    var enemy_visual = CharacterBody3D.new()
    var mesh = MeshInstance3D.new()
    var box = BoxMesh.new()
    box.size = Vector3(1, 2, 1)
    mesh.mesh = box
    enemy_visual.add_child(mesh)
    add_child(enemy_visual)
    enemy_visual.global_position = position

    # Add AI
    var enemy_ai = BasicMeleeEnemy.new()
    enemy_ai.max_health = 50
    enemy_ai.target_player = player
    enemy_visual.add_child(enemy_ai)

    # Connect signals
    enemy_ai.enemy_died.connect(_on_enemy_died)

    return enemy_ai
```

### Example 2: Create a Custom Game Mode

```gdscript
extends "res://scripts/game_modes/BaseGameMode.gd"

class_name MyCustomMode

func _init():
    mode_name = "Survival Challenge"
    description = "Survive as long as possible!"

    objectives = {
        "time_survived": {"target": 300.0, "current": 0.0},
        "enemies_defeated": {"target": 20, "current": 0}
    }

    star_thresholds = {
        1: 60.0,   # 1 minute
        2: 180.0,  # 3 minutes
        3: 300.0   # 5 minutes
    }

    lives_type = "limited"
    starting_lives = 3

func update_progress(event_type: String, value):
    match event_type:
        "time_survived":
            objectives["time_survived"]["current"] = value
        "enemy_defeated":
            objectives["enemies_defeated"]["current"] += 1

    emit_signal("objectives_updated", objectives)

func check_completion() -> bool:
    return objectives["time_survived"]["current"] >= objectives["time_survived"]["target"]
```

### Example 3: Wave-Based Level

```gdscript
extends Node3D

var waves = [
    [{"type": "melee", "count": 3}],
    [{"type": "melee", "count": 2}, {"type": "archer", "count": 1}],
    [{"type": "boss", "count": 1}]
]

var current_wave = 0
var enemies_in_wave = []

func start_wave(wave_index):
    current_wave = wave_index
    enemies_in_wave.clear()

    for enemy_data in waves[wave_index]:
        for i in enemy_data["count"]:
            var enemy = spawn_enemy(enemy_data["type"])
            enemy.enemy_died.connect(_on_enemy_died.bind(enemy))
            enemies_in_wave.append(enemy)

func _on_enemy_died(enemy):
    enemies_in_wave.erase(enemy)

    if enemies_in_wave.is_empty():
        if current_wave + 1 < waves.size():
            start_wave(current_wave + 1)
        else:
            print("All waves complete!")
```

---

## 🏗️ Architecture Patterns

### 1. Signal-Driven Communication

Components communicate via signals, avoiding tight coupling:

```gdscript
# Enemy emits
enemy.enemy_died.connect(_on_enemy_died)
enemy.health_changed.connect(_on_health_changed)
enemy.attack_pattern_triggered.connect(_on_attack)

# Combat system emits
combat_controller.skill_activated.connect(_on_skill_used)
combat_controller.boss_staggered.connect(_on_boss_stagger)

# Game mode emits
game_mode.objectives_updated.connect(_update_ui)
game_mode.mode_completed.connect(_on_victory)
```

### 2. Resource-Based Configuration

Game elements are defined as resources for easy modification:

```gdscript
# Create ability
var fireball = AbilityData.new()
fireball.ability_name = "Fireball"
fireball.damage = 50
fireball.cost_amount = 20

# Create game mode
var survival_mode = SurvivalMode.new()
survival_mode.time_limit = 300

# Create equipment
var sword = Equipment.new()
sword.equipment_type = Equipment.EquipmentType.WEAPON
sword.attack_bonus = 10
```

### 3. Composition Over Inheritance

Player is composed of independent systems:

```gdscript
# Each system is modular and reusable
var player_data = PlayerData.new()
var equipment_manager = EquipmentManager.new()
var level_up_system = LevelUpSystem.new()
var ability_system = AbilitySystem.new()

# Systems can be swapped, disabled, or extended independently
```

### 4. Extensibility Through Inheritance

Easy to create custom variations:

```gdscript
# Custom enemy - just override behavior methods
extends "res://scripts/EnemyAI.gd"

func choose_attack_pattern():
    # Your custom logic
    return "special_attack"

# Custom game mode - just override conditions
extends "res://scripts/game_modes/BaseGameMode.gd"

func check_completion() -> bool:
    # Your custom win condition
    return custom_condition_met
```

---

## 📁 File Structure

```
godot-endless-runner-3d/
├── QUICKSTART.md                           # 5-minute quick start
├── TUTORIAL_MODULAR_SETUP.md               # Complete tutorial
├── TUTORIAL_README.md                      # This file
│
├── examples/
│   └── TutorialGameModeExample.gd          # 5 game mode templates
│
├── scripts/
│   ├── tutorial/
│   │   ├── TutorialArenaLevel.gd           # Complete arena demo
│   │   └── TutorialMainMenu.gd             # Menu system demo
│   │
│   ├── enemies/
│   │   ├── BasicMeleeEnemy.gd
│   │   ├── RangedArcherEnemy.gd
│   │   ├── HeavyBruiserEnemy.gd
│   │   ├── AgileRogueEnemy.gd
│   │   ├── MageCasterEnemy.gd
│   │   └── BossEnemy.gd
│   │
│   ├── game_modes/
│   │   ├── BaseGameMode.gd                 # Base class
│   │   ├── StoryMode.gd
│   │   ├── ChallengeMode.gd
│   │   ├── TimedMode.gd
│   │   └── GameModeManager.gd              # Singleton
│   │
│   ├── combat/
│   │   ├── DaiCombatController.gd
│   │   ├── CombatGrid.gd
│   │   ├── AbilityData.gd
│   │   └── DaiAbilityLibrary.gd
│   │
│   ├── rpg/
│   │   ├── PlayerData.gd
│   │   ├── LevelUpSystem.gd
│   │   ├── EquipmentManager.gd
│   │   ├── AbilitySystem.gd
│   │   └── SaveDataManager.gd
│   │
│   └── ui/
│       ├── ModeSelectionUI.gd
│       ├── ModeObjectivesUI.gd
│       └── DaiCombatUI.gd
│
└── scenes/
    ├── Main3D.tscn                         # Runner mode
    ├── CombatLevel.tscn                    # Combat mode
    └── Player3D.tscn                       # Player character
```

---

## 🎓 Learning Path

### Beginner (30 minutes)
1. Read [QUICKSTART.md](QUICKSTART.md)
2. Run `TutorialArenaLevel.gd` (create scene, attach script, run)
3. Study `examples/TutorialGameModeExample.gd`
4. Create your first custom enemy

### Intermediate (2 hours)
1. Read [TUTORIAL_MODULAR_SETUP.md](TUTORIAL_MODULAR_SETUP.md)
2. Create a custom game mode
3. Build a wave-based level with multiple enemy types
4. Integrate combat system with DaiCombatController
5. Add UI for objectives and progress

### Advanced (4+ hours)
1. Study existing scenes (CombatLevel.tscn, Main3D.tscn)
2. Create hybrid runner-combat gameplay
3. Build custom RPG progression system
4. Implement save/load functionality
5. Design multi-level campaign with story progression

---

## 🔧 Common Customizations

### Custom Enemy Behavior

```gdscript
extends "res://scripts/EnemyAI.gd"

# Override to change when enemy attacks
func choose_attack_pattern():
    if current_health < max_health * 0.3:
        return "desperate_attack"  # Low health = aggressive
    return "normal_attack"

# Override to change movement
func execute_pursuing_behavior(delta):
    # Circle around player instead of direct pursuit
    var angle = Time.get_ticks_msec() / 1000.0
    var offset = Vector3(cos(angle) * 5, 0, sin(angle) * 5)
    var target_pos = target_player.global_position + offset
    velocity = (target_pos - global_position).normalized() * movement_speed
```

### Custom Game Objectives

```gdscript
extends "res://scripts/game_modes/BaseGameMode.gd"

func _init():
    objectives = {
        "headshots": {"target": 10, "current": 0},
        "no_damage": {"target": 1, "current": 1},  # Boolean: 1 = true
        "speed_bonus": {"target": 1, "current": 0}
    }

func update_progress(event_type: String, value):
    match event_type:
        "headshot":
            objectives["headshots"]["current"] += 1
        "damage_taken":
            objectives["no_damage"]["current"] = 0  # Failed no-damage run
        "time_completed":
            if value < 60:  # Under 1 minute
                objectives["speed_bonus"]["current"] = 1
```

### Custom Abilities

```gdscript
# Create custom ability resource
var lightning_strike = AbilityData.new()
lightning_strike.ability_name = "Lightning Strike"
lightning_strike.description = "Call down lightning on enemies"
lightning_strike.ability_type = AbilityData.AbilityType.OFFENSIVE
lightning_strike.cost_type = AbilityData.CostType.MANA
lightning_strike.cost_amount = 30
lightning_strike.damage = 75
lightning_strike.cooldown = 5.0
lightning_strike.aoe_radius = 3.0

# Add to player ability system
player.ability_system.learn_ability(lightning_strike)
```

---

## 🐛 Troubleshooting

### Common Issues

**Issue**: Enemy doesn't detect player
- **Fix**: Set `enemy.target_player = player` after spawning
- **Fix**: Check `detection_range` is large enough
- **Fix**: Verify collision layers/masks

**Issue**: Game mode objectives not updating
- **Fix**: Call `game_mode.update_progress("event_type", value)`
- **Fix**: Check event type string matches your objective keys
- **Fix**: Connect to `objectives_updated` signal

**Issue**: Combat system not working
- **Fix**: Call `combat_controller.initialize(player)` in `_ready()`
- **Fix**: Register enemies: `combat_controller.register_enemy(enemy)`
- **Fix**: Ensure player has required methods (`take_damage`, etc.)

**Issue**: Scene transitions not working
- **Fix**: Use `get_tree().change_scene_to_file("res://path/to/scene.tscn")`
- **Fix**: Verify scene file exists and path is correct
- **Fix**: Check for errors in Output panel

---

## 💡 Tips & Best Practices

### Performance
- Use object pooling for frequently spawned enemies
- Limit active enemies on screen (despawn distant ones)
- Use visibility culling for off-screen objects

### Organization
- Group related enemies in folders (forest enemies, dungeon enemies, etc.)
- Use naming conventions (prefix enemies with type: "Enemy_Goblin")
- Keep game modes in separate resource files

### Testing
- Test individual components in isolation
- Create test scenes for each enemy type
- Use `print()` statements liberally during development

### Extensibility
- Always extend base classes, don't modify them
- Use signals for inter-component communication
- Keep configuration in resources, not hardcoded

---

## 📖 Additional Resources

### In This Project
- **Component Scripts**: Read documentation in script files
- **Example Scenes**: Study existing scenes for patterns
- **Test Files**: Check `test_*.gd` files for usage examples

### External Resources
- [Godot Documentation](https://docs.godotengine.org/)
- [GDScript Reference](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/index.html)
- [3D Game Tutorial](https://docs.godotengine.org/en/stable/getting_started/first_3d_game/index.html)

---

## 🎯 Next Steps

1. **Complete the Quick Start** - Get hands-on experience
2. **Read the Full Tutorial** - Understand the architecture
3. **Study Examples** - See patterns in action
4. **Build Something** - Create your own level/mode/enemy
5. **Experiment** - Mix and match components
6. **Share** - Show off what you've created!

---

## 🤝 Contributing

If you create interesting:
- Custom enemies
- Game modes
- Levels
- Abilities

Consider sharing them as examples for others to learn from!

---

**Happy Game Development! 🎮**

This modular framework is designed to accelerate your game development. Start with the quick start, explore the examples, and build something amazing!
