# Endless Runner 3D Game

A fast-paced 3D endless runner game built with Godot 4.4.1, featuring dynamic 3D hazards, combat encounters, and chiptune music.

## 🎮 Features

### Core Gameplay
- **3D Multi-lane Movement**: Switch between 3 lanes and 4 rows in full 3D space
- **Dynamic 3D Hazards**: Ground spikes, overhead barriers, and enemy markers with 3D meshes
- **Combat System**: Turn-based grid combat when hitting enemy markers
- **Pickup System**: Collect coins, XP, and health potions in 3D space
- **Streak System**: Perfect dodges build multiplier bonuses

### Visual & Audio
- **3D Camera**: Third-person runner camera with optimal viewing angle
- **3D Environment**: Scrolling ground tiles, side walls, and floating elements
- **Health System**: Visual health bar with color-coded status
- **Background Music**: Chiptune soundtrack with volume controls
- **3D Telegraph System**: Hazards pulse and glow before becoming active
- **Material Effects**: Dynamic 3D materials for different hazard types

## 🎯 Controls

### Movement (3D Grid)
- **A/D** or **←/→**: Switch lanes (X-axis)
- **W/S** or **↑/↓**: Move forward/backward in rows (Z-axis)
- **Space**: Jump (avoid ground hazards)
- **Shift**: Slide (avoid overhead hazards)

### Audio Controls
- **M**: Toggle music on/off
- **+/-**: Adjust music volume

## 🏗️ Technical Details

### 3D Architecture
- **CharacterBody3D Player**: Full 3D physics and movement
- **Area3D Hazards**: 3D collision detection with custom meshes
- **3D Materials**: Dynamic StandardMaterial3D with emission effects
- **Camera3D**: Optimized third-person runner camera

### 3D Hazard System
- **Custom 3D Meshes**: Unique shapes for each hazard type
- **3D Telegraph Effects**: Pulsing emission materials
- **3D Collision**: BoxShape3D collision shapes

## 🚀 Getting Started

1. Open in Godot 4.4.1+
2. Run `Main3D.tscn`
3. Enjoy the 3D endless runner experience!

## 🆚 2D vs 3D Comparison

### Advantages of 3D Version:
- **Better Depth Perception**: Easier to judge hazard distances
- **More Immersive**: 3D camera provides better spatial awareness
- **Visual Appeal**: 3D meshes and materials look more modern

### Performance Considerations:
- **Higher GPU Usage**: 3D rendering requires more graphics power
- **Memory Usage**: 3D meshes and materials use more RAM
