# Enhanced Enemy Attack System Documentation

## Overview

The Enhanced Enemy Attack System provides sophisticated telegraphed attacks that require specific dodge directions, creating engaging tactical combat encounters. The system includes multiple enemy types with distinct attack patterns, enhanced visual and audio cues, multi-phase boss encounters, and combo attack sequences that provide deep tactical gameplay.

## Core Components

### EnemyAttackSystem
- **Purpose**: Manages attack patterns, telegraphing, and dodge requirements
- **Features**: 
  - Attack pattern database with visual/audio cues
  - Telegraph timing and visual effects
  - Integration with combat controller for dodge mechanics

### EnemyAI (Base Class)
- **Purpose**: Base AI behavior for all enemies
- **Features**:
  - State machine (Idle, Pursuing, Attacking, Retreating, Stunned, Dead)
  - Health management and damage handling
  - Attack pattern selection and execution

### Enemy Types

#### BasicMeleeEnemy
- **Attack Patterns**: Simple frontal attacks, left-right combos
- **Behavior**: Aggressive close-range combat
- **Dodge Requirements**: Backward for frontal, left/right for side attacks

#### RangedArcherEnemy
- **Attack Patterns**: Single arrow shots, triple volleys
- **Behavior**: Maintains distance, strafes to avoid attacks
- **Dodge Requirements**: Side dodges for arrows, backward for volleys

#### HeavyBruiserEnemy
- **Attack Patterns**: Overhead slams, ground pound area attacks, bull rush charges, slam-pound combos
- **Behavior**: Slow but powerful, hard to interrupt, becomes more aggressive when damaged
- **Dodge Requirements**: Side dodges for slams, backward for area attacks, side dodges for charges
- **Special**: Combo attacks require multiple sequential dodges

#### AgileRogueEnemy
- **Attack Patterns**: Quick dash attacks (left/right), multi-hit combos, spinning blade area attacks, shadow strike sequences
- **Behavior**: Fast movement, hit-and-run tactics, dash abilities for mobility
- **Dodge Requirements**: Various directions based on attack sequence, rapid dodge sequences for combos
- **Special**: Shadow strike combos teleport between attack positions

#### MageCasterEnemy
- **Attack Patterns**: Fireball spells, lightning storm area attacks, ice shard barrages, meteor strikes, arcane missile combos
- **Behavior**: Long-range casting, retreats when threatened, mana management affects spell selection
- **Dodge Requirements**: Side dodges for fireballs, backward for storms, varied patterns for barrages
- **Special**: Mana system affects attack availability, casting times vary by spell complexity, meteor strikes have extended telegraph times

#### BossEnemy
- **Attack Patterns**: Multi-phase complex sequences, tier-specific patterns, enrage patterns, desperation attacks
- **Behavior**: Phase transitions, enrage mode, special attacks, adaptive pattern selection
- **Dodge Requirements**: Complex sequences requiring multiple dodges, extended combo chains
- **Special**: Health-based phase transitions, damage reduction during transitions, tier-specific escalation, desperation mode at low health
- **Enhanced Features**: 
  - Tier 1: 3-phase basic boss patterns with alternates
  - Tier 2: 5-attack complex sequences with enrage variants
  - Final Boss: 6-attack ultimate sequences with desperation patterns

## Attack Types

### Frontal Attacks
- **Visual Cue**: Red rectangular telegraph in front of enemy
- **Audio Cue**: "frontal_windup"
- **Required Dodge**: Backward
- **Examples**: Basic slash, fireball

### Side Attacks
- **Visual Cue**: Orange rectangular telegraph to enemy's side
- **Audio Cue**: "side_windup"
- **Required Dodge**: Opposite direction (left attack = dodge right)
- **Examples**: Side swipes, dash attacks

### Area Attacks
- **Visual Cue**: Purple circular telegraph around enemy
- **Audio Cue**: "area_windup"
- **Required Dodge**: Backward or to safe zones
- **Examples**: Ground pound, lightning storm

### Overhead Attacks
- **Visual Cue**: Yellow spherical telegraph above target
- **Audio Cue**: "overhead_windup"
- **Required Dodge**: Side dodges
- **Examples**: Overhead slam, aerial attacks

## Testing the System

### In-Game Testing Controls

When running the game, use these keys to test different aspects:

#### Combat System Tests
- **Enter**: Test basic combat scenario with telegraphed attacks
- **Z/X/N**: Dodge left/right/backward
- **Space**: Block incoming attacks

#### Enemy Encounter Tests
- **1**: Spawn "Single Goblin" encounter
- **2**: Spawn "City Guard" encounter (melee + archer)
- **3**: Spawn "Balanced Squad" encounter (melee + archer + mage)
- **4**: Spawn "Boss Tier 1" encounter

#### Individual Enemy Tests
- **5**: Spawn Basic Melee enemy
- **6**: Spawn Ranged Archer enemy
- **7**: Spawn Mage Caster enemy
- **8**: Spawn Boss Tier 1 enemy

### Expected Behavior

1. **Telegraph Phase**: Enemy shows visual indicator and plays audio cue
2. **Timing Window**: Player has specific time to dodge in correct direction
3. **Perfect Dodge**: Dodging at the right time in right direction grants invincibility frames
4. **Attack Execution**: If not dodged, attack deals damage based on enemy type
5. **Visual Feedback**: Screen effects and particle systems show attack results

## Integration with Existing Systems

### Combat Controller Integration
- Enemies register attacks with the combat controller
- Combat controller handles dodge timing and perfect dodge detection
- Invincibility frames prevent damage during perfect dodges

### Game Manager Integration
- Enemy spawner manages encounter flow
- Rewards system awards XP and coins for defeated enemies
- Score multipliers apply to enemy defeat bonuses

### Mobile Input Integration
- Touch gestures map to dodge directions
- Haptic feedback provides tactile response to combat actions
- Visual indicators show touch zones for combat controls

## Attack Pattern Examples

### Basic Melee Combo
```
1. Left Swipe (1.2s telegraph) -> Dodge Right
2. Right Swipe (1.2s telegraph) -> Dodge Left
```

### Archer Triple Volley
```
1. Left Arrow (2.5s telegraph) -> Dodge Right
2. Center Arrow (2.5s telegraph) -> Dodge Backward  
3. Right Arrow (2.5s telegraph) -> Dodge Left
```

### Boss Multi-Phase
```
Phase 1: Charge Attack (2.0s) -> Dodge Backward
Phase 2: Side Sweep (1.5s) -> Dodge Right
Phase 3: Area Slam (2.5s) -> Dodge Left
```

## Performance Considerations

- Telegraph effects use efficient mesh instances with material animations
- Attack patterns are pre-defined to avoid runtime allocation
- Enemy AI uses state machines to minimize per-frame calculations
- Visual effects are pooled and reused when possible

## Future Enhancements

- Additional enemy types with unique mechanics
- Environmental hazards that require specific dodge patterns
- Combo system rewarding consecutive perfect dodges
- Dynamic difficulty adjustment based on player performance
- Multiplayer support for cooperative dodge mechanics
### Com
bo Attacks
- **Visual Cue**: Magenta rectangular telegraph
- **Audio Cue**: "combo_windup"
- **Required Dodge**: Multiple sequential dodges
- **Examples**: Multi-hit sequences, boss combos

### Boss Special Attacks
- **Visual Cue**: Large dark red circular telegraph with rim lighting
- **Audio Cue**: "boss_special_windup"
- **Required Dodge**: Varies by specific attack
- **Examples**: Ultimate abilities, phase transition attacks
- **Special**: Enhanced visual effects with warning particles

## Enhanced Attack Features

### Multi-Phase Attack Patterns
- **Boss Tier 1**: 3-4 attack sequences with 2-4 second intervals
- **Boss Tier 2**: 5-attack complex patterns with varied timing
- **Final Boss**: 6-attack ultimate sequences with 17+ second duration
- **Combo Attacks**: Sequential attacks requiring different dodge directions

### Enhanced Visual Telegraphing
- **Attack-Specific Effects**: Different mesh shapes and colors for each attack type
- **Warning Particles**: Dangerous attacks (40+ damage) show particle warnings
- **Scaling Effects**: Boss and area attacks scale up during telegraph
- **Intensity Ramping**: Telegraph effects intensify as attack approaches
- **Directional Indicators**: Side attacks show rotated telegraph meshes

### Improved Audio System
- **Contextual Audio**: Different audio cues based on attack importance
- **Boss Audio**: Special high-intensity audio for boss attacks
- **Magic Audio**: Distinct magical energy sounds for spell attacks
- **Impact Audio**: Ground impact warnings for area attacks

### Adaptive Enemy Behavior
- **Pattern Variety**: Each enemy type has 4-5 different attack patterns
- **Health-Based Selection**: Attack patterns change based on enemy health
- **Distance Awareness**: Enemies choose attacks based on player distance
- **Combo Avoidance**: Enemies avoid repeating the same pattern consecutively

## Enhanced Attack Pattern Examples

### Heavy Bruiser Slam-Pound Combo
```
1. Overhead Slam (2.2s telegraph) -> Dodge Right
2. Ground Pound (2.5s telegraph) -> Dodge Backward
Total Duration: 6.0 seconds
```

### Rogue Shadow Strike Combo
```
1. Shadow Strike Left (1.2s telegraph) -> Dodge Right
2. Shadow Strike Right (1.0s telegraph) -> Dodge Left  
3. Shadow Strike Overhead (1.5s telegraph) -> Dodge Backward
Total Duration: 4.5 seconds
```

### Mage Ice Shard Barrage
```
1. Ice Shard Left (2.0s telegraph) -> Dodge Right
2. Ice Shard Center (2.0s telegraph) -> Dodge Backward
3. Ice Shard Right (2.0s telegraph) -> Dodge Left
Total Duration: 4.4 seconds (overlapping)
```

### Final Boss Ultimate Sequence
```
Phase 1: Charge Attack (3.0s) -> Dodge Backward
Phase 2: Left Sweep (2.0s) -> Dodge Right
Phase 3: Right Sweep (2.0s) -> Dodge Left
Phase 4: Area Devastation (4.0s) -> Dodge Backward
Phase 5: Overhead Slam (2.5s) -> Dodge Left
Phase 6: Ultimate Attack (5.0s) -> Dodge Right
Total Duration: 20.5 seconds
```

## Performance Enhancements

- **Optimized Telegraph Effects**: Efficient mesh instances with material animations
- **Pattern Caching**: Pre-defined attack patterns to avoid runtime allocation
- **Visual Effect Pooling**: Reusable particle and telegraph effects
- **Smart Audio Management**: Context-aware audio cue selection
- **Adaptive Quality**: Telegraph complexity scales with device performance

## Integration Improvements

### Enhanced Combat Controller Integration
- **Multi-Attack Tracking**: Handles multiple simultaneous telegraphed attacks
- **Perfect Dodge Windows**: Precise timing windows for each attack type
- **Combo Dodge Chains**: Support for sequential dodge requirements

### Advanced Enemy AI Integration
- **Contextual Pattern Selection**: Enemies choose patterns based on tactical situation
- **Health-Based Adaptation**: Attack patterns evolve as enemy health decreases
- **Player Behavior Learning**: Enemies adapt to player dodge patterns over time

## Future Enhancement Opportunities

- **Environmental Hazards**: Telegraph system extended to environmental dangers
- **Cooperative Dodge Mechanics**: Multi-player coordinated dodge requirements
- **Dynamic Difficulty**: Telegraph timing adjusts based on player performance
- **Accessibility Options**: Visual and audio accessibility improvements
- **Advanced Boss Mechanics**: Phase-specific vulnerability windows and counter-attacks