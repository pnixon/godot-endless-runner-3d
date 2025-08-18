# Combat Feedback and Timing System

## Overview

The Combat Feedback and Timing System provides comprehensive visual, audio, and screen effects for combat actions in the RPG. It includes a combo system that rewards consecutive successful dodges and attacks, perfect timing mechanics, and immersive feedback for all combat interactions.

## Features

### 1. Visual Feedback System
- **Dodge Effects**: Different visual effects for regular vs perfect dodges
- **Block Effects**: Shield-like visual effects with enhanced feedback for perfect blocks
- **Perfect Timing Effects**: Special glowing ring effects for perfect actions
- **Combo Effects**: Escalating particle effects that grow with combo count
- **Invincibility Effects**: Pulsing cyan effect during invincibility frames

### 2. Screen Effects
- **Screen Shake**: Dynamic camera shake with varying intensity based on action type
- **Slow Motion**: Time dilation effect triggered by perfect dodges (30% speed for 0.8s)
- **Screen Flash**: Full-screen color flashes for critical moments (gold for perfect timing)
- **Enhanced Effects**: Stronger effects for boss attacks and high combos

### 3. Audio Feedback
- **Action Sounds**: Distinct audio cues for different combat actions
- **Perfect Timing Audio**: Special sounds for perfect dodges and blocks
- **Combo Audio**: Escalating audio feedback as combos build
- **Pitch Variation**: Slight pitch randomization to prevent repetition

### 4. Combo System
- **Combo Types**: Dodge, Block, Attack, and Mixed combos
- **Multiplier System**: Combo multiplier increases with consecutive actions (max 5.0x)
- **Combo Window**: 3-second window to extend combos
- **Bonus Rewards**: XP bonuses based on combo count and multiplier
- **Visual Escalation**: Enhanced effects for combos of 5+ and 10+

### 5. Perfect Timing Mechanics
- **Perfect Dodge Window**: 0.2-second window for perfect timing
- **Perfect Block Window**: 0.3-second window for perfect blocks
- **Streak Tracking**: Consecutive perfect actions increase bonuses
- **Enhanced Rewards**: Perfect actions grant bonus XP and enhanced effects

## Usage

### Integration with Combat Controller

The system automatically integrates with the existing `CombatController`:

```gdscript
# The feedback system is automatically created and connected
var feedback_system = CombatFeedbackSystem.new()
add_child(feedback_system)
```

### Key Methods

```gdscript
# Trigger screen effects
feedback_system.trigger_screen_shake(intensity, duration)
feedback_system.trigger_slow_motion(duration, time_scale)
feedback_system.trigger_screen_flash(intensity, duration, color)

# Play combat sounds
feedback_system.play_combat_sound("dodge_success", volume)

# Combo system
feedback_system.get_current_combo_count()
feedback_system.get_current_combo_multiplier()
feedback_system.force_break_combo()
```

### Signal Connections

The system emits several signals for external integration:

```gdscript
signal combo_started(combo_type: String)
signal combo_extended(combo_count: int, multiplier: float)
signal combo_broken(final_count: int, final_multiplier: float)
signal perfect_timing_achieved(action_type: String, bonus: int)
signal screen_effect_triggered(effect_type: String, intensity: float)
```

## Testing

### Debug Controls (F-Keys)
- **F1**: Test basic dodge
- **F2**: Test perfect dodge
- **F3**: Test block feedback
- **F4**: Test combo system
- **F5**: Test screen effects
- **F6**: Test audio feedback
- **F7**: Debug feedback system
- **F8**: Run full test sequence

### Player Controls (P, O, I, U Keys)
- **P**: Test perfect dodge with timing
- **O**: Test perfect block
- **I**: Test combo system with multiple actions
- **U**: Debug feedback system state

### Automatic Testing

The system includes an automated test script (`test_combat_feedback.gd`) that runs in debug builds:

```gdscript
# Automatically added in GameManager3D._ready() when OS.is_debug_build()
var feedback_test = preload("res://test_combat_feedback.gd").new()
```

## Configuration

### Combo System Settings
```gdscript
var combo_window: float = 3.0  # Time window to extend combo
var max_combo_multiplier: float = 5.0  # Maximum combo multiplier
```

### Screen Effects Settings
```gdscript
var perfect_dodge_slow_motion: float = 0.3  # 30% speed
var slow_motion_duration: float = 0.8  # 0.8 seconds
```

### Audio Settings
```gdscript
# Combat sounds are loaded from audio directory
# Uses existing audio files as placeholders
var combat_sounds: Dictionary = {
    "dodge_success": "chiptunes awesomeness.mp3",
    "dodge_perfect": "chiptunes awesomeness 2.mp3",
    # ... more sounds
}
```

## Visual Effects Details

### Perfect Dodge Effect
- **Visual**: Golden glowing ring that expands and rotates
- **Duration**: 0.5 seconds
- **Animation**: Scale from 0.8 to 2.0, rotate 360 degrees, fade out

### Combo Effects
- **Particle Count**: Scales with combo count (max 10 particles)
- **Colors**: Green → Red gradient based on combo intensity
- **Animation**: Particles spiral outward and upward, fading over time

### Screen Shake
- **Intensity**: Varies by action type (0.05 for failed actions, 0.3 for boss attacks)
- **Camera Offset**: Random X/Y displacement within intensity bounds
- **Recovery**: Smooth return to original position over duration

### Slow Motion
- **Engine Integration**: Uses `Engine.time_scale` for global time dilation
- **Trigger Conditions**: Perfect dodges, high combos (10+)
- **Audio Cue**: Special slow motion sound effect

## Performance Considerations

### Effect Cleanup
- Automatic cleanup of expired visual effects
- Weak references to prevent memory leaks
- Efficient tween management

### Audio Optimization
- Single AudioStreamPlayer for all combat sounds
- Pitch variation to prevent audio repetition
- Volume scaling based on action importance

### Screen Effect Limits
- Maximum shake intensity capping
- Time scale restoration on scene exit
- Effect duration limits to prevent abuse

## Integration with Requirements

This system fulfills the following task requirements:

1. ✅ **Visual feedback system** for successful dodges, blocks, and perfect timing
2. ✅ **Screen effects** for critical moments (slow-motion, screen shake)
3. ✅ **Audio feedback** with distinct sounds for different combat actions
4. ✅ **Combo system** that rewards consecutive successful actions

The system integrates seamlessly with the existing combat mechanics while providing rich, responsive feedback that enhances the player experience and makes combat feel impactful and rewarding.