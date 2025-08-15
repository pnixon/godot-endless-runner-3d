# 3D Version Troubleshooting Guide

## Fixed Issues

### ✅ Script Parse Error - start_combat Function
**Error**: `Invalid argument for "start_combat()" function: argument 1 should be "int" but is "String"`

**Solution**: Fixed parameter order mismatch between GameManager3D and CombatGrid
- GameManager3D.start_combat expects: `(formation_id: String, encounter_lane: int)`
- CombatGrid.start_combat expects: `(player_lane: int, formation_id: String)`
- Fixed internal call to use correct parameter order

## Common Issues & Solutions

### 1. Scene Loading Issues
**Problem**: Main3D.tscn fails to load
**Solution**: 
- Ensure all script paths are correct
- Check that all referenced scripts exist
- Verify no circular dependencies

### 2. 3D Mesh Not Appearing
**Problem**: Hazards or player appear as invisible
**Solution**:
- Check MeshInstance3D has valid mesh assigned
- Verify materials are properly set
- Ensure proper lighting (DirectionalLight3D)

### 3. Collision Detection Not Working
**Problem**: Player passes through hazards
**Solution**:
- Verify collision layers and masks are set correctly
- Player detection area: collision_layer = 2, collision_mask = 1
- Hazards: collision_layer = 1, collision_mask = 2
- Check CollisionShape3D has valid shape assigned

### 4. Camera Issues
**Problem**: Camera angle is wrong or player not visible
**Solution**:
- Camera is attached to Player node
- Position: Vector3(0, 3, 5) - behind and above player
- Rotation: -15 degrees on X-axis for downward angle
- FOV: 75 degrees for good visibility

### 5. Input Not Responding
**Problem**: Player doesn't move with WASD
**Solution**:
- Check input map in project settings
- Verify input actions are defined:
  - move_left: A key and Left arrow
  - move_right: D key and Right arrow  
  - move_forward: W key and Up arrow
  - move_backward: S key and Down arrow
  - jump: Space key
  - slide: Shift key

### 6. Performance Issues
**Problem**: Low FPS or stuttering
**Solution**:
- Reduce number of simultaneous hazards
- Use simpler meshes for distant objects
- Enable object pooling (already implemented)
- Check GPU compatibility with Vulkan renderer

### 7. Audio Issues
**Problem**: Music not playing
**Solution**:
- Verify background_music.mp3 exists in project root
- Check AudioStreamPlayer is properly created
- Ensure audio drivers are working

## Debug Commands

### In-Game Debug Keys
- **H**: Show health bar debug info
- **T**: Test damage (10 HP)
- **Y**: Test healing (10 HP)
- **M**: Toggle music
- **+/-**: Adjust volume

### Console Debug
Enable debug prints to see:
- Player position and movement
- Hazard spawning and collision
- Combat system state
- Audio system status

## Performance Optimization

### Current Optimizations
- Object pooling for hazards
- Efficient collision detection
- Material caching
- Proper cleanup of removed objects

### Additional Optimizations (if needed)
- Reduce shadow quality
- Lower mesh complexity
- Implement LOD system
- Use MultiMeshInstance3D for repeated elements

## Testing Checklist

### Basic Functionality
- [ ] Game loads without errors
- [ ] Player appears as capsule mesh
- [ ] Camera follows player correctly
- [ ] Ground plane is visible
- [ ] Lighting works properly

### Movement System
- [ ] A/D switches lanes (X-axis)
- [ ] W/S moves forward/backward (Z-axis)
- [ ] Space makes player jump
- [ ] Shift makes player slide
- [ ] Movement is smooth and responsive

### Hazard System
- [ ] Hazards spawn ahead of player
- [ ] Different mesh shapes for different hazard types
- [ ] Telegraph effects work (pulsing/glowing)
- [ ] Collision detection works correctly
- [ ] Hazards are cleaned up properly

### UI System
- [ ] Health bar appears in top-left
- [ ] Score/coins/XP update correctly
- [ ] Instructions show 3D controls
- [ ] Game over screen works

### Audio System
- [ ] Background music plays automatically
- [ ] Volume controls work (M, +, -)
- [ ] No audio errors in console

## Getting Help

If you encounter issues not covered here:

1. Check the Godot console for error messages
2. Verify all file paths and references
3. Test with the simple Test3D.tscn scene first
4. Compare with working 2D version for reference
5. Check Godot 4.4.1 compatibility

## File Verification

Ensure these key files exist and are properly formatted:
- `Main3D.tscn` - Main game scene
- `GameManager3D.gd` - Game logic
- `Player3D.gd` - Player controller
- `EnhancedObstacle3D.gd` - Hazard system
- `EnhancedObstacle3D.tscn` - Hazard scene
- `HazardData.gd` - Shared data (from 2D version)
- `CombatGrid.gd` - Combat system (from 2D version)
- `background_music.mp3` - Audio file
