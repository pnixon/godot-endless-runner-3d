# 📹 Camera System Guide

> **Complete guide to camera modes, configuration, and implementation for different gameplay styles**

This framework includes a powerful, flexible camera system supporting 5 distinct view modes. This guide covers everything from basic setup to advanced techniques.

---

## 📋 Table of Contents

1. [Camera System Overview](#1-camera-system-overview)
2. [View Modes Explained](#2-view-modes-explained)
3. [Quick Start](#3-quick-start)
4. [Configuration](#4-configuration)
5. [Gameplay Style Presets](#5-gameplay-style-presets)
6. [Advanced Techniques](#6-advanced-techniques)
7. [Camera Effects](#7-camera-effects)
8. [Troubleshooting](#8-troubleshooting)

---

## 1. Camera System Overview

### 1.1 Architecture

The camera system consists of two main components:

**CameraController** (`scripts/camera/CameraController.gd`)
- Manages camera position, rotation, and FOV
- Handles 5 distinct view modes
- Smooth following and transitions
- Camera shake system

**ViewAdapter** (`scripts/camera/ViewAdapter.gd`)
- Adapts gameplay to current view mode
- Adjusts spawn distances and difficulty
- Provides view-specific positioning

### 1.2 Features

✅ **5 View Modes:** First-Person, Third-Person, Top-Down, Side View, Fixed Angle
✅ **Smooth Follow:** Configurable smoothness and response
✅ **Camera Shake:** Impact and intensity-based shaking
✅ **Runtime Switching:** Change views on-the-fly (debug mode)
✅ **Gameplay Adaptation:** View-specific spawn distances and difficulty
✅ **FOV Control:** Per-mode field of view settings
✅ **Customizable:** Fully exposed parameters for tweaking

---

## 2. View Modes Explained

### 2.1 Third-Person (Default)

**Best for:** Standard endless runners, action games, most genres

**Description:** Camera positioned behind and above the player, looking down at a slight angle.

```
     Camera
       |
       | distance (8m)
       |
       v
   ___/_\___  ← Player
     /___\
```

**Specs:**
```gdscript
distance: 8.0 meters behind player
height: 6.0 meters above player
angle: -35 degrees (looking down)
FOV: 70 degrees
```

**Pros:**
- Best overall visibility
- Shows player character
- Natural control feeling
- Great for combat

**Cons:**
- Can't see far ahead
- Obstacles may surprise player

**When to use:**
- Traditional endless runner gameplay
- Combat-focused games
- Character showcasing
- Most general purposes

---

### 2.2 First-Person

**Best for:** Immersive experiences, shooters, exploration

**Description:** Camera positioned at player's eye level, looking forward.

```
   👁️ ← Camera at eye level
   |
   |
  /|\  ← Player body
  / \
```

**Specs:**
```gdscript
height_offset: 1.6 meters (eye level)
forward_offset: 0.3 meters (slight ahead)
FOV: 90 degrees (wider for immersion)
```

**Pros:**
- Maximum immersion
- More challenge/tension
- Good for exploration
- Unique perspective

**Cons:**
- Can't see player character
- Less spatial awareness
- May cause motion sickness
- Harder to judge jumps

**When to use:**
- Horror/suspense themes
- Exploration-focused gameplay
- Shooter-style combat
- Unique/experimental designs

---

### 2.3 Top-Down

**Best for:** Strategy, puzzle, twin-stick shooters

**Description:** Camera positioned high above, looking down at the playfield.

```
         Camera (high above)
            |
            |
            v
      ___________
     |  🎮 Player|
     |     ↓     |  ← Playfield visible
     |___________|
```

**Specs:**
```gdscript
height: 20.0 meters above player
angle: -60 degrees (steep downward)
FOV: 60 degrees
```

**Pros:**
- See entire playfield
- Strategic overview
- Easy to plan routes
- Clear obstacle visibility

**Cons:**
- Less immersive
- Player appears small
- Less vertical information
- Can feel distant

**When to use:**
- Puzzle/strategy elements
- Complex lane patterns
- Tactical gameplay
- Twin-stick shooter style

---

### 2.4 Side View

**Best for:** Platformers, 2.5D games, classic arcade feel

**Description:** Camera positioned to the side, creating a 2.5D perspective.

```
      [Camera]
         ↓

    🎮 Player → Running forward
    ___________  ← Ground

    (Side perspective)
```

**Specs:**
```gdscript
distance: 15.0 meters to the side
height: 3.0 meters above ground
FOV: 50 degrees
```

**Pros:**
- Clear jump/height info
- Classic platformer feel
- Easy to judge distances
- Nostalgic appeal

**Cons:**
- Limited lane visibility
- Depth perception harder
- Less modern feel

**When to use:**
- Platformer-style gameplay
- Retro/classic aesthetic
- Jump-focused mechanics
- Simple lane system

---

### 2.5 Fixed Angle

**Best for:** Arcade games, specific cinematics, scripted sequences

**Description:** Camera stays at a fixed position and angle, doesn't follow player.

```
    [Camera - Fixed Position]
         ↓

    🎮 ← Player moves through view

    (Classic arcade style)
```

**Specs:**
```gdscript
position: Vector3(0, 12, 10) (customizable)
rotation: Vector3(-45, 0, 0) (customizable)
FOV: 65 degrees
```

**Pros:**
- Cinematic control
- Classic arcade feel
- Predictable framing
- Good for specific challenges

**Cons:**
- Player can leave view
- Less dynamic
- Requires careful design

**When to use:**
- Specific challenge sections
- Cinematic moments
- Boss battles (fixed arena)
- Arcade-style gameplay

---

## 3. Quick Start

### 3.1 Basic Setup

#### Option 1: Auto-Setup (ConfigurableGameManager)

```gdscript
# ConfigurableGameManager auto-creates camera
# Just configure view mode in inspector or code

extends ConfigurableGameManager

func _ready():
    super._ready()  # Creates camera automatically

    # Change view mode
    camera_controller.set_view_mode(CameraController.ViewMode.THIRD_PERSON)
```

#### Option 2: Manual Setup

```gdscript
# In your game manager or player scene
var camera_controller = CameraController.new()
camera_controller.name = "CameraController"
camera_controller.target = player  # Set player as target
camera_controller.view_mode = CameraController.ViewMode.THIRD_PERSON
add_child(camera_controller)
```

#### Option 3: Scene Setup

1. Add `CameraController` node to your scene
2. In inspector, set `Target` to your player node
3. Choose `View Mode` from dropdown
4. Adjust parameters as needed

### 3.2 Minimal Example

```gdscript
extends Node3D

func _ready():
    # Create player
    var player = CharacterBody3D.new()
    player.name = "Player"
    add_child(player)

    # Create camera
    var camera = CameraController.new()
    camera.target = player
    camera.view_mode = CameraController.ViewMode.THIRD_PERSON
    add_child(camera)

    # Done! Camera follows player
```

---

## 4. Configuration

### 4.1 View Mode Properties

Each view mode has specific configurable properties:

#### Third-Person Settings

```gdscript
@export_group("Third Person Settings")
@export var third_person_distance: float = 8.0        # Distance behind
@export var third_person_height: float = 6.0          # Height above
@export var third_person_angle: float = -35.0         # Look down angle
@export var third_person_fov: float = 70.0            # Field of view

# In script
camera_controller.third_person_distance = 10.0  # Farther back
camera_controller.third_person_height = 8.0     # Higher up
camera_controller.third_person_angle = -25.0    # Less steep angle
```

#### First-Person Settings

```gdscript
@export_group("First Person Settings")
@export var first_person_height_offset: float = 1.6   # Eye level
@export var first_person_forward_offset: float = 0.3  # Slight ahead
@export var first_person_fov: float = 90.0            # Wide FOV

# In script
camera_controller.first_person_height_offset = 1.8  # Taller character
camera_controller.first_person_fov = 100.0          # Wider view
```

#### Top-Down Settings

```gdscript
@export_group("Top Down Settings")
@export var top_down_height: float = 20.0             # How high above
@export var top_down_angle: float = -60.0             # Look down angle
@export var top_down_fov: float = 60.0                # Field of view

# In script
camera_controller.top_down_height = 30.0   # Higher for more view
camera_controller.top_down_angle = -70.0   # Steeper angle
```

#### Side View Settings

```gdscript
@export_group("Side View Settings")
@export var side_view_distance: float = 15.0          # Distance to side
@export var side_view_height: float = 3.0             # Height above ground
@export var side_view_fov: float = 50.0               # Field of view

# In script
camera_controller.side_view_distance = 12.0  # Closer side view
camera_controller.side_view_height = 4.0     # Higher perspective
```

#### Fixed Angle Settings

```gdscript
@export_group("Fixed Angle Settings")
@export var fixed_angle_position: Vector3 = Vector3(0, 12, 10)
@export var fixed_angle_rotation: Vector3 = Vector3(-45, 0, 0)
@export var fixed_angle_fov: float = 65.0

# In script
camera_controller.fixed_angle_position = Vector3(5, 15, 15)
camera_controller.fixed_angle_rotation = Vector3(-30, 15, 0)
```

### 4.2 General Camera Settings

```gdscript
# Smoothness (higher = more responsive, lower = smoother)
camera_controller.follow_smoothness = 10.0

# Enable smooth rotation transitions
camera_controller.smooth_rotation = true

# Enable camera shake
camera_controller.enable_shake = true
```

### 4.3 Runtime View Switching

```gdscript
# Change view mode at runtime
func change_view(new_view: CameraController.ViewMode):
    camera_controller.set_view_mode(new_view)

# Cycle through all modes
func cycle_view():
    camera_controller.cycle_view_mode()

# Check current mode
func get_current_view() -> CameraController.ViewMode:
    return camera_controller.view_mode
```

**Debug Shortcut:**
In debug builds, press **V** to cycle through view modes for testing.

---

## 5. Gameplay Style Presets

The camera controller includes preset configurations optimized for different gameplay styles.

### 5.1 Using Presets

```gdscript
# Apply a preset configuration
camera_controller.configure_for_gameplay_style("runner")
```

### 5.2 Available Presets

#### "runner" - Default Endless Runner
```gdscript
view_mode: THIRD_PERSON
distance: 8.0
height: 6.0
angle: -35.0
```
Perfect for: Temple Run, Subway Surfers style games

#### "racing" - Racing Game
```gdscript
view_mode: THIRD_PERSON
distance: 12.0
height: 5.0
angle: -25.0
follow_smoothness: 15.0  # More responsive
```
Perfect for: Kart racers, racing games

#### "platformer" - 2.5D Platformer
```gdscript
view_mode: SIDE_VIEW
distance: 15.0
height: 3.0
```
Perfect for: Classic platformers, side-scrollers

#### "shooter" - First-Person Shooter
```gdscript
view_mode: FIRST_PERSON
fov: 90.0
```
Perfect for: FPS games, immersive combat

#### "strategy" - Top-Down Strategy
```gdscript
view_mode: TOP_DOWN
height: 25.0
angle: -70.0
```
Perfect for: Strategy games, puzzle games, twin-stick shooters

### 5.3 Custom Presets

Create your own preset:

```gdscript
func configure_for_horror_game():
    camera_controller.set_view_mode(CameraController.ViewMode.FIRST_PERSON)
    camera_controller.first_person_fov = 75.0  # Narrower, more tense
    camera_controller.follow_smoothness = 5.0   # Slower, heavier feel
    camera_controller.enable_shake = true       # Impact shake

func configure_for_bullet_hell():
    camera_controller.set_view_mode(CameraController.ViewMode.TOP_DOWN)
    camera_controller.top_down_height = 30.0
    camera_controller.top_down_angle = -80.0     # Nearly straight down
    camera_controller.top_down_fov = 55.0        # Focused view
```

---

## 6. Advanced Techniques

### 6.1 Dynamic Camera Adjustment

Adjust camera based on game state:

```gdscript
func _process(delta):
    # Zoom out when going fast
    if player.velocity.length() > 20.0:
        camera_controller.third_person_distance = lerp(
            camera_controller.third_person_distance,
            12.0,  # Farther when fast
            delta * 2.0
        )
    else:
        camera_controller.third_person_distance = lerp(
            camera_controller.third_person_distance,
            8.0,   # Normal distance
            delta * 2.0
        )

    # Look ahead when in combat
    if in_combat:
        camera_controller.third_person_angle = lerp(
            camera_controller.third_person_angle,
            -20.0,  # Less steep, see ahead
            delta * 3.0
        )
```

### 6.2 Camera Zones

Change camera behavior in specific zones:

```gdscript
# In zone script
extends Area3D

@export var zone_view_mode: CameraController.ViewMode = CameraController.ViewMode.SIDE_VIEW
@export var zone_camera_distance: float = 15.0

func _on_player_entered(body):
    if body.is_in_group("player"):
        var camera = get_tree().get_first_node_in_group("camera")
        if camera:
            camera.set_view_mode(zone_view_mode)
            camera.side_view_distance = zone_camera_distance

func _on_player_exited(body):
    if body.is_in_group("player"):
        var camera = get_tree().get_first_node_in_group("camera")
        if camera:
            # Restore default
            camera.set_view_mode(CameraController.ViewMode.THIRD_PERSON)
```

### 6.3 Cinematic Cameras

Create dramatic camera moments:

```gdscript
func boss_intro_camera():
    # Save current settings
    var original_mode = camera_controller.view_mode
    var original_target = camera_controller.target

    # Fixed angle looking at boss
    camera_controller.set_view_mode(CameraController.ViewMode.FIXED_ANGLE)
    camera_controller.fixed_angle_position = boss.global_position + Vector3(5, 8, 10)
    camera_controller.look_at_target(boss)

    # Wait for dramatic effect
    await get_tree().create_timer(3.0).timeout

    # Restore normal camera
    camera_controller.set_view_mode(original_mode)
    camera_controller.target = original_target
```

### 6.4 Camera Interpolation

Smooth transitions between configurations:

```gdscript
func smooth_transition_to_top_down(duration: float = 2.0):
    var start_height = camera_controller.global_position.y
    var target_height = 20.0

    var tween = create_tween()
    tween.tween_method(
        func(value):
            camera_controller.global_position.y = value,
        start_height,
        target_height,
        duration
    )
    tween.parallel().tween_property(
        camera_controller,
        "rotation_degrees:x",
        -60.0,
        duration
    )

    await tween.finished
    camera_controller.set_view_mode(CameraController.ViewMode.TOP_DOWN)
```

### 6.5 Look-Ahead Camera

Camera looks ahead of player movement:

```gdscript
extends CameraController

var look_ahead_distance: float = 5.0

func update_third_person(delta: float):
    # Base position
    target_position = target.global_position
    target_position.y += third_person_height
    target_position.z += third_person_distance

    # Add look-ahead based on velocity
    if target is CharacterBody3D:
        var velocity_forward = target.velocity.normalized()
        target_position += velocity_forward * look_ahead_distance

    # Continue with normal update
    global_position = global_position.lerp(target_position, follow_smoothness * delta)
```

---

## 7. Camera Effects

### 7.1 Camera Shake

Built-in shake system for impact and intensity:

```gdscript
# Basic shake
camera_controller.trigger_shake(0.3, 0.2)  # intensity, duration

# On player hit
func _on_player_hit():
    camera_controller.trigger_shake(0.5, 0.3)  # Medium shake

# On explosion
func _on_explosion():
    camera_controller.trigger_shake(1.0, 0.5)  # Big shake
```

**Customizing Shake:**
```gdscript
# In CameraController script
@export var shake_decay: float = 5.0  # How fast shake fades

# For trauma-based shake (more realistic)
var trauma: float = 0.0
var max_trauma: float = 1.0

func add_trauma(amount: float):
    trauma = min(trauma + amount, max_trauma)

func _process(delta):
    if trauma > 0:
        trauma = max(trauma - delta * shake_decay, 0)

        # Apply shake based on trauma squared (smoother falloff)
        var shake_amount = trauma * trauma
        camera.rotation_degrees.z = 10.0 * shake_amount * randf_range(-1, 1)
        camera.position.x = 0.5 * shake_amount * randf_range(-1, 1)
```

### 7.2 FOV Kick

Change FOV for impact:

```gdscript
func fov_kick(amount: float, duration: float):
    var original_fov = camera_controller.camera.fov

    var tween = create_tween()
    tween.tween_property(camera_controller.camera, "fov", original_fov + amount, duration * 0.5)
    tween.tween_property(camera_controller.camera, "fov", original_fov, duration * 0.5)

# On jump
func _on_jump():
    fov_kick(10.0, 0.3)  # Expand FOV briefly

# On landing
func _on_land():
    fov_kick(-5.0, 0.2)  # Contract FOV
```

### 7.3 Slow Motion

Slow down time with adapted camera:

```gdscript
func slow_motion(duration: float = 2.0, time_scale: float = 0.3):
    # Slow down time
    Engine.time_scale = time_scale

    # Increase camera smoothness for dramatic effect
    var original_smoothness = camera_controller.follow_smoothness
    camera_controller.follow_smoothness = 3.0

    await get_tree().create_timer(duration, true, false, true).timeout

    # Restore
    Engine.time_scale = 1.0
    camera_controller.follow_smoothness = original_smoothness
```

### 7.4 Depth of Field

Add cinematic depth of field blur:

```gdscript
func enable_depth_of_field():
    var camera_attributes = CameraAttributesPractical.new()
    camera_attributes.dof_blur_far_enabled = true
    camera_attributes.dof_blur_far_distance = 20.0
    camera_attributes.dof_blur_far_transition = 10.0

    camera_controller.camera.attributes = camera_attributes
```

---

## 8. Troubleshooting

### 8.1 Common Issues

#### Camera is not following player

**Solution:**
```gdscript
# Ensure target is set
camera_controller.target = player

# Check camera is in scene tree
add_child(camera_controller)

# Verify camera controller is processing
camera_controller.set_process(true)
```

#### Camera is jittery/stuttering

**Solution:**
```gdscript
# Increase smoothness
camera_controller.follow_smoothness = 15.0

# Or use physics interpolation
camera_controller.set_physics_process(true)

func _physics_process(delta):
    update_camera_position(delta)
```

#### Player not visible in first-person

**Solution:**
```gdscript
# This is expected in first-person mode
# To see player body, adjust camera offset:
camera_controller.first_person_height_offset = 1.2  # Lower, see shoulders
```

#### Wrong orientation/rotation

**Solution:**
```gdscript
# Check player forward direction
# Ensure player is facing negative Z
# Adjust rotation in camera update functions
```

#### Camera going through walls

**Solution:**
```gdscript
# Add raycasting to detect obstacles
func _process(delta):
    var desired_position = calculate_camera_position()

    # Raycast from player to camera
    var space_state = get_world_3d().direct_space_state
    var query = PhysicsRayQueryParameters3D.create(
        player.global_position,
        desired_position
    )
    var result = space_state.intersect_ray(query)

    if result:
        # Hit something, move camera closer
        camera.global_position = result.position
    else:
        camera.global_position = desired_position
```

### 8.2 Performance Issues

#### Camera updates causing lag

**Solution:**
```gdscript
# Reduce update frequency
var camera_update_interval = 0.0
const CAMERA_UPDATE_RATE = 1.0 / 30.0  # 30 FPS updates

func _process(delta):
    camera_update_interval += delta
    if camera_update_interval >= CAMERA_UPDATE_RATE:
        update_camera_position(camera_update_interval)
        camera_update_interval = 0.0
```

#### Too many calculations

**Solution:**
```gdscript
# Cache frequently used values
@onready var cached_target_position: Vector3
var cache_update_timer: float = 0.0

func _process(delta):
    cache_update_timer += delta

    if cache_update_timer >= 0.1:  # Update cache every 0.1s
        cached_target_position = target.global_position
        cache_update_timer = 0.0

    # Use cached value instead of querying every frame
    var distance_to_target = global_position.distance_to(cached_target_position)
```

### 8.3 Design Issues

#### Can't see obstacles in time

**Solution:**
```gdscript
# Increase spawn distance based on camera view
if camera_controller.view_mode == CameraController.ViewMode.FIRST_PERSON:
    spawn_distance = 60.0  # Farther for FP
elif camera_controller.view_mode == CameraController.ViewMode.THIRD_PERSON:
    spawn_distance = 45.0  # Standard for TP

# Or use ViewAdapter
var adjusted_distance = view_adapter.get_spawn_distance()
```

#### Camera feels too slow/fast

**Solution:**
```gdscript
# Adjust smoothness
camera_controller.follow_smoothness = 10.0  # Default
# Lower = smoother but slower (5.0)
# Higher = more responsive (15.0)

# Or adjust for action
if in_intense_action:
    camera_controller.follow_smoothness = 20.0  # Snappy
else:
    camera_controller.follow_smoothness = 8.0   # Smooth
```

---

## Conclusion

The camera system is one of the most important parts of your game's feel. Experiment with different modes and settings to find what works best for your specific game.

### Quick Reference

```gdscript
# Common camera operations

# Set view mode
camera_controller.set_view_mode(CameraController.ViewMode.THIRD_PERSON)

# Apply preset
camera_controller.configure_for_gameplay_style("runner")

# Trigger shake
camera_controller.trigger_shake(0.5, 0.3)

# Look at target
camera_controller.look_at_target(enemy)

# Cycle modes (debug)
camera_controller.cycle_view_mode()

# Check visibility
var visible = camera_controller.is_position_visible(enemy.global_position)
```

### Recommended Settings by Genre

| Genre | View Mode | Distance | Height | FOV | Smoothness |
|-------|-----------|----------|--------|-----|------------|
| Endless Runner | Third-Person | 8.0 | 6.0 | 70 | 10.0 |
| Platformer | Side View | 15.0 | 3.0 | 50 | 8.0 |
| Combat Arena | Third-Person | 10.0 | 8.0 | 75 | 12.0 |
| Puzzle | Top-Down | 25.0 | - | 60 | 6.0 |
| Horror | First-Person | - | 1.6 | 75 | 5.0 |

---

**Next Steps:**
- Try different modes in your game
- Tweak settings to match your design
- Read [PRODUCTION_GUIDE.md](./PRODUCTION_GUIDE.md) for full implementation
- Check [ART_ASSET_GUIDE.md](./ART_ASSET_GUIDE.md) for visual polish

**Happy filming! 📹✨**
