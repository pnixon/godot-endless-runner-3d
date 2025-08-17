# Mobile Input System Documentation

## Overview

The mobile input system provides touch gesture recognition, haptic feedback, and mobile-optimized UI scaling for the Android version of Legends of Aetherion.

## Components

### MobileInputManager
- **Location**: `scripts/MobileInputManager.gd`
- **Purpose**: Handles touch gesture recognition and converts them to game actions
- **Features**:
  - Multi-touch gesture detection
  - Configurable sensitivity settings
  - Support for swipes, taps, long press, and multi-finger gestures

### HapticController
- **Location**: `scripts/HapticController.gd`
- **Purpose**: Manages device vibration patterns for tactile feedback
- **Features**:
  - Predefined haptic patterns for different game events
  - Intensity and duration control
  - Platform-specific vibration support

### MobileUIManager
- **Location**: `scripts/MobileUIManager.gd`
- **Purpose**: Handles UI scaling and screen adaptation for mobile devices
- **Features**:
  - Automatic UI scaling based on screen size and DPI
  - Safe area detection for devices with notches
  - Orientation change handling
  - Touch-friendly button sizing

### MobileInputBridge
- **Location**: `scripts/MobileInputBridge.gd`
- **Purpose**: Connects mobile gestures to existing game input actions
- **Features**:
  - Gesture-to-action mapping
  - Haptic feedback integration
  - Backward compatibility with keyboard controls

## Gesture Mapping

| Gesture | Game Action | Haptic Feedback |
|---------|-------------|-----------------|
| Swipe Left | Move Left / Lane Switch | Medium Bump |
| Swipe Right | Move Right / Lane Switch | Medium Bump |
| Swipe Up | Jump | Light Tap |
| Swipe Down | Slide | Light Tap |
| Tap | Attack | Light Tap |
| Long Press | Special Ability | Ability Charge |
| Two-Finger Tap | Pause/Menu | Medium Bump |

## Configuration

### Project Settings
The following settings have been configured in `project.godot`:

```ini
[display]
window/stretch/mode="canvas_items"
window/stretch/aspect="expand"
window/handheld/orientation=1

[input_devices]
pointing/emulate_touch_from_mouse=true
pointing/emulate_mouse_from_touch=true

[rendering]
renderer/rendering_method="mobile"
textures/vram_compression/import_etc2_astc=true
```

### Android Export Settings
- **Target SDK**: Android 5.0+ (API 21+)
- **Architecture**: ARM64-v8a (primary), ARMv7 (fallback)
- **Permissions**: Internet, Vibrate, Wake Lock
- **Orientation**: Landscape (user-controlled)

## Usage

### Integrating Mobile Input
1. The system is automatically initialized through autoloads
2. Connect to gesture signals in your game scripts:

```gdscript
func _ready():
    MobileInputManager.gesture_detected.connect(_on_gesture_detected)

func _on_gesture_detected(gesture_type: MobileInputManager.GestureType, position: Vector2):
    match gesture_type:
        MobileInputManager.GestureType.SWIPE_LEFT:
            # Handle left swipe
            pass
```

### Adding Haptic Feedback
```gdscript
# Use predefined patterns
HapticController.on_lane_switch()
HapticController.on_collision()

# Or custom vibration
HapticController.play_custom_vibration(0.5, 0.2)
```

### Configuring Mouse Emulation
```gdscript
# Enable/disable mouse emulation (enabled by default on desktop)
MobileInputManager.set_mouse_emulation_enabled(true)

# Check if mouse emulation is active
if MobileInputManager.get_mouse_emulation_enabled():
    print("Mouse gestures available for testing")
```

### Mobile UI Scaling
```gdscript
# Add UI elements to mobile scaling groups
my_label.add_to_group("mobile_ui")
my_label.add_to_group("mobile_ui_text")

# Get current scale factor
var scale = MobileUIManager.get_ui_scale_factor()
```

## Testing

### Desktop Testing
- Touch emulation is enabled for mouse input
- Mouse gesture emulation provides desktop testing capabilities
- Use `MobileInputTest.gd` to verify gesture detection
- Check console output for gesture events

#### Mouse Emulation Controls
| Mouse Action | Emulated Gesture | Description |
|--------------|------------------|-------------|
| Left Click + Drag | Swipe | Drag in any direction to simulate swipe |
| Left Click (Quick) | Tap | Quick click for tap gesture |
| Left Click (Hold 0.5s) | Long Press | Hold left button for long press |
| Right Click | Two-Finger Tap | Right click for menu/pause gesture |

### Device Testing
1. Export to Android APK
2. Install on test devices
3. Verify gesture recognition and haptic feedback
4. Test on different screen sizes and orientations

## Performance Considerations

- Gesture detection runs at 60fps with minimal overhead
- Haptic feedback is throttled to prevent excessive vibration
- UI scaling calculations are cached and only updated on screen changes
- Touch input processing is optimized for mobile CPUs

## Troubleshooting

### Common Issues
1. **Gestures not detected**: Check touch sensitivity settings
2. **No haptic feedback**: Verify device supports vibration and permissions are granted
3. **UI scaling issues**: Ensure elements are in mobile UI groups
4. **Performance problems**: Reduce gesture sensitivity or disable haptic feedback

### Debug Information
Enable debug output by setting `MobileInputManager.debug_mode = true` in your scripts.

## Future Enhancements

- Gesture customization UI
- Advanced haptic patterns
- Adaptive UI layouts for different screen ratios
- Gesture recording and playback for tutorials