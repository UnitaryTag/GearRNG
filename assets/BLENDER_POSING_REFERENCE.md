# Blender Posing Reference — MenuScene Character

> **Drop this file into a terminal Claude session at `/home/willi/Documents/GearRNG`.**  
> Say: *"Read assets/BLENDER_POSING_REFERENCE.md, then pose the character sitting."*

---

## 1. The Task

Pose the Roblox R15 blocky character in a **seated pose under the tree, facing the camera** (butt at Z=0, legs extended forward toward camera, arms resting at sides with bent elbows, back near tree trunk). The posed character lives in `MenuScene.blend` and gets exported to `MenuScene.fbx` for Roblox.

**File:** `/home/willi/Documents/GearRNG/assets/MenuScene.blend` — open this in Blender.  
**Output:** Save blend, re-export FBX.

---

## 2. The Rig — MrXen0 Roblox Blocky R15

- **Rig ID:** `xqpb4vnl0zay` (Blender 4.0+)
- **Armature object:** `Roblox_R15` (141 bones)
- **Embedded UI script:** `MrXen0_R15RIGUI_v1.0.py` — text datablock inside the blend file. Contains all IK/FK operators.

### 2.1 Coordinate System

- **Z is UP** (ground plane at Z≈0)
- **Y is FORWARD** — character currently faces **-Y** (toward camera), back toward **+Y** (tree)
- **X is LEFT/RIGHT** — character's left = world +X, character's right = world -X (after 180° Z rotation)
- 1 Blender unit = 1 Roblox stud

**Important:** The armature has a 180° Z rotation (`rotation_euler = (0, 0, π)`) with a `(0, -2, 0)` location offset. This flips the character to face -Y while keeping ROOT at the same world position. Because of this rotation, the character's local X is inverted: `.L` bones correspond to world +X, `.R` bones to world -X.

### 2.2 Critical: ROOT ≠ Pelvis

**ROOT** is a master control bone at the origin. **LowerTorso** is the actual hip/pelvis bone.  
In rest pose: ROOT at Z=0, LowerTorso at Z=2.0 (offset = 2.0 units).  
**To put the butt on the ground:** move ROOT to Z=-2.0 → LowerTorso ends up at Z=0.

All IK controllers are parented under ROOT (via MCH bones), so they shift with ROOT.

### 2.3 Bone Hierarchy (simplified)

```
ROOT (master control, Z=0 in rest)
├── LowerTorso (actual hips, Z=2.0 in rest)
│   └── UpperTorso → Head
├── MCH_IK_HAND_PARENT.L → IK_Hand.L (hand IK target)
├── MCH_IK_HAND_PARENT.R → IK_Hand.R
├── MCH_IK_LEG_PARENT.L  → IK_LEG.L (foot IK target)
│   ├── FOOT_ROLL.L
│   └── MCH_FOOT_BACK.L
├── MCH_IK_LEG_PARENT.R  → IK_LEG.R
├── POLE_ARM.L / POLE_ARM.R (elbow direction guides)
├── POLE_LEG.L / POLE_LEG.R (knee direction guides)
├── ORG_UpperLeg.L/R → ORG_LowerLeg.L/R → ORG_Foot.L/R  (deform chain)
├── ORG_UpperArm.L/R → ORG_LowerArm.L/R → ORG_Hand.L/R
└── PROPERTIES (IK/FK mode sliders — **DO NOT DELETE**)
```

### 2.4 IK/FK System

**PROPERTIES bone** stores mode sliders (accessible via `arm.pose.bones["PROPERTIES"]`):
- `ARM_IK_FK.L` / `ARM_IK_FK.R` — **1.0 = IK mode**, 0.0 = FK mode
- `LEG_IK_FK.L` / `LEG_IK_FK.R` — **1.0 = IK mode**, 0.0 = FK mode
- `ARM_IK_PARENT.L` / `ARM_IK_PARENT.R` — 0 = parent to ROOT, 1 = parent to Torso
- `LEG_IK_PARENT.L` / `LEG_IK_PARENT.R` — 0 = parent to ROOT, 1 = parent to Torso

**Current mode:** All IK (all `*_IK_FK` = 1.0). The rig should stay in IK mode.

**Snap operators** (from embedded script):
```python
bpy.ops.roblox_r15.ik_fk_arm   # Snap IK → FK position, switch to FK
bpy.ops.roblox_r15.fk_ik_arm   # Snap FK → IK position, switch to IK
bpy.ops.roblox_r15.ik_fk_leg   # Same for legs
bpy.ops.roblox_r15.fk_ik_leg
```
These compute proper rest-pose offsets via `get_matrix()` and handle the transition cleanly.

### 2.5 Bone Collections

| Collection | Bones | Purpose |
|-----------|-------|---------|
| DEF | 15 | Deform bones — drive the mesh |
| ORG | 12 | Original/organization bones |
| MCH | 77 | Mechanic bones — constraints, IK chain |
| BODY | 3 | Body control |
| ROOT | 1 | Master root |
| HEAD | 1 | Head control |
| PROPERTIES | 1 | IK/FK sliders |
| ARM_FK.L/R | 3 each | FK arm controls |
| ARM_IK.L/R | 4 each | IK arm controls (IK_Hand, POLE_ARM) |
| LEG_FK.L/R | 3 each | FK leg controls |
| LEG_IK.L/R | 5 each | IK leg controls (IK_LEG, POLE_LEG, foot roll) |

### 2.6 Mesh Body Parts

15 separate mesh objects (blocky Roblox style), each parented to the armature with Armature Deform:
`Head, UpperTorso, LowerTorso, LeftUpperArm, LeftLowerArm, LeftHand, RightUpperArm, RightLowerArm, RightHand, LeftUpperLeg, LeftLowerLeg, LeftFoot, RightUpperLeg, RightLowerLeg, RightFoot`

---

## 3. The Scene (MenuScene.blend)

### 3.1 Objects in the scene
- **Roblox_R15** — armature + 15 body mesh parts (the character)
- **Tree** — Trunk_Lower, Trunk_Mid, Trunk_Upper, Trunk_Canopy, Leaves (5 mesh objects, UV-fixed)
- **Ground** — flat ground plane
- **GrassField** — scattered grass clumps

### 3.2 Lighting Setup (Golden Hour 3-Point)

Three SUN lamps + World ambient create warm evening light:

| Light | Energy | Color | Role |
|-------|--------|-------|------|
| KeySun | 4.0 | (1.00, 0.75, 0.45) warm gold | Main sun, casts shadows |
| FillLight | 0.8 | (0.35, 0.50, 0.85) cool blue | Fills shadow side |
| RimLight | 3.0 | (1.00, 0.90, 0.70) warm | Edge separation from background |

**World (MenuWorld):** Dark warm ambient — Background node with color (0.05, 0.04, 0.03), strength 0.5. Prevents pure black shadows while keeping mood.

**Eevee settings:** `use_raytracing = True`, `use_shadows = True`. Render 480×270.

**Blender 5.1 note:** `shadow_cube_size`, `shadow_cascade_size`, `use_ssr` are removed in 5.1. Raytracing shadows replace the old shadow map approach.

### 3.3 Camera Setup

**MainMenuCamera** at position (0.8, -4.5, 1.5):
- **35mm lens** — moderate wide angle, cinematic framing
- **Looking at** chest level (~Z=1.0) — character fills center frame
- **Y=-4.5** (in front of character who faces -Y) — clear view of full body
- **Render resolution:** 480×270 (16:9 small preview)

Viewport screenshot alternative: `save_viewport()` captures the current 3D viewport angle (useful for checking from different angles without re-rendering).

### 3.4 Current Pose State (2026-06-20 — straight legs, feet forward, hands on ground)

**Pose:** Seated on ground under tree, face toward camera (-Y), hands resting on ground, **legs perfectly straight and flat on ground**, **feet aligned with legs (not auto-flattened to floor)**. User explicitly requested: no knee bend, legs flat on floor, feet stay on legs pointing forward.

**Armature transform:** `rotation_euler = (0, 0, π)` (180° Z), `location = (0, -2, 0)`. This flips the character to face -Y while keeping ROOT at world (0, -1, -2).

**IK targets in world space:**

| Bone | World Position (X, Y, Z) | Notes |
|------|--------------------------|-------|
| ROOT | (0, -1, -2) | World position after armature offset |
| LowerTorso | (0, -1, 0) | Butt on ground ✓ |
| UpTorso | (0, -1, 0.4) | 8° backward lean (`rot_euler.x = 0.14`) |
| Head | (0, -0.777, 1.984) | Face at Y=-0.777, back near tree |
| IK_Hand.L | (1.200, -1.000, 0.000) | Hand at side, outside torso width |
| IK_Hand.R | (-1.200, -1.000, 0.000) | |
| IK_LEG.L | (0.480, -3.472, -0.246) | **Compensated for foot rotation offset** |
| IK_LEG.R | (-0.480, -3.472, -0.246) | |
| POLE_ARM.L | (1.100, -0.850, 1.000) | Elbow guide — outward, natural bend |
| POLE_ARM.R | (-1.100, -0.850, 1.000) | |
| POLE_LEG.L | (0.500, -2.000, 0.000) | Knee guide — **aligned with full leg extension** |
| POLE_LEG.R | (-0.500, -2.000, 0.000) | |

**FOOT_ROLL rotation (critical — controls foot orientation):**

| Bone | Rotation Euler (XYZ) | Notes |
|------|---------------------|-------|
| FOOT_ROLL.L | (π/2, 0, 0) = (90°, 0, 0) | Tilts foot to point forward in line with leg |
| FOOT_ROLL.R | (π/2, 0, 0) = (90°, 0, 0) | Instead of auto-flattening to ground |

**Deform bone verification (world space):**

| ORG Bone | World Position | Notes |
|----------|---------------|-------|
| ROOT | (0.000, -1.000, -2.000) | Master control |
| LowerTorso | (0.000, -1.000, 0.000) | Butt at Z=0 ✓ |
| UpTorso | (0.000, -1.000, 0.400) | 8° lean applied |
| UpperTorso | (0.000, -1.000, 0.400) | Driven by COPY_TRANSFORMS |
| Head | (0.000, -0.777, 1.984) | Face -Y, back +Y |
| ORG_UpperArm.L | (1.000, -0.810, 1.750) | Shoulder |
| ORG_LowerArm.L | (1.322, -0.980, 0.945) | Elbow — bent outward naturally |
| ORG_Hand.L | (1.200, -1.000, 0.000) | Hand on ground at side |
| ORG_UpperArm.R | (-1.000, -0.810, 1.750) | Shoulder |
| ORG_LowerArm.R | (-1.322, -0.980, 0.945) | Elbow — bent outward naturally |
| ORG_Hand.R | (-1.200, -1.000, 0.000) | Hand on ground at side |
| ORG_UpperLeg.L | (0.500, -1.000, 0.000) | Hip — leg starts at Z=0 |
| ORG_LowerLeg.L | (0.646, -1.809, 0.000) | Knee — **Z=0, perfectly flat** |
| ORG_Foot.L | (0.480, -2.720, 0.000) | Foot at full leg extension, Z=0 |
| ORG_UpperLeg.R | (-0.500, -1.000, 0.000) | Hip — leg starts at Z=0 |
| ORG_LowerLeg.R | (-0.646, -1.809, 0.000) | Knee — **Z=0, perfectly flat** |
| ORG_Foot.R | (-0.480, -2.720, 0.000) | Foot at full leg extension, Z=0 |

**Foot orientation (Y=forward, Z=up):**
| Bone | Y Axis (toe direction) | Z Axis (top of foot) |
|------|----------------------|---------------------|
| ORG_Foot.L | (0.000, -1.000, 0.002) — forward ✓ | (0.000, -0.002, -1.000) — top up ✓ |
| ORG_Foot.R | (0.000, -1.000, 0.002) — forward ✓ | (0.000, -0.002, -1.000) — top up ✓ |

**Key metrics:**
- Butt: LowerTorso at Z=0.000 — seated on ground ✓
- Legs: All leg bones (UpperLeg, LowerLeg, Foot) at Z=0.000 — perfectly flat ✓
- Knee: Z=0.000, no bend — straight leg from hip to foot ✓
- Foot Y axis: points (0, -1, 0) — forward in line with leg, NOT flattened to floor ✓
- Foot position: Y=-2.720, full leg extension (bone length 1.748 from hip at Y=-1.000)
- Hands: Z=0.000 — resting on ground at sides
- Arm chain (L): shoulder (1.00,-0.81,1.75) → elbow (1.322,-0.98,0.945) → hand (1.20,-1.00,0.00) — natural bent arc, hands at sides outside torso
- L/R symmetry: perfect (all pairs match within 0.001)

**Known trade-offs:**
- **Leg-ground clipping:** UpperLeg mesh bottoms at Z≈-0.65 (0.6 below ground), LowerLeg at Z≈-0.59 (0.6 below). Unavoidable with blocky R15 limbs (~1.2 studs thick) in horizontal-legged seated pose with butt on ground.
- **Knee interpenetration:** LeftLowerLeg and RightLowerLeg bboxes overlap at knees — legs positioned close together with blocky meshes.
- **IK_LEG position below ground (Z=-0.246):** Compensates for the FOOT_ROLL X=90° rotation which shifts MCH_IK_Foot upward and backward. The IK target must be pushed out to Y=-3.472 and down to Z=-0.246 so the resulting foot lands at Z=0, Y=-2.720.

### 3.5 Torso Control

The torso lean is applied via **UpTorso** bone (`rotation_euler.x = 0.14` = 8° backward lean). UpperTorso is driven through a `COPY_TRANSFORMS` constraint. Do NOT rotate UpperTorso directly — it will be overwritten by the constraint.

**Current lean:** 8° backward (toward tree / +Y). This is the sweet spot: enough to create visible contact between LowerTorso back and the tree, but not so much that the head penetrates the trunk.

**With 180° Z armature rotation:** Positive X rotation on UpTorso tilts the character backward (toward +Y / tree). This is because the armature rotation flips the bone's local axes — in the pre-flip orientation, +X rotation tilted forward, but post-flip it tilts backward.

IK hands are parented to ROOT (`ARM_IK_PARENT=0`), so they move with the character root rather than the torso. For the current arms-at-sides pose, this keeps hands at hip level regardless of torso lean.

---

## 4. How to Pose (Working Code Patterns)

### 4.1 Reset ALL bones to rest
```python
import bpy
from mathutils import Vector, Euler, Quaternion

arm = bpy.data.objects["Roblox_R15"]
bones = arm.pose.bones

for pb in bones:
    pb.location = Vector((0, 0, 0))
    pb.rotation_quaternion = Quaternion((1, 0, 0, 0))
    pb.rotation_euler = Euler((0, 0, 0))
    pb.scale = Vector((1, 1, 1))
bpy.context.view_layer.update()
```

### 4.2 Move hips to ground
```python
bones["ROOT"].location.z = -2.0  # Lowers LowerTorso from Z=2.0 to Z=0.0
bpy.context.view_layer.update()
```

### 4.3 Set IK target in world space
```python
def set_ik_world(bone_name, world_pos):
    """Set an IK control bone to a world-space position."""
    pb = bones[bone_name]
    # Parent's world matrix (includes ROOT offset)
    parent_world = arm.matrix_world @ pb.parent.matrix
    # Convert world target → local space relative to parent
    pb.location = parent_world.inverted() @ world_pos
```

### 4.4 Get bone world position (for verification)
```python
def get_world_pos(bone_name):
    pb = bones[bone_name]
    world = arm.matrix_world @ pb.matrix
    return world.translation
```

### 4.5 Verify the IK/FK mode
```python
props = arm.pose.bones["PROPERTIES"]
print(f"Arm IK: L={props['ARM_IK_FK.L']}, R={props['ARM_IK_FK.R']}")
print(f"Leg IK: L={props['LEG_IK_FK.L']}, R={props['LEG_IK_FK.R']}")
# All should be 1.0 (IK mode)
```

### 4.6 Save viewport screenshot (for verification)
```python
import os
tmp = os.path.join(os.path.expanduser("~"), "Documents", "GearRNG", "assets", "viewport_check.png")
area = next(a for a in bpy.context.screen.areas if a.type == 'VIEW_3D')
with bpy.context.temp_override(area=area):
    bpy.ops.screen.screenshot_area(filepath=tmp)
```

### 4.7 Export FBX
```python
bpy.ops.export_scene.fbx(
    filepath="/home/willi/Documents/GearRNG/assets/MenuScene.fbx",
    axis_forward="-Z",
    axis_up="Y",
    apply_unit_scale=True,
    apply_scale_options="FBX_SCALE_ALL",
    mesh_smooth_type="OFF",
    use_mesh_modifiers=True,
    use_tspace=True,
)
```

---

## 5. Vision System — "Seeing" the Blender Scene

**DeepSeek v4 Pro model backend cannot process images** — `get_viewport_screenshot` and `Read` of PNGs both return `[Unsupported Image]`. This is a model limitation, not a terminal/config issue. The solution is a dual approach:

### 5.1 AI Vision: Programmatic Scene Description (`blender_vision.py`)

The reusable module at `assets/blender_vision.py` provides text-based "vision" of the 3D scene:

```python
# Load the module
exec(open("/home/willi/Documents/GearRNG/assets/blender_vision.py").read())

# Get full scene text dump (objects, bones, lights, camera)
print(describe_full_scene())

# Check for pose problems (symmetry, clipping, ground contact)
print(diagnose_issues())

# Quick bone position query
pos = bone_world_pos("IK_Hand.R")
```

**Key functions:**
| Function | Returns |
|----------|---------|
| `describe_full_scene()` | All scene objects with bbox, all bone world positions, lights, world, camera, render settings |
| `diagnose_issues()` | Pose problems: ground contact, knee height, butt height, L/R symmetry, mesh interpenetration |
| `bone_world_pos(name)` | `Vector` of bone head in world space (handles ROOT offset correctly) |
| `bone_world_tail(name)` | `Vector` of bone tail in world space |
| `save_viewport(path?)` | Saves 3D viewport screenshot to `assets/viewport_current.png` |
| `save_render(path?)` | Renders camera view to `assets/render_preview.png` |

**Diagnostic rules:**
- Feet/hands off ground: Z > 0.05 triggers warning
- Knees high: Z > 0.3 triggers warning
- Hips not at ground: |Z| > 0.01 triggers warning
- Bone below ground: Z < -0.05 on any deform bone triggers warning
- L/R asymmetry: > 0.05 world-space difference on any axis
- Cross-region penetration: only checks arms-vs-legs and L-vs-R limb pairs (avoids false positives from joint-adjacent blocky mesh overlap)

### 5.2 User Vision: Terminal Screenshots with `viu`

`viu` renders images in-terminal via the **Kitty graphics protocol**. The AI can't see the image, but the user can:

```bash
# View the current viewport
viu /home/willi/Documents/GearRNG/assets/viewport_current.png

# View a camera render
viu /home/willi/Documents/GearRNG/assets/render_preview.png
```

### 5.3 Workflow

1. **AI reads** `describe_full_scene()` output → reasons about pose geometrically
2. **AI runs** `diagnose_issues()` → catches symmetry/clipping problems
3. **AI saves screenshots** via `save_viewport()` or `save_render()` → tells user "run `viu assets/viewport_current.png`"
4. **User views** screenshot with `viu` → provides visual feedback in plain English

### 5.4 MCP Note

The **blender-mcp** addon (v1.2, ahujasid/blender-mcp) connects via raw TCP on port 9876. Its `get_viewport_screenshot` tool correctly returns base64 PNG — it's just that the DeepSeek model backend can't render it. The MCP tools still work fine for:
- `execute_blender_code` — run arbitrary Python in Blender
- `get_scene_info` — structured scene data
- `get_object_info` — per-object details
- Polyhaven / Sketchfab / Hunyuan3D integrations

---

## 6. Target Pose Description

**"Sitting under the tree, facing the camera"** — relaxed, cinematic:
1. **Butt on ground:** LowerTorso at Z=0 (ROOT world Z=-2), mesh bottom at Z=0.000
2. **Back near tree:** Torso leaned back 8° — LowerTorso back near tree trunk, UpperTorso/Head close but not penetrating
3. **Face toward camera (-Y):** Character looks toward the viewer at Y=-4.5
4. **Legs straight, flat on ground:** All leg bones at Z=0.000 from hip to foot. No knee bend. Feet at full extension Y=-2.720 (total leg bone length 1.748 from hip at Y=-1.000). POLE targets aligned with leg direction (Y=-2.0, Z=0) to prevent knee collapse or arching.
5. **Feet point forward (not flat on floor):** FOOT_ROLL rotated 90° around X to tilt feet to point forward in line with the straight legs. ORG_Foot Y axis = (0, -1, 0). This overrides the rig's default auto-flattening behavior that rotates feet parallel to the ground plane.
6. **Arms at sides with bent elbows:** Hands at X=±1.2, Y=-1.0, Z=0.0 (on ground at sides, outside torso width of 2.0). Elbows bent outward via POLE_ARM at X=±1.1, Y=-0.85, Z=1.0. NOT straight — natural relaxed arc from shoulder through elbow to hand.
7. **L/R symmetry:** Perfect ±X mirroring for all paired bones

## 7. Foot Rotation Mechanism (FOOT_ROLL → MCH Chain)

The R15 rig automatically flattens feet to be parallel with the ground (standard for walking/running). To override this for a seated pose where feet point forward:

**Chain:** `FOOT_ROLL → MCH_FOOT_BACK (Transform constraint) → MCH_FOOT_LEFT_SIDE → MCH_INT_IK_LEG → MCH_IK_Foot → MCH_SWITCH_Foot → ORG_Foot (Copy Transforms, WORLD)`

- **FOOT_ROLL** — child of IK_LEG, identity rotation by default, NO constraints. The user-facing control point for foot rotation.
- **MCH_FOOT_BACK** — child of IK_LEG, has a TRANSFORM constraint targeting FOOT_ROLL. Propagates FOOT_ROLL's rotation into the MCH chain.
- **MCH_IK_Foot** — copies rotation from MCH_INT_IK_LEG. Its world position is the IK target for the leg chain.
- **MCH_SWITCH_Foot** — Copy Transforms from MCH_IK_Foot (influence 1 when IK mode is on) and from FK_Foot (influence 0).
- **ORG_Foot** — Copy Transforms from MCH_SWITCH_Foot in WORLD space. The final deform bone.

**To tilt feet forward:** Set `FOOT_ROLL.{side}.rotation_euler = Euler((π/2, 0, 0), 'XYZ')` — 90° around X.

**IMPORTANT:** Rotating FOOT_ROLL shifts MCH_IK_Foot's world position, which changes where the IK solver places the foot. After rotating FOOT_ROLL, you MUST compensate by adjusting IK_LEG position:
```python
# 1. Rotate feet to point forward
bones["FOOT_ROLL.L"].rotation_euler = Euler((math.radians(90), 0, 0), 'XYZ')
bones["FOOT_ROLL.R"].rotation_euler = Euler((math.radians(90), 0, 0), 'XYZ')
bpy.context.view_layer.update()

# 2. Measure the foot position shift
foot = bone_world_pos("ORG_Foot.L")
dy = target_y - foot.y  # ~-0.752 (foot moves back toward hip)
dz = target_z - foot.z  # ~-0.246 (foot moves up)

# 3. Push IK_LEG further out to compensate
ik = bone_world_pos("IK_LEG.L")
set_ik_world("IK_LEG.L", Vector((ik.x, ik.y + dy, ik.z + dz)))
```

**Current compensation values** (for straight legs at Z=0):
- IK_LEG at Y=-3.472, Z=-0.246 → resulting foot at Y=-2.720, Z=0.000
- POLE_LEG at Y=-2.000, Z=0.000 (aligned with leg direction)

---

## 8. Blender 5.1 API Notes

- Use `bpy.context.temp_override(area=area)` for context-sensitive operators.
- `MeshLoopTriangle.select` — removed. Use `MeshPolygon.select`.
- `MeshPolygon.loop_triangles` — removed. Count tris: `len(poly.vertices) - 2`.
- `SceneEEVEE.shadow_cube_size` — removed. Use `use_raytracing` + ray tracing settings.
- `SceneEEVEE.shadow_cascade_size` — removed. Same as above.
- `SceneEEVEE.use_ssr` — removed. Screen-space reflections unavailable in 5.1.
- `SceneEEVEE.use_raytracing` — **replacement** for legacy shadow map quality.
- `bpy.context.scene.world` may be `None` — always null-check before accessing `.name` or `.node_tree`.
- FBX export: `use_tspace=True` for normal map tangents.
- `axis_forward="-Z"`, `axis_up="Y"` for Roblox coordinate system.

---

## 9. Project Context

- **Repo:** `/home/willi/Documents/GearRNG` — git, main branch
- **Roblox game:** "Gear RNG" — loot/rng simulator
- **Main menu scene:** Character sitting under a tree in a grassy field at golden hour
- **All UI uses React** (jsdotlua/react@17.2.1) — no native Instance.new()
- **FBX imports strip materials** — MenuSceneBuilder.lua re-applies Color + Material + SurfaceAppearance

---

## 10. Git Workflow

```bash
cd /home/willi/Documents/GearRNG
git add assets/MenuScene.blend assets/MenuScene.fbx assets/BLENDER_POSING_REFERENCE.md
git commit -m "Repose character: straight legs flat on ground, feet pointing forward, hands on ground"
# Co-Authored-By: Claude <noreply@anthropic.com>
```

`*.blend1`, `*.blend2`, and `assets/viewport_*.png` are gitignored.
