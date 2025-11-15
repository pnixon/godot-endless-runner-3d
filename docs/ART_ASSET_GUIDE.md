# 🎨 Art Asset Creation Guide

> **Complete guide for creating, importing, and optimizing 3D art assets for your endless runner game**

This guide covers everything from creating assets from scratch to importing and optimizing them for use in Godot 4.

---

## 📋 Table of Contents

1. [Art Style Guidelines](#1-art-style-guidelines)
2. [3D Modeling](#2-3d-modeling)
3. [Texturing and Materials](#3-texturing-and-materials)
4. [Animation](#4-animation)
5. [VFX and Particles](#5-vfx-and-particles)
6. [UI and 2D Assets](#6-ui-and-2d-assets)
7. [Audio Assets](#7-audio-assets)
8. [Import and Optimization](#8-import-and-optimization)
9. [Free Asset Resources](#9-free-asset-resources)

---

## 1. Art Style Guidelines

### 1.1 Choosing an Art Style

#### Low-Poly Style (Recommended for Indie/Solo Dev)
**Pros:**
- Faster to create
- Performs well on all platforms
- Timeless aesthetic
- Easy to iterate

**Specs:**
- Character: 500-2000 triangles
- Environment props: 100-500 triangles
- Enemies: 300-1500 triangles
- Stylized textures or flat colors

**Examples:** Crossy Road, Alto's Adventure, Minecraft

#### Stylized/Cartoon Style
**Pros:**
- Appeals to wide audience
- Forgiving with imperfections
- Fun and expressive

**Specs:**
- Character: 2000-5000 triangles
- Simple, appealing shapes
- Bold colors and outlines
- Exaggerated proportions

**Examples:** Crash Bandicoot, Jak and Daxter, Ratchet & Clank

#### Realistic Style
**Pros:**
- Immersive
- Impressive visuals

**Cons:**
- Time-intensive
- Requires advanced skills
- Higher performance cost

**Specs:**
- Character: 10,000-30,000 triangles
- PBR textures (4K for close-ups)
- Detailed normal maps

**Not recommended for solo/indie developers** unless you have AAA art team

### 1.2 Color Palette

Create a cohesive color palette for your game.

#### Example Palette Generator
```gdscript
# Define your game's color palette
const COLOR_PALETTE = {
    "player_primary": Color(0.2, 0.6, 1.0),      # Blue
    "player_secondary": Color(0.9, 0.9, 0.95),   # White/Silver
    "enemy_primary": Color(0.8, 0.2, 0.2),       # Red
    "environment_grass": Color(0.4, 0.7, 0.3),   # Green
    "environment_stone": Color(0.5, 0.5, 0.55),  # Gray
    "collectible_coin": Color(1.0, 0.8, 0.1),    # Gold
    "ui_background": Color(0.1, 0.1, 0.15),      # Dark Blue
    "ui_accent": Color(0.3, 0.8, 0.9),           # Cyan
}
```

**Tools for Palette Creation:**
- Coolors.co
- Adobe Color
- Paletton.com

### 1.3 Proportions and Scale

Maintain consistent scale throughout your game.

```
Reference Scale (Godot Units):
- 1 unit = 1 meter in real world
- Player height: 1.8 units (6 feet)
- Lane width: 3 units
- Jump height: 2-2.5 units
- Enemy sizes: 1.5-3 units (varied)
- Collectible: 0.5-1 unit
- Obstacles: 1-2.5 units height
```

**Export Scale Settings:**
- Blender: Use default units (1 Blender unit = 1 meter)
- Maya: Set to centimeters (180cm for character)
- 3ds Max: Set to meters

---

## 2. 3D Modeling

### 2.1 Software Recommendations

#### Free Options
1. **Blender** (Highly Recommended)
   - Industry-standard, completely free
   - Excellent Godot integration
   - Huge community and tutorials

2. **SketchUp Free**
   - Simple, beginner-friendly
   - Good for environments
   - Limited for character modeling

3. **Tinkercad**
   - Web-based
   - Perfect for simple low-poly assets
   - Very beginner-friendly

#### Paid Options
1. **Maya** ($220/month)
2. **3ds Max** ($220/month)
3. **Modo** ($60/month)
4. **Cinema 4D** ($94/month)

### 2.2 Player Character Modeling

#### Low-Poly Character Workflow (Blender)

**Step 1: Base Mesh**
```
1. Start with a cube (or use human base mesh addon)
2. Model basic body shapes:
   - Head: Sphere (subdivide 1-2 times)
   - Body: Cube stretched
   - Arms: Cylinders
   - Legs: Cylinders
   - Hands/Feet: Simple blocks or spheres

3. Target polycount: 500-2000 triangles total
```

**Step 2: Proportions**
```
Head-to-body ratio:
- Realistic: 1:7.5 (head is 1/7.5 of total height)
- Stylized: 1:3 to 1:5 (bigger head, cuter)
- Chibi: 1:2 (very large head)
```

**Step 3: Details**
```
Add minimal details:
- Face: Simple eye indents, nose bump (or just texture)
- Fingers: Combined or simple blocks (not individual)
- Clothing: Model as part of body or simple separate mesh
```

**Step 4: Unwrap UVs**
```
1. Select all faces
2. U → Smart UV Project (or manual unwrap for more control)
3. In UV editor, arrange islands efficiently
4. Leave small margin between islands
5. Export UV layout for texturing
```

#### Blender Shortcuts Cheatsheet
```
G - Move/Grab
R - Rotate
S - Scale
Tab - Toggle Edit Mode
E - Extrude
Ctrl+R - Loop Cut
Alt+Click - Select Loop
X - Delete menu
Shift+D - Duplicate
```

### 2.3 Enemy Modeling

Create varied enemy silhouettes for instant recognition:

```
Enemy Archetypes:

1. Basic Melee (Goblin)
   - Short, stocky
   - 1000 triangles
   - Simple weapon (club/sword)

2. Ranged Archer
   - Taller, slimmer
   - 1200 triangles
   - Bow as separate mesh

3. Heavy Bruiser
   - Large, bulky
   - 1500 triangles
   - Exaggerated proportions

4. Agile Rogue
   - Sleek, thin
   - 800 triangles
   - Crouched pose

5. Mage Caster
   - Flowing robes
   - 1300 triangles
   - Staff or wand

6. Boss
   - 2x-3x size of player
   - 3000-5000 triangles
   - Impressive silhouette
```

#### Modular Enemy System
Create interchangeable parts:
```
Base body (shared)
├── Head variant A, B, C
├── Weapon variant A, B, C
├── Armor variant A, B, C
└── Color variant A, B, C

Result: 81 unique combinations from 13 models!
```

### 2.4 Environment Modeling

#### Ground Tiles
```
Create modular 3x3 meter tiles:
- Grass tile
- Road tile
- Stone tile
- Dirt tile
- Sand tile

Each tile: 50-200 triangles
Tile seamlessly using modulo positioning
```

#### Props and Obstacles
```
Obstacles:
- Spikes: 100 triangles (cone cluster)
- Barrier: 80 triangles (simple bar)
- Wall: 120 triangles (with details)

Decoration Props:
- Rock: 50-150 triangles
- Tree: 200-500 triangles
- Building: 500-2000 triangles
- Lamp post: 150 triangles
```

#### Biome Sets
Create cohesive sets for each biome:

**Tutorial Valley Biome**
```
- Green grass ground
- Simple trees (low detail)
- Small rocks
- Wooden fences
- Clouds (planes with texture)
```

**Mystic City Biome**
```
- Cobblestone ground
- Buildings (simple boxes with windows)
- Street lamps
- Archways
- Market stalls
```

**Industrial Wasteland Biome**
```
- Metal platforms
- Pipes and machinery
- Rusty containers
- Warning signs
- Steam/smoke emitters (particle systems)
```

### 2.5 Collectibles and Items

#### Coin
```
Method 1: Simple disk
- Cylinder: 24 sides, 50 triangles
- Flatten on Y-axis
- Add bevel to edges
- Set to always face camera (billboard)

Method 2: Stylized star
- 8-pointed star shape
- 80 triangles
- Rotates slowly
```

#### Power-Ups
```
Shield:
- Transparent sphere with hexagon pattern
- 200 triangles
- Glowing shader

Speed Boost:
- Lightning bolt shape
- 120 triangles
- Animated electricity shader

Health Potion:
- Simple bottle shape
- 180 triangles
- Red liquid (separate mesh with transparency)
```

---

## 3. Texturing and Materials

### 3.1 Texturing Approaches

#### Option 1: Vertex Colors (Simplest)
```
Perfect for low-poly:
- No texture files needed
- Paint colors directly on mesh in Blender
- Export to Godot, colors preserved
- Fast performance

In Blender:
1. Switch to Vertex Paint mode
2. Choose color
3. Paint on mesh
4. Export as .glb
```

#### Option 2: Flat Color Materials
```gdscript
# In Godot, assign materials with flat colors
var player_material = StandardMaterial3D.new()
player_material.albedo_color = Color(0.2, 0.6, 1.0)  # Blue
player_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED  # For flat look

mesh_instance.set_surface_override_material(0, player_material)
```

#### Option 3: Simple Textures (Stylized)
```
Create simple textures:
- Resolution: 512x512 or 1024x1024
- Hand-painted style
- Minimal detail
- Bold outlines (optional)

Tools:
- Krita (free)
- GIMP (free)
- Photoshop
- Substance Painter (for PBR)
```

#### Option 4: PBR Textures (Advanced)
```
For realistic style:
- Albedo map (base color)
- Normal map (surface detail)
- Roughness map (shininess)
- Metallic map (metal vs non-metal)

Resolution:
- Characters: 2048x2048
- Environment: 1024x1024 to 2048x2048
- Props: 512x512 to 1024x1024
```

### 3.2 Texturing Workflow

#### Using Substance Painter (PBR)
```
1. Export model from Blender with UVs
2. Import to Substance Painter
3. Bake maps (normal, AO, curvature)
4. Create materials:
   - Base layer (skin, cloth, metal)
   - Details (dirt, scratches, wear)
   - Highlights (edge wear, shine)
5. Export texture sets (4K → downscale to 2K or 1K)
6. Import to Godot
```

#### Hand-Painting in Krita/Photoshop
```
1. Import UV layout from Blender
2. Create base color layer
3. Add shading layer (multiply mode)
4. Add highlights layer (add/screen mode)
5. Add details (eyes, patterns, symbols)
6. Export as PNG or JPG
7. Import to Godot, assign to material
```

### 3.3 Shader Effects

#### Cel-Shading (Toon Shader)
```gdscript
# Create custom toon shader
shader_type spatial;

uniform vec4 albedo : source_color = vec4(1.0);
uniform float toon_steps = 3.0;
uniform float outline_thickness = 0.05;
uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void fragment() {
    ALBEDO = albedo.rgb;
}

void light() {
    float NdotL = dot(NORMAL, LIGHT);
    float toon_intensity = floor(NdotL * toon_steps) / toon_steps;
    DIFFUSE_LIGHT = ALBEDO * LIGHT_COLOR * toon_intensity;
}
```

#### Outline Shader
```gdscript
shader_type spatial;
render_mode cull_front, unshaded;

uniform float outline_width = 0.05;
uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void vertex() {
    VERTEX += NORMAL * outline_width;
}

void fragment() {
    ALBEDO = outline_color.rgb;
}
```

**Usage:**
```gdscript
# Apply two materials to mesh
# Material 0: Main color/texture
# Material 1: Outline shader
```

#### Hologram Shader
```gdscript
shader_type spatial;
render_mode blend_add, unshaded;

uniform vec4 holo_color : source_color = vec4(0.0, 0.8, 1.0, 0.5);
uniform float scan_speed = 2.0;
uniform float scan_width = 0.1;

void fragment() {
    float scan = fract((UV.y + TIME * scan_speed));
    float intensity = smoothstep(0.0, scan_width, scan) * smoothstep(1.0, 1.0 - scan_width, scan);

    ALBEDO = holo_color.rgb;
    ALPHA = holo_color.a + intensity * 0.3;
    EMISSION = holo_color.rgb * intensity;
}
```

---

## 4. Animation

### 4.1 Character Animation

#### Essential Animations for Player

```
Required:
1. Idle - Standing still, breathing
2. Run - Running forward
3. Jump - Jumping upward
4. Fall - In mid-air
5. Land - Landing from jump
6. Slide - Sliding under obstacles
7. Lane Switch Left - Strafing left
8. Lane Switch Right - Strafing right

Combat (if using combat system):
9. Attack - Basic attack animation
10. Skill Cast - Using special ability
11. Dodge - Evasive movement
12. Block - Defensive stance
13. Hit React - Taking damage
14. Death - Falling/defeated

Total: 8-14 animations
```

#### Animation Specs
```
Frame rate: 24-30 FPS
Duration:
- Idle: 2-4 seconds (looping)
- Run: 0.5-1 second (looping)
- Jump: 0.3 seconds
- Land: 0.2 seconds
- Attack: 0.3-0.8 seconds
- Death: 1-2 seconds

Export format: .glb with animations embedded
```

### 4.2 Animation Workflow (Blender)

#### Step 1: Rigging
```
Option A: Auto-Rig (Blender Rigify addon)
1. Enable Rigify addon
2. Add → Armature → Basic → Human
3. Align bones to your mesh
4. Generate rig
5. Weight paint (automatic or manual)

Option B: Manual Rig
1. Create armature
2. Add bones:
   - Root (hips)
   - Spine (2-3 bones)
   - Head/Neck
   - Arms (shoulder, upper arm, forearm, hand)
   - Legs (thigh, shin, foot)
3. Parent mesh to armature (with automatic weights)
4. Fix weight painting issues
```

#### Step 2: Animating
```
1. Pose mode (Ctrl+Tab)
2. Set keyframes:
   - Select bone
   - Move/Rotate (G/R)
   - Press I to insert keyframe (Location, Rotation)
3. Move timeline
4. Repeat
5. Use graph editor to refine curves
```

#### Step 3: Animation Principles
```
Apply the 12 Principles:
1. Squash and Stretch - Add life
2. Anticipation - Wind up before action
3. Staging - Clear silhouette
4. Follow Through - Parts continue moving after stop
5. Ease In/Out - Accelerate and decelerate
6. Arcs - Natural movement in curves
7. Secondary Action - Supporting details
8. Timing - Speed conveys weight
9. Exaggeration - Push poses for appeal
10. Solid Drawing - Maintain volume
11. Appeal - Make it interesting to watch
12. Straight Ahead vs Pose to Pose
```

### 4.3 Enemy Animations

```
Basic Enemy Set:
1. Idle - Standing/waiting
2. Walk - Approaching player
3. Attack - Swinging weapon
4. Hit React - Taking damage
5. Death - Defeated
(5 animations)

Advanced Enemy Set:
+ Special Attack - Charged/powerful attack
+ Dodge/Block - Defensive move
+ Taunt - Before attacking
(8 animations)

Boss Set:
All of above +
+ Enrage - Powered-up state
+ Vulnerability - Stunned/breakable
+ Phase Transition - Between forms
(11+ animations)
```

### 4.4 Animation in Godot

#### Setting up AnimationPlayer
```gdscript
# In player script
@onready var animation_player = $AnimationPlayer

func _physics_process(delta):
    if is_on_floor():
        if velocity.length() > 0.1:
            animation_player.play("run")
        else:
            animation_player.play("idle")
    else:
        if velocity.y > 0:
            animation_player.play("jump")
        else:
            animation_player.play("fall")
```

#### Animation Tree (Advanced)
```gdscript
# Use AnimationTree for blending
@onready var animation_tree = $AnimationTree
@onready var state_machine = animation_tree.get("parameters/playback")

func _process(delta):
    state_machine.travel("run")  # Smooth transition

# Set blend values
animation_tree.set("parameters/run_speed/scale", run_speed / max_speed)
```

---

## 5. VFX and Particles

### 5.1 Particle Systems

#### Coin Collect Effect
```gdscript
func create_coin_collect_particles() -> GPUParticles3D:
    var particles = GPUParticles3D.new()
    particles.amount = 20
    particles.lifetime = 0.5
    particles.one_shot = true
    particles.explosiveness = 1.0

    var material = ParticleProcessMaterial.new()
    material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
    material.emission_sphere_radius = 0.5

    material.gravity = Vector3.ZERO
    material.initial_velocity_min = 2.0
    material.initial_velocity_max = 5.0

    material.color = Color.YELLOW
    material.color_ramp = create_fade_out_gradient()

    particles.process_material = material
    particles.draw_pass_1 = create_sparkle_mesh()

    return particles
```

#### Jump Dust Effect
```gdscript
func create_jump_dust() -> GPUParticles3D:
    var particles = GPUParticles3D.new()
    particles.amount = 15
    particles.lifetime = 0.6
    particles.one_shot = true

    var material = ParticleProcessMaterial.new()
    material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
    material.emission_box_extents = Vector3(0.5, 0.1, 0.5)

    material.direction = Vector3.UP
    material.spread = 25.0
    material.gravity = Vector3(0, -5, 0)

    material.initial_velocity_min = 1.0
    material.initial_velocity_max = 3.0

    material.scale_min = 0.2
    material.scale_max = 0.5

    particles.process_material = material

    return particles
```

#### Skill Effect (Fire Blast)
```gdscript
func create_fireball_particles() -> GPUParticles3D:
    var particles = GPUParticles3D.new()
    particles.amount = 50
    particles.lifetime = 1.0
    particles.emitting = true

    var material = ParticleProcessMaterial.new()
    material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
    material.emission_sphere_radius = 0.3

    # Fire colors
    var gradient = Gradient.new()
    gradient.add_point(0.0, Color.YELLOW)
    gradient.add_point(0.5, Color.ORANGE)
    gradient.add_point(1.0, Color.RED)

    var gradient_texture = GradientTexture1D.new()
    gradient_texture.gradient = gradient
    material.color_ramp = gradient_texture

    # Movement
    material.gravity = Vector3(0, 2, 0)  # Rise up
    material.initial_velocity_min = 0.5
    material.initial_velocity_max = 2.0

    particles.process_material = material

    return particles
```

### 5.2 Impact Effects

#### Hit Flash
```gdscript
# Flash white when hit
func flash_white(mesh_instance: MeshInstance3D):
    var material = mesh_instance.get_active_material(0).duplicate()
    material.emission_enabled = true
    material.emission = Color.WHITE
    material.emission_energy = 2.0

    mesh_instance.set_surface_override_material(0, material)

    await get_tree().create_timer(0.1).timeout

    material.emission_energy = 0.0
```

#### Screen Shake
```gdscript
# In camera controller
func trauma_shake(trauma_amount: float):
    trauma = min(trauma + trauma_amount, 1.0)

func _process(delta):
    if trauma > 0:
        trauma = max(trauma - delta, 0)
        var shake = trauma * trauma  # Square for smoother falloff

        camera.rotation_degrees.z = max_shake_rotation * shake * randf_range(-1, 1)
        camera.position.x = max_shake_offset * shake * randf_range(-1, 1)
        camera.position.y = max_shake_offset * shake * randf_range(-1, 1)
```

### 5.3 Environment Effects

#### Fog
```gdscript
# In WorldEnvironment
var environment = Environment.new()
environment.fog_enabled = true
environment.fog_light_color = Color(0.7, 0.8, 0.9)
environment.fog_density = 0.01
environment.fog_height = -10.0

world_environment.environment = environment
```

#### God Rays
```gdscript
# Add DirectionalLight3D with shadow
var sun = DirectionalLight3D.new()
sun.light_energy = 1.5
sun.shadow_enabled = true
sun.rotation_degrees = Vector3(-45, 135, 0)

# Add volumetric fog for god ray effect
environment.volumetric_fog_enabled = true
environment.volumetric_fog_density = 0.05
```

---

## 6. UI and 2D Assets

### 6.1 HUD Elements

#### Health Bar
```
Create in image editor:
- Background: 200x40px, dark gray/black
- Fill: 196x36px, gradient red to green
- Border: 200x40px, white outline
- Export as PNG with transparency
```

#### Buttons
```
Normal state: 200x60px
Hover state: 200x60px (brighter)
Pressed state: 200x60px (darker, offset)

Use 9-slice scaling in Godot for resizing
```

#### Icons
```
Skill icons: 64x64px
Item icons: 48x48px
Status icons: 32x32px

Style tips:
- Clear silhouette
- Bold outlines
- Limited colors
- Recognizable at small size
```

### 6.2 Menu Backgrounds

```
Title screen:
- 1920x1080px (16:9)
- Or higher resolution, Godot will scale down
- Parallax layers for depth
- Animated elements (particles, shaders)

Settings menu:
- Semi-transparent overlay (dark blur)
- Clean, readable text
```

### 6.3 Typography

**Font Recommendations:**
- **Headers:** Bold, impactful (e.g., Bebas Neue, Oswald)
- **Body:** Readable, clean (e.g., Open Sans, Roboto)
- **Game Text:** Stylized but clear (e.g., Press Start 2P for retro)

**Free Font Sources:**
- Google Fonts
- DaFont
- Font Squirrel

**Import to Godot:**
```
1. Place .ttf or .otf in res://assets/fonts/
2. Create DynamicFont resource
3. Set size, outline, shadow as needed
4. Assign to Label nodes
```

---

## 7. Audio Assets

### 7.1 Sound Effects

#### Required SFX
```
Player Actions:
- Jump (whoosh)
- Land (thud)
- Slide (quick scrape)
- Footsteps (run loop, 4-6 variations)
- Take damage (grunt/impact)
- Death (dramatic fall)

Combat:
- Sword swing (whoosh)
- Hit impact (thwack)
- Block (clang)
- Skill cast (magical charge)
- Spell impact (explosion)

Collectibles:
- Coin pickup (ding)
- Power-up (magical shimmer)
- Health potion (gulp)

UI:
- Button click
- Button hover
- Menu open
- Menu close
- Level up (fanfare)
```

#### Creating SFX

**Tools:**
- **Audacity** (free) - Edit and mix
- **BFXR** (free, web-based) - Generate retro SFX
- **ChipTone** (free) - Chiptune SFX
- **Freesound.org** - Free SFX library

**Recording:**
- Use smartphone or cheap mic
- Record Foley (real-world sounds)
- Layer multiple sounds for richness

**Export Settings:**
```
Format: OGG Vorbis (best for Godot)
Bitrate: 128 kbps (good quality, small size)
Sample Rate: 44.1kHz
Mono for SFX, Stereo for music
```

### 7.2 Music

#### Required Tracks
```
1. Main Menu - Inviting, energetic
2. Gameplay Loop - Driving, exciting, loops smoothly
3. Boss Battle - Intense, fast-paced
4. Victory Jingle - Short, celebratory (5-10 seconds)
5. Game Over - Somber, failure theme (5-10 seconds)
```

#### Music Tools
- **LMMS** (free) - Full DAW
- **Bosca Ceoil** (free) - Simple, retro music maker
- **BeepBox** (free, web-based) - Chiptune maker
- **GarageBand** (Mac, free) - Easy music creation

#### Music Sources (Free/Royalty-Free)
- **OpenGameArt.org**
- **Incompetech** (Kevin MacLeod)
- **Purple Planet Music**
- **Bensound**

**Licensing:**
- Check license (CC0, CC-BY, etc.)
- Credit composer if required
- Don't use copyrighted music!

#### Implementation
```gdscript
# In AudioManager
func play_music(track_name: String):
    var new_stream = load("res://assets/audio/music/%s.ogg" % track_name)

    # Crossfade
    var tween = create_tween()
    if music_player.playing:
        tween.tween_property(music_player, "volume_db", -80, 1.0)

    await tween.finished

    music_player.stream = new_stream
    music_player.play()

    tween = create_tween()
    tween.tween_property(music_player, "volume_db", 0, 1.0)
```

---

## 8. Import and Optimization

### 8.1 Godot Import Settings

#### 3D Models (.glb / .gltf)
```
Import settings:
- Meshes:
  - Generate Lightmap UVs: Yes (for baked lighting)
  - LODs: Generate (for distant objects)

- Materials:
  - Import as Spatial Material
  - Use Named Materials

- Animation:
  - Import animations: Yes
  - FPS: 30
  - Trimming: Yes
  - Loop: Set per animation
```

#### Textures
```
Import settings:
- Compress: VRAM Compressed (default)
- Mipmaps: Generate
- Filter: Linear (smooth) or Nearest (pixel-art)
- Repeat: Enabled (for tiling) or Disabled

For UI textures:
- Compress: Lossless
- Mipmaps: Off
- Filter: Linear with Mipmaps Anisotropic
```

#### Audio
```
Import settings:
- Format: OGG Vorbis
- Loop: Enable for music, disable for SFX
- Compression: Compressed (RAM)

For looping music:
- Set loop mode to "Forward"
- Set loop begin/end points if needed
```

### 8.2 Optimization Techniques

#### LOD (Level of Detail)
```gdscript
# In Blender, create 3 versions:
# - Model_LOD0.glb (full detail, 0-10 units)
# - Model_LOD1.glb (medium, 10-30 units)
# - Model_LOD2.glb (low, 30+ units)

# In Godot:
var lod_node = GeometryInstance3D.new()
lod_node.lod_bias = 1.0
```

#### Texture Atlasing
```
Combine multiple textures into one:
- Character: body, head, accessories in one 2048x2048
- UI elements: all icons in one atlas
- Environment: props in one atlas

Benefits:
- Fewer draw calls
- Better performance
- Easier to manage

Tools:
- TexturePacker
- Godot's built-in sprite sheet tools
```

#### Mesh Optimization
```
In Blender before export:
1. Remove doubles (Merge → By Distance)
2. Dissolve unnecessary edges
3. Use Decimate modifier if too high poly
4. Apply all modifiers
5. Check triangle count (keep under budget)
```

#### Batching
```gdscript
# Use MultiMesh for many identical objects
var multi_mesh = MultiMeshInstance3D.new()
multi_mesh.multimesh = MultiMesh.new()
multi_mesh.multimesh.transform_format = MultiMesh.TRANSFORM_3D
multi_mesh.multimesh.instance_count = 1000
multi_mesh.multimesh.mesh = rock_mesh

for i in range(1000):
    var transform = Transform3D()
    transform.origin = Vector3(randf() * 100, 0, randf() * 100)
    multi_mesh.multimesh.set_instance_transform(i, transform)
```

---

## 9. Free Asset Resources

### 9.1 3D Model Libraries

**Free:**
- **Kenney.nl** - HUGE library of free game assets (CC0)
- **Quaternius** - Low-poly 3D models (CC0)
- **Poly Pizza** - Community 3D models (CC0)
- **OpenGameArt.org** - Game assets (various licenses)
- **Sketchfab** - Some free models (check license)

**Paid:**
- **Humble Bundle** - Asset bundles (cheap)
- **itch.io** - Indie game assets
- **Unity Asset Store** - Convert to Godot
- **CGTrader** - Pro models

### 9.2 Texture Libraries

- **Polyhaven** (CC0) - PBR textures
- **TextureCan** (CC0) - Seamless textures
- **Textures.com** (Free tier available)
- **Kenney.nl** - Stylized textures

### 9.3 Audio Libraries

- **Freesound.org** - Community SFX (CC)
- **Zapsplat** - Free SFX library
- **OpenGameArt.org** - Music and SFX
- **Incompetech** (Kevin MacLeod) - Royalty-free music (CC-BY)
- **Purple Planet** - Free music
- **YouTube Audio Library** - Free music and SFX

### 9.4 UI/Font Resources

- **Google Fonts** - Free fonts
- **Font Awesome** - Icon font
- **Game-Icons.net** - Free game icons (CC-BY)
- **Flaticon** - Icons (free tier)

---

## 10. Asset Pipeline Checklist

### Before Export (Blender/Maya/etc.)
- [ ] Model is correct scale (1 unit = 1 meter)
- [ ] All modifiers applied
- [ ] Mesh is clean (no doubles, ngons fixed)
- [ ] UVs unwrapped correctly
- [ ] Materials/textures assigned
- [ ] Animations created and named
- [ ] Rig is functional (if animated)
- [ ] Polycount within budget
- [ ] Normals facing correct direction

### Export Settings
- [ ] Format: .glb (recommended) or .gltf
- [ ] Include: Meshes, materials, animations
- [ ] Apply transforms on export
- [ ] Use correct up-axis (Y-up for Godot)

### After Import (Godot)
- [ ] Check model appears correctly
- [ ] Verify scale is correct
- [ ] Materials look right
- [ ] Animations play properly
- [ ] Collisions set up (if needed)
- [ ] LOD configured (if using)
- [ ] Added to appropriate groups
- [ ] Tested in-game

---

## Conclusion

Creating art assets is a huge part of game development, but by following these guidelines, you can create a cohesive, polished look even as a solo developer or small team.

**Key Takeaways:**
1. **Choose a style you can execute** - Low-poly is perfectly fine!
2. **Consistency is more important than fidelity** - Cohesive look beats high detail
3. **Use free assets to supplement** - Kenney, Quaternius, etc.
4. **Optimize early** - Keep polycount and texture sizes reasonable
5. **Iterate** - First version won't be perfect, improve over time

**Next Steps:**
- Review [CAMERA_GUIDE.md](./CAMERA_GUIDE.md) for camera setup
- See [PRODUCTION_GUIDE.md](./PRODUCTION_GUIDE.md) for full workflow
- Check [GDD.md](./GDD.md) for design vision

---

**Happy creating! 🎨✨**
