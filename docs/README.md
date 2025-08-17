# 🎮 Godot 4 Endless Runner 3D

**Ultra-responsive 3D endless runner with lane-based movement, dynamic hazards, and chiptune soundtrack**

![Godot 4](https://img.shields.io/badge/Godot-4.x-blue.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)
![Platform](https://img.shields.io/badge/Platform-Cross--Platform-orange.svg)

## 🚀 Features

### 🎯 **Ultra-Crunchy Gameplay**
- **Lane-based movement** - Precise 3-lane system with smooth interpolation
- **Grid movement** - Forward/backward between 4 rows for tactical positioning
- **Ultra-snappy jumps** - 0.3s duration with heavy gravity for arcade feel
- **Visual sliding** - Player crouches to avoid overhead hazards
- **Perfect collision detection** - Lane-based validation prevents false hits

### 🎵 **Dynamic Audio System**
- **Random music selection** - Different chiptune track each playthrough
- **4 chiptune tracks** included for variety
- **Runtime track switching** - Press N to change music anytime
- **Seamless looping** - Continuous background music

### 🎪 **Smart Hazard System**
- **Ground Spikes** (Red) - Jump to avoid, positioned at ground level
- **Overhead Barriers** (Orange) - Duck/slide to avoid, positioned at head level
- **Pickups** - Coins, XP, and health potions at chest level
- **Height-based mechanics** - Intuitive avoidance based on hazard position

### 🎮 **Responsive Controls**
- **WASD** - Lane switching and row movement
- **Space** - Jump over ground hazards
- **Shift** - Slide under overhead barriers
- **M** - Toggle music, **+/-** - Volume, **N** - Next track

## 🎯 **Gameplay Mechanics**

### Movement System
```
Lanes (X-axis):  [-3.0, 0.0, 3.0]  # Left, Center, Right
Rows (Z-axis):   [3.0, 1.0, -1.0, -3.0]  # Back to Front
```

### Hazard Positioning
- **Ground Spikes**: Y = 0.2 (ground level) - **Jump to avoid**
- **Overhead Barriers**: Y = 2.5 (head level) - **Slide to avoid**
- **Pickups**: Y = 1.5 (chest level) - **Run through to collect**

### Physics
- **Ultra-heavy gravity** (3.5x default) for non-floaty jumps
- **Smooth movement** (20.0 lerp speed) for fluid positioning
- **Precise collision** (0.8x1.8x0.8 player box) for fair gameplay

## 🛠️ **Technical Details**

### Built With
- **Godot 4.x** - Modern game engine
- **GDScript** - Native scripting language
- **3D Physics** - CharacterBody3D with custom movement
- **Dynamic Audio** - MP3 streaming with random selection

### Architecture
- **Modular design** - Separate scripts for player, hazards, and game management
- **Event-driven** - Signal-based communication between systems
- **Scalable spawning** - Dynamic difficulty and hazard generation
- **Clean separation** - Audio, input, and gameplay systems isolated

### Performance
- **Efficient collision** - Minimal collision shapes for performance
- **Smart spawning** - Objects cleaned up automatically
- **Optimized rendering** - Simple meshes for smooth gameplay
- **Memory conscious** - Audio loaded on-demand

## 🎮 **Controls**

### Movement
- **A/D** - Switch lanes (left/right)
- **W/S** - Move between rows (forward/back)
- **Space** - Jump (avoid ground spikes)
- **Shift** - Slide/Duck (avoid overhead barriers)

### Audio
- **M** - Toggle music on/off
- **+/-** - Volume up/down
- **N** - Next random track

### Game
- **A/D** - Restart when game over

## 🎵 **Soundtrack**

Includes 4 high-energy chiptune tracks:
- **"chiptunes awesomeness.mp3"** - Energetic action theme
- **"chiptunes awesomeness 2.mp3"** - Alternative action track
- **"the brass and the blade (Remix) chiptunes.mp3"** - Epic remix
- **"background_music.mp3"** - Original theme

## 🚀 **Getting Started**

### Prerequisites
- **Godot 4.x** - Download from [godotengine.org](https://godotengine.org/)

### Installation
1. **Clone the repository**
   ```bash
   git clone https://github.com/pnixon/godot-endless-runner-3d.git
   cd godot-endless-runner-3d
   ```

2. **Open in Godot**
   - Launch Godot 4
   - Click "Import"
   - Navigate to project folder
   - Select `project.godot`

3. **Play**
   - Press F5 or click Play
   - Select `Main3D.tscn` as main scene

## 🎯 **Game Features**

### Difficulty Progression
- **Dynamic spawning** - Hazards spawn faster over time
- **Biome system** - Different hazard types in different areas
- **Score multipliers** - Reward skillful play
- **Health system** - Take damage from hazards, collect health potions

### Visual Feedback
- **Movement effects** - Visual indicators for player actions
- **Health/Stamina bars** - Clear UI feedback
- **Collision debugging** - Console output for development
- **Smooth animations** - Interpolated movement and scaling

### Audio Experience
- **Spatial audio** - 3D positioned sound effects
- **Dynamic music** - Random selection keeps gameplay fresh
- **Volume controls** - Player-adjustable audio levels
- **Seamless loops** - Continuous background music

## 🔧 **Development**

### Project Structure
```
endless_runner_3d/
├── Main3D.tscn              # Main game scene
├── Player3D.gd              # Player controller
├── GameManager3D.gd         # Game logic and spawning
├── EnhancedObstacle3D.gd    # Hazard system
├── HazardData.gd            # Hazard definitions
├── *.mp3                    # Chiptune soundtrack
└── README.md                # This file
```

### Key Systems
- **Player3D.gd** - Movement, collision, abilities
- **GameManager3D.gd** - Spawning, scoring, audio
- **EnhancedObstacle3D.gd** - Hazard behavior and rendering
- **HazardData.gd** - Hazard type definitions and factory methods

## 🎮 **Gameplay Tips**

### Mastering Movement
- **Plan ahead** - Look for hazard patterns
- **Use all lanes** - Don't stay in center lane
- **Row positioning** - Use front/back rows tactically
- **Combo movements** - Chain lane switches with jumps/slides

### Hazard Strategy
- **Red spikes** - Always jump, positioned on ground
- **Orange barriers** - Always slide, positioned overhead
- **Yellow pickups** - Run through for coins and XP
- **Green potions** - Collect for health restoration

### Advanced Techniques
- **Perfect timing** - Jump/slide at last moment for style points
- **Lane management** - Keep escape routes open
- **Audio cues** - Use music rhythm for timing
- **Visual scanning** - Look ahead for hazard combinations

## 🤝 **Contributing**

Contributions welcome! Areas for improvement:
- **New hazard types** - More variety in obstacles
- **Power-ups** - Temporary abilities and boosts
- **Visual effects** - Particles and screen effects
- **More music** - Additional chiptune tracks
- **Difficulty modes** - Easy/Normal/Hard settings

## 📝 **License**

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🎵 **Credits**

- **Game Engine**: Godot 4.x
- **Music**: Chiptune tracks (various artists)
- **Development**: Built with ❤️ for arcade gaming fans

---

**Ready to run? Jump in and experience ultra-responsive 3D endless runner action!** 🎮🚀
