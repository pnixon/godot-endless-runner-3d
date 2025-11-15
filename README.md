# Endless Runner 3D - Prototype

A complete 3D endless runner game prototype built with Godot 4.

## Features

### Core Gameplay
- **Lane-based movement system** - Move between 3 lanes with smooth transitions
- **Jump and slide mechanics** - Avoid obstacles by jumping or sliding
- **Progressive difficulty** - Game gets harder over time with faster spawning
- **Score system** - Distance-based scoring with bonuses for collectibles

### Obstacles
- **Ground Spikes** - Jump over these red hazards
- **Overhead Barriers** - Slide under these yellow obstacles
- **Walls** - Switch lanes to avoid blocking walls

### Collectibles
- **Coins** - Collect for points and currency
- **Health Potions** - Restore health
- **Shield Power-up** - Temporary invincibility
- **Speed Boost** - Temporary speed increase
- **Coin Magnet** - Automatically attracts nearby coins

### Visual Polish
- Particle effects for all actions (jumping, collecting, damage, etc.)
- Power-up visual indicators
- Smooth animations and transitions
- Dynamic lighting and environment

### UI
- Real-time score display
- Health bar with color indicators
- Coin counter
- Power-up status indicators
- Game over screen with high score tracking
- Title screen with controls

## Controls

### Keyboard
- **A** or **Left Arrow** - Move left
- **D** or **Right Arrow** - Move right
- **W** - Move forward (advance row)
- **S** - Move backward (retreat row)
- **Space** - Jump over ground obstacles
- **Shift** - Slide under overhead obstacles

### Gameplay Tips
1. Watch the lane you're in - only obstacles in your lane will hit you
2. Collect coins for maximum points
3. Use power-ups strategically
4. Perfect timing on jumps and slides is key
5. The game gets progressively harder - stay focused!

## Game Systems

### Difficulty Progression
- Spawn intervals decrease every 10 seconds
- More complex obstacle patterns appear at higher difficulties
- Enemy formations vary by progression level

### Scoring
- Distance traveled: 10 points per unit
- Coins collected: 50 points each
- Health potions: 100 points
- Power-ups: 150-200 points
- All bonuses are multiplied by any active multipliers

### Health System
- Start with 100 HP
- Different obstacles deal different damage amounts
- Ground spikes: 20 damage
- Overhead barriers: 15 damage
- Walls: 25 damage
- Health potions restore 30 HP

## Technical Details

### Architecture
- **EndlessRunnerManager** - Main game loop, spawning, and state management
- **RunnerPlayer** - Player controller with movement and collision
- **GroundSystem** - Infinite scrolling ground with visual variety
- **ObstacleTypes** - Modular obstacle creation system
- **Collectibles** - Power-up and pickup system
- **ParticleEffects** - Visual feedback system
- **RunnerUI** - Complete UI with HUD and menus

### Performance
- Object pooling for efficient spawning
- Automatic cleanup of off-screen objects
- Optimized particle systems
- Mobile-ready rendering pipeline

## Development

Built with Godot 4.4 using GDScript.

### Project Structure
```
├── scenes/
│   └── EndlessRunner.tscn       # Main game scene
├── scripts/
│   ├── EndlessRunnerManager.gd  # Game manager
│   ├── RunnerPlayer.gd          # Player controller
│   ├── GroundSystem.gd          # Scrolling ground
│   ├── ObstacleTypes.gd         # Obstacle definitions
│   ├── Collectibles.gd          # Collectible items
│   ├── ParticleEffects.gd       # Visual effects
│   └── RunnerUI.gd              # UI system
└── README.md                     # This file
```

## Future Enhancements

Potential additions for a full release:
- Multiple environments/biomes
- Character customization
- Leaderboards
- Achievements
- More obstacle types
- Boss encounters
- Mobile touch controls
- Sound effects and music
- Procedural environment generation
- Save system for high scores

## License

MIT License - See LICENSE file for details

---

**Have fun running!**
