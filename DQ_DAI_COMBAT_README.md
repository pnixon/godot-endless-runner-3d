# Dragon Quest: The Adventure of Dai Combat System

A complete implementation of the **Dragon Quest: The Adventure of Dai - A Hero's Bonds** combat system for Godot 4, integrated with the endless runner gameplay.

## 🎮 Features

### Core Combat Mechanics
- ✅ **Auto-Running**: Seamlessly integrated with the existing endless runner
- ✅ **Auto-Attack System**: Characters automatically attack nearby enemies
- ✅ **Lane-Based Combat**: Swipe/move between 3 lanes to attack enemies and dodge
- ✅ **Manual Skill Activation**: Charge and activate powerful special moves
- ✅ **Dodge & Block Mechanics**: Active defense system (from existing CombatController)
- ✅ **Party System**: Support for 4 heroes (2 active, 2 support)

### Boss Battle Features
- ✅ **Vulnerability Windows**: Bosses open windows where they can be staggered
- ✅ **Stagger Mechanics**: Land hits during vulnerability to stagger the boss
- ✅ **Break Mode**: Stagger bosses multiple times to trigger massive damage windows
- ✅ **Phase Transitions**: Bosses have multiple phases with increasing difficulty
- ✅ **Enrage Mode**: Low health triggers enhanced boss abilities

### Skill System
- ✅ **10+ Pre-made Abilities**: Iconic DQ Dai techniques
  - **Avan Strash** - Legendary cross-slash
  - **Air Slash** - Ranged blade wave
  - **Bloody Scryde** - Dark finishing move
  - **Gira/Hyado/Io** - Elemental magic
  - **Gigastrash** - Ultimate technique
  - And more!
- ✅ **Skill Charging**: Skills charge over time and from combat actions
- ✅ **MP/Stamina System**: Resource management for abilities
- ✅ **Skill Combos**: Chain abilities for bonus damage
- ✅ **Elemental System**: Fire, Ice, Lightning, Light, Dark

### Progression System
- ✅ **Equipment-Based Skills**: Unlock abilities by equipping weapons
- ✅ **Skill Scrolls**: One-time use items to permanently unlock skills
- ✅ **Skill Fragments**: Collect fragments from enemies to unlock abilities
- ✅ **Skill Upgrades**: Level up abilities to increase power

### UI Components
- ✅ **Skill Buttons**: 4 skill slots with charge indicators
- ✅ **HP/MP Bars**: Player resource display
- ✅ **Boss Health Bar**: Dedicated boss status display
- ✅ **Combat Indicators**: Stagger, break mode, vulnerability status
- ✅ **Auto-Attack Indicator**: Shows when auto-attacks are active

---

## 📁 File Structure

```
scripts/
├── DaiCombatIntegration.gd         # Main integration manager (ADD THIS TO YOUR SCENE!)
├── combat/
│   ├── AbilityData.gd              # Skill/ability data resource
│   ├── DaiAbilityLibrary.gd       # Pre-made DQ Dai abilities
│   ├── DaiCombatController.gd     # Core combat logic
│   └── SkillAcquisitionSystem.gd  # Skill unlocking/progression
├── ui/
│   └── DaiCombatUI.gd             # Combat UI system
└── enemies/
    └── BossEnemy.gd                # Enhanced with stagger/break mode
```

---

## 🚀 Quick Start Guide

### 1. Add Combat System to Your Scene

Add `DaiCombatIntegration` node to your main game scene:

```gdscript
# In your main scene or game manager
var dai_combat = DaiCombatIntegration.new()
add_child(dai_combat)
dai_combat.player = $Player  # Set your player reference
```

**OR** in the Godot editor:
1. Attach `DaiCombatIntegration.gd` as a script to a new Node
2. Set the `player` export variable to your player node
3. Run the game!

### 2. That's It!

The system automatically creates:
- Combat controller
- Skill acquisition system
- Combat UI
- Starter skill loadout (Air Slash, Gira, Heal, Avan Strash)

---

## 🎯 Using the Combat System

### Basic Controls

**Keyboard (default):**
- `1` - Activate Skill 1
- `2` - Activate Skill 2
- `3` - Activate Skill 3
- `4` - Activate Skill 4

**Customization:**
```gdscript
# In DaiCombatIntegration node inspector
skill_1_key = KEY_Q
skill_2_key = KEY_W
skill_3_key = KEY_E
skill_4_key = KEY_R
```

### Auto-Attack

Auto-attacks happen automatically when enemies are in range:
- Default interval: 1 second
- Default range: 5 units
- Charges skills on hit
- Works while running

### Skill Activation

Skills can be activated when:
1. ✅ Fully charged (0-100% charge bar)
2. ✅ Off cooldown
3. ✅ Player has enough MP/stamina

Skills charge through:
- Passive charging over time
- Landing auto-attacks
- Taking damage

---

## 👾 Boss Battles

### Registering a Boss

```gdscript
# When boss spawns
var boss = BossEnemy.new()
dai_combat.register_boss(boss)

# When boss is defeated
dai_combat.unregister_boss()
```

### Boss Mechanics Flow

1. **Normal Combat** → Boss attacks, player dodges/blocks
2. **Vulnerability Window Opens** → Boss shows opening (yellow indicator)
3. **Land Hits During Window** → Successful hits build stagger
4. **Boss Staggers** → Boss is stunned briefly (yellow stars)
5. **Repeat Staggers** → After 3 staggers...
6. **BREAK MODE!** → Massive damage window (cyan aura, 2x damage)

### Opening Vulnerability Windows

Bosses automatically open vulnerability windows, but you can trigger manually:

```gdscript
# Manually open a 3-second vulnerability window
dai_combat.open_boss_vulnerability_window(3.0)

# Or directly on the boss
boss.open_vulnerability_window(5.0)
```

---

## 🎨 Creating Custom Abilities

### Define a New Ability

```gdscript
# Create in DaiAbilityLibrary.gd or your own script
static func create_my_custom_skill() -> AbilityData:
    var ability = AbilityData.new()
    ability.ability_name = "Mega Slash"
    ability.description = "A powerful slashing attack"
    ability.ability_type = AbilityData.AbilityType.PHYSICAL_TECHNIQUE

    ability.mp_cost = 15
    ability.stamina_cost = 20.0
    ability.cooldown_time = 4.0

    ability.base_damage = 60.0
    ability.damage_multiplier = 1.2
    ability.crit_chance = 0.15

    ability.target_type = AbilityData.TargetType.SINGLE_ENEMY
    ability.max_range = 10.0

    ability.can_be_upgraded = true
    ability.max_level = 5

    return ability
```

### Unlock and Equip

```gdscript
# Unlock the skill
dai_combat.unlock_skill("Mega Slash")

# Equip to slot 0
dai_combat.equip_skill_to_slot("Mega Slash", 0)
```

---

## 🏆 Skill Progression

### 1. Equipment-Based Unlocking

```gdscript
# Create equipment that grants skills
var sword = SkillAcquisitionSystem.Equipment.new()
sword.equipment_name = "Sword of Avan"
sword.grants_skills = true
sword.skill_list = ["Avan Strash", "Air Slash"]

# Equip it
skill_acquisition.equip_weapon(sword)
# Skills are now unlocked while equipped!
```

### 2. Skill Fragments

```gdscript
# Add fragments (dropped from enemies)
dai_combat.add_skill_fragments("Avan Strash", 5)

# Check progress
var progress = skill_acquisition.get_fragment_progress("Avan Strash")
print(progress.current, " / ", progress.required)  # e.g., "15 / 25"

# Auto-unlocks when enough fragments collected!
```

### 3. Skill Scrolls

```gdscript
# Create a scroll
var scroll = SkillAcquisitionSystem.SkillScroll.new()
scroll.skill_name = "Gigastrash"
scroll.rarity = SkillAcquisitionSystem.SkillScroll.ScrollRarity.LEGENDARY

# Use it to instantly unlock
skill_acquisition.add_scroll(scroll)
skill_acquisition.use_skill_scroll(scroll)
# Skill permanently unlocked!
```

### 4. Auto-Drop System

```gdscript
# When enemy is defeated
dai_combat.on_enemy_defeated(enemy)

# Automatically:
# - Rolls for fragment drops (30% chance)
# - Awards 1-3 fragments for normal enemies
# - Awards 3-5 fragments for bosses
# - Unlocks skills when enough fragments collected
```

---

## 🔧 Configuration

### Combat Controller Settings

```gdscript
var controller = dai_combat.get_combat_controller()

# Auto-attack
controller.auto_attack_enabled = true
controller.auto_attack_interval = 1.0  # Attacks per second
controller.auto_attack_damage = 15.0
controller.auto_attack_range = 5.0

# Skill charging
controller.skill_charge_rate = 1.0  # Charge per second
controller.skill_charge_on_hit = 5.0  # Charge gained per auto-attack
controller.skill_charge_on_damaged = 10.0  # Charge when damaged

# Boss mechanics
controller.stagger_threshold = 3.0  # Hits needed to stagger
controller.break_mode_stagger_count = 3  # Staggers for break mode
controller.vulnerability_window_duration = 3.0
controller.break_mode_duration = 5.0
controller.break_mode_damage_multiplier = 2.0
```

### Skill Acquisition Settings

```gdscript
var acquisition = dai_combat.get_skill_acquisition()

# Fragment requirements (already set, but customizable)
acquisition.fragments_required["My Custom Skill"] = 30

# Drop rate
acquisition.fragment_drop_rate = 0.3  # 30% chance
```

---

## 🎬 Integration with Game Manager

### Connect to Your Game Manager

```gdscript
# In your ConfigurableGameManager.gd or similar
func _ready():
    # Create combat system
    var dai_combat = DaiCombatIntegration.new()
    add_child(dai_combat)
    dai_combat.player = player_node
    dai_combat.game_manager = self

    # Combat system will call these methods if they exist:
    # - on_skill_used(skill_name)
    # - on_boss_staggered(boss)
    # - on_break_mode(boss)
    # - on_skill_unlocked(skill)

func on_skill_used(skill_name: String):
    print("Player used: ", skill_name)
    # Add score, play effects, etc.

func on_boss_staggered(boss: Node3D):
    print("Boss staggered! Go all out!")
    # Show UI message, slow time, etc.

func on_break_mode(boss: Node3D):
    print("BREAK MODE! DEAL MASSIVE DAMAGE!")
    # Dramatic effects, camera shake, etc.

func on_skill_unlocked(skill: AbilityData):
    print("NEW SKILL UNLOCKED: ", skill.ability_name)
    # Show unlock screen, play fanfare, etc.
```

### Enemy Defeat Integration

```gdscript
# In EnemyAI.gd or similar
func die():
    # ... existing death logic ...

    # Process combat drops
    if dai_combat:
        dai_combat.on_enemy_defeated(self)

    queue_free()
```

---

## 🐛 Debug Commands

```gdscript
# Unlock all skills instantly
dai_combat.debug_unlock_all_skills()

# Max all fragments
dai_combat.debug_max_all_fragments()

# Print system status
dai_combat.debug_print_status()
```

---

## 📊 Pre-made Abilities Reference

### Basic Skills (10 fragments)
| Skill | Type | Element | MP | Damage | Description |
|-------|------|---------|----|----|-------------|
| Air Slash | Physical | None | 10 | 35 | Ranged sword wave |
| Gira | Magic | Fire | 8 | 40 | Fire damage + burn chance |
| Hyado | Magic | Ice | 8 | 35 | Ice damage + slow |
| Heal | Magic | Light | 15 | -50 | Restore health |

### Advanced Skills (25-30 fragments)
| Skill | Type | Element | MP | Damage | Description |
|-------|------|---------|----|----|-------------|
| Avan Strash | Physical | None | 20 | 80 | Legendary cross-slash |
| Io | Magic | Lightning | 12 | 55 | Lightning AoE + stun |
| Beast King Blitz | Physical | None | 25 | 120 | Explosive punch |
| Twin Sword Flash | Combo | None | 15 | 30×4 | Rapid multi-hit |

### Ultimate Skills (50-75 fragments)
| Skill | Type | Element | MP | Damage | Description |
|-------|------|---------|----|----|-------------|
| Bloody Scryde | Finisher | Dark | 50 | 200 | Dark piercing slash + lifesteal |
| Gigastrash | Finisher | Light | 60 | 250 | Ultimate Avan Strash evolution |

---

## 🎮 Gameplay Tips

1. **Charge Management**: Save fully-charged skills for boss vulnerability windows
2. **Auto-Attack Value**: Let auto-attacks charge your skills while you focus on dodging
3. **Vulnerability Windows**: Watch for boss animations that signal vulnerability
4. **Break Mode Timing**: Use your strongest skills during break mode for 2x damage
5. **Fragment Farming**: Fight more enemies to collect fragments faster
6. **Combo Chains**: Some skills can combo into others for bonus damage

---

## 🔗 System Integration Points

### With Existing Endless Runner:
- ✅ Works with existing 3-lane system
- ✅ Compatible with RunnerPlayer.gd and ConfigurablePlayer.gd
- ✅ Uses existing CombatController for dodge/block
- ✅ Integrates with EnemySpawner and enemy formations
- ✅ Uses existing ParticleEffects and CombatFeedbackSystem

### New Systems Added:
- DaiCombatController (auto-attack, skills, boss mechanics)
- SkillAcquisitionSystem (progression)
- DaiCombatUI (combat interface)
- Enhanced BossEnemy (stagger/break mode)

---

## 📝 Example: Complete Boss Battle

```gdscript
# Spawn boss
var boss = BossEnemy.new()
boss.boss_tier = 2  # Tier 2 boss
add_child(boss)

# Register with combat system
dai_combat.register_boss(boss)

# Boss will automatically:
# 1. Auto-attack the player
# 2. Open vulnerability windows periodically
# 3. Get staggered when hit during windows
# 4. Enter break mode after 3 staggers
# 5. Take 2x damage in break mode

# Player can:
# 1. Auto-attack the boss
# 2. Activate skills (1, 2, 3, 4 keys)
# 3. Dodge boss attacks
# 4. Build skill charge
# 5. Unleash powerful attacks during break mode

# When boss is defeated
boss.connect("enemy_died", func():
    dai_combat.unregister_boss()
    dai_combat.on_enemy_defeated(boss)  # Roll for fragments!
)
```

---

## 🚀 Advanced Usage

### Custom Skill Charge Sources

```gdscript
# Charge skills from custom events
func on_perfect_dodge():
    combat_controller._add_skill_charge_all(15.0)  # Bonus charge!

func on_combo_completed():
    combat_controller._add_skill_charge_all(20.0)
```

### Dynamic Difficulty

```gdscript
# Scale with game difficulty
combat_controller.auto_attack_damage = 15.0 * difficulty_multiplier
combat_controller.break_mode_damage_multiplier = 2.0 + (difficulty * 0.5)
```

### Save/Load Support

```gdscript
# Save
var save_data = skill_acquisition.get_save_data()
# Store save_data to file

# Load
skill_acquisition.load_save_data(loaded_data)
```

---

## 🎉 That's It!

You now have a fully functional Dragon Quest: The Adventure of Dai combat system integrated with your endless runner!

**Happy adventuring, hero!** ⚔️✨

---

## 📞 Support

For issues or questions, check:
- The script comments for detailed documentation
- `DaiCombatIntegration.debug_print_status()` for runtime debugging
- Godot console output for combat events

## 📜 License

Part of the Godot Endless Runner 3D project.
