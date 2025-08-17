# Enemy Attack System Documentation

## Overview

The Enemy Attack System provides telegraphed attacks that require specific dodge directions, creating engaging tactical combat encounters. The system includes multiple enemy types with distinct attack patterns, visual and audio cues, and boss encounters with multi-phase telegraphing.

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
- **Attack Patterns**: Overhead slams, ground pound area attacks
- **Behavior**: Slow but powerful, hard to interrupt
- **Dodge Requirements**: Side dodges for slams, backward for area attacks

#### AgileRogueEnemy
- **Attack Patterns**: Quick dash attacks, multi-hit combos
- **Behavior**: Fast movement, hit-and-run tactics
- **Dodge Requirements**: Various directions based on attack sequence

#### MageCasterEnemy
- **Attack Patterns**: Fireball spells, lightning storm area attacks
- **Behavior**: Long-range casting, retreats when threatened
- **Dodge Requirements**: Side dodges for fireballs, backward for storms
- **Special**: Mana system affects attack availability

#### BossEnemy
- **Attack Patterns**: Multi-phase complex sequences
- **Behavior**: Phase transitions, enrage mode, special attacks
- **Dodge Requirements**: Complex sequences requiring multiple dodges
- **Special**: Health-based phase transitions, damage reduction during transitions

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