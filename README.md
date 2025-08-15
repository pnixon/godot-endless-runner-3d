# Endless Runner Game

A fast-paced endless runner game built with Godot 4.4.1, featuring dynamic hazards, combat encounters, and chiptune music.

## 🎮 Features

### Core Gameplay
- **Multi-lane Movement**: Switch between 3 lanes and 4 rows for complex positioning
- **Dynamic Hazards**: Ground spikes, overhead barriers, and enemy markers
- **Combat System**: Turn-based grid combat when hitting enemy markers
- **Pickup System**: Collect coins, XP, and health potions
- **Streak System**: Perfect dodges build multiplier bonuses

### Visual & Audio
- **Zoomed Camera**: Enhanced view for better hazard anticipation
- **Health System**: Visual health bar with color-coded status
- **Background Music**: Chiptune soundtrack with volume controls
- **Telegraph System**: Hazards flash before becoming active
- **Special Effects**: Unique visuals for different hazard types

### Progression
- **Biome System**: 3 different biomes with varying difficulty
- **Dynamic Difficulty**: Hazard spawn rates increase over time
- **Score System**: Points, coins, and XP tracking
- **Health Potions**: Rare healing items spawn based on biome

## 🎯 Controls

### Movement
- **A/D** or **←/→**: Switch lanes
- **W** or **↑**: Hop (avoid ground hazards)
- **S** or **↓**: Slide (avoid overhead hazards)

### Audio Controls
- **M**: Toggle music on/off
- **+/-**: Adjust music volume

### Debug Controls
- **H**: Show health bar debug info
- **T**: Test damage (10 HP)
- **Y**: Test healing (10 HP)

## 🏗️ Technical Details

### Architecture
- **Modular Design**: Separate systems for hazards, combat, audio, and UI
- **Object Pooling**: Efficient hazard spawning and cleanup
- **Signal-based Communication**: Decoupled component interactions
- **Dynamic Camera**: Smooth following with anticipation offset

### Hazard System
- **HazardData**: Centralized hazard configuration
- **EnhancedObstacle**: Advanced hazard behavior with telegraphing
- **Biome Weights**: Configurable spawn probabilities per biome

### Combat System
- **Grid-based Combat**: 3x4 tactical combat grid
- **Formation System**: Predefined enemy formations per biome
- **Turn-based Logic**: Player and enemy action phases

## 📁 Project Structure

```
endless_runner/
├── *.gd                    # Core game scripts
├── *.tscn                  # Scene files
├── background_music.mp3    # Chiptune soundtrack
├── wizard_variation_01_00001_.png  # Player sprite
└── .godot/                 # Godot engine files (ignored)
```

### Key Scripts
- **GameManager.gd**: Main game loop, spawning, and state management
- **Player.gd**: Player movement, health, and input handling
- **EnhancedObstacle.gd**: Advanced hazard behavior
- **HazardData.gd**: Hazard type definitions and factory methods
- **CombatGrid.gd**: Turn-based combat system

## 🚀 Getting Started

### Prerequisites
- Godot 4.4.1 or later
- Git (for cloning)

### Installation
1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd endless_runner
   ```

2. Open in Godot:
   - Launch Godot Engine
   - Click "Import"
   - Navigate to the project folder
   - Select `project.godot`

3. Run the game:
   - Press F5 or click the play button
   - Select `Main.tscn` as the main scene if prompted

## 🎵 Audio

The game features a chiptune soundtrack ("the brass and the blade (Remix)") that loops continuously. Music controls are available during gameplay for volume adjustment and toggling.

## 🏆 Gameplay Tips

1. **Perfect Timing**: Wait for hazards to telegraph before moving
2. **Health Management**: Collect health potions when your HP is low
3. **Streak Building**: Perfect dodges increase your score multiplier
4. **Combat Strategy**: Position yourself strategically in the combat grid
5. **Biome Awareness**: Later biomes have fewer health potions and harder enemies

## 🔧 Development

### Adding New Hazards
1. Add new type to `HazardType` enum in `HazardData.gd`
2. Create factory method in `HazardData.gd`
3. Add handling in `EnhancedObstacle.gd` and `Player.gd`
4. Update biome spawn weights in `GameManager.gd`

### Modifying Combat
- Edit formations in `CombatGrid.gd`
- Adjust enemy stats and abilities
- Add new attack patterns

### Audio Customization
- Replace `background_music.mp3` with your own track
- Adjust volume levels in `GameManager.gd`
- Add sound effects through the sound system

## 📝 License

This project is open source. Feel free to modify and distribute.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues for bugs and feature requests.

## 🎮 Credits

- Built with Godot Engine 4.4.1
- Chiptune music: "the brass and the blade (Remix)"
- Wizard sprite assets included
