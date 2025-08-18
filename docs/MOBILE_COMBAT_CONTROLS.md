# Mobile Combat Controls

## Overview

The mobile combat control system provides intuitive touch gestures for lane-based combat actions. This system replaces traditional grid-based movement with fluid gesture-based dodging, blocking, and dashing.

## Combat Gestures

### Dodge Actions
- **Swipe Left**: Dodge left to avoid side attacks
- **Swipe Right**: Dodge right to avoid side attacks  
- **Swipe Down**: Dodge backward to avoid frontal attacks

### Movement Actions
- **Swipe Up**: Dash forward (replaces jumping)
  - Character moves forward while enemy also advances
  - Creates aggressive, fast-paced combat flow

### Defensive Actions
- **Hold Touch**: Block incoming attacks
  - Hold finger on screen to maintain block
  - Consumes stamina while blocking
  - Release to end block

## Haptic Feedback

The system provides tactile feedback for all combat actions:

- **Light Vibration (0.3s, 0.1s)**: Dodge actions
- **Medium Vibration (0.4s, 0.15s)**: Dash forward
- **Strong Vibration (0.5s, 0.2s)**: Block start
- **Enhanced Vibration (0.7s, 0.25s)**: Perfect dodge
- **Heavy Vibration (0.8s, 0.3s)**: Successful block

## Visual Indicators

### Touch Zones
The screen is divided into intuitive touch zones:

- **Left Edge (25%)**: Dodge left zone
- **Right Edge (25%)**: Dodge right zone  
- **Bottom Area (30%)**: Dodge backward zone
- **Top Area (30%)**: Dash forward zone
- **Center Area (40%)**: Block hold zone

### Visual Feedback
- **Gesture Recognition**: Shows detected gesture with directional arrows
- **Combat Actions**: Enhanced feedback for combat-specific gestures
- **Zone Highlighting**: Touch zones light up when activated
- **Perfect Timing**: Special effects for perfect dodges and blocks

## Implementation Details

### Gesture Thresholds
- **Dodge Swipe**: 80px minimum distance
- **Dash Swipe**: 120px minimum distance  
- **Block Hold**: 0.3s minimum duration

### Combat Integration
- Gestures automatically trigger combat actions when in combat mode
- System integrates with existing combat controller for timing and effects
- Perfect dodge windows and invincibility frames work with touch controls
- Stamina system applies to all gesture-based actions

## Testing Controls

### Desktop Testing (Mouse Emulation)
- **Left Click + Drag**: Simulate swipe gestures
- **Left Click (Short)**: Simulate tap
- **Left Click (Hold 0.5s)**: Simulate long press
- **Right Click**: Simulate two-finger tap

### Debug Controls
- **J Key**: Test mobile combat control integration
- **; Key**: Toggle touch zone visibility
- **F9-F12**: Run mobile combat system tests

## Technical Architecture

### Components
- **MobileInputManager**: Gesture recognition and haptic feedback
- **CombatController**: Combat action execution and timing
- **TouchZoneIndicator**: Visual feedback and zone management
- **HapticController**: Device vibration patterns

### Signal Flow
1. Touch input detected by MobileInputManager
2. Gesture recognized and classified
3. Combat-specific signal emitted
4. CombatController receives signal and executes action
5. Visual and haptic feedback provided
6. Combat state updated

## Performance Considerations

- Touch zones only created on mobile platforms or debug builds
- Haptic feedback automatically disabled on non-mobile platforms
- Visual indicators can be toggled for performance optimization
- Gesture recognition optimized for 60fps gameplay

## Future Enhancements

- Customizable gesture sensitivity settings
- Additional gesture types (pinch, rotate)
- Gesture combination attacks
- Accessibility options for different hand sizes
- Tutorial system for gesture learning