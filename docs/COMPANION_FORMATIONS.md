# Companion Formation System

## Overview
The companion system allows players to manage AI companions in different tactical formations during gameplay.

## Formation Types

### 1. **Triangle Formation** (Default)
- **Description**: Triangle formation with player at front
- **Layout**: Player leads, companions behind in triangle shape
- **Best for**: Balanced offense and defense

### 2. **Line Formation**
- **Description**: Line formation across lanes
- **Layout**: All units in same row, different lanes
- **Best for**: Wide area coverage

### 3. **Column Formation**
- **Description**: Column formation in same lane
- **Layout**: All units in same lane, different rows
- **Best for**: Focused assault or retreat

### 4. **Spread Formation**
- **Description**: Maximum spread formation
- **Layout**: Companions spread across maximum distance
- **Best for**: Area control and flanking

### 5. **Defensive Formation**
- **Description**: Defensive formation with companions in front
- **Layout**: Companions protect player from front
- **Best for**: Defensive situations

### 6. **Follow Formation**
- **Description**: Close follow formation
- **Layout**: Companions stay close to player
- **Best for**: Protection and support

## Controls

### Formation Management
- **F Key**: Cycle through formations
- **G Key**: Issue "Follow" command
- **B Key**: Issue "Defend" command  
- **V Key**: Issue "Attack" command
- **C Key**: Use companion abilities

## Formation Cycling
When pressing **F**, formations cycle in this order:
1. Triangle → Line → Column → Spread → Defensive → Follow → (back to Triangle)

Each formation change provides:
- Visual feedback with formation name
- Description of the formation's purpose
- Automatic repositioning of companions

## Technical Details

### Position System
- **Lanes**: Left (-3.0), Center (0.0), Right (3.0)
- **Rows**: Back (-8.0), Mid-Back (-5.0), Mid-Front (-2.0), Front (1.0)
- **Smooth Movement**: Companions lerp to new positions over time

### Companion Commands
The system supports various companion commands:
- `FOLLOW`: Follow player in formation
- `HOLD`: Hold current position
- `ATTACK`: Focus on attacking enemies
- `DEFEND`: Focus on defending player
- `RETREAT`: Move to safer positions
- `ABILITY`: Use special abilities
- `MOVE_TO`: Move to specific position

## Integration
The formation system integrates with:
- Lane-based movement system
- Combat system
- Player input handling
- Visual feedback system
