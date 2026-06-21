# Blender Posing Reference — MenuScene Character

> **Drop this file into a terminal Claude session at `/home/willi/Documents/GearRNG`.**  
> Say: *"Read assets/BLENDER_POSING_REFERENCE.md, then pose the character sitting."*

---

## 1. The Task

Pose the Roblox R15 blocky character in a **seated pose on the ground** (butt at Z=0, legs extended forward, hands on ground for support). The posed character lives in `MenuScene.blend` and gets exported to `MenuScene.fbx` for Roblox.

**File:** `/home/willi/Documents/GearRNG/assets/MenuScene.blend` — open this in Blender.  
**Output:** Save blend, re-export FBX.

---

## 2. The Rig — MrXen0 Roblox Blocky R15

- **Rig ID:** `xqpb4vnl0zay` (Blender 4.0+)
- **Armature object:** `Roblox_R15` (141 bones)
- **Embedded UI script:** `MrXen0_R15RIGUI_v1.0.py` — text datablock inside the blend file. Contains all IK/FK operators.

### 2.1 Coordinate System

- **Z is UP** (ground plane at Z≈0)
- **Y is FORWARD** (character faces -Y or +Y depending on orientation)
- **X is LEFT/RIGHT**
- 1 Blender unit = 1 Roblox stud

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

### 3.4 Current Pose State (refined 2026-06-20)

**Pose:** Seated on ground, legs extended forward, torso leaned back ~12°, hands on ground behind hips for support.

IK targets in world space:

| Bone | World Position (X, Y, Z) |
|------|--------------------------|
| ROOT | (0, 0, -2.0) |
| LowerTorso | (0, 0, 0) ← butt on ground |
| UpperTorso | (0, 0, 0.4) |
| Head | (0, -0.333, 1.965) ← tilted back from torso lean |
| IK_Hand.L | (-0.55, 0.35, 0.03) ← hand behind hip on ground |
| IK_Hand.R | (0.55, 0.35, 0.03) |
| IK_LEG.L | (-0.45, -1.75, 0.03) ← foot extended forward |
| IK_LEG.R | (0.45, -1.75, 0.03) |
| POLE_ARM.L | (-0.80, 0.45, 0.15) |
| POLE_ARM.R | (0.80, 0.45, 0.15) |
| POLE_LEG.L | (-0.50, -0.70, 0.20) ← knees near ground |
| POLE_LEG.R | (0.50, -0.70, 0.20) |

Deform bone verification:

| ORG Bone | World Position |
|----------|---------------|
| ORG_Foot.L | (-0.450, -1.750, 0.030) |
| ORG_Foot.R | (0.450, -1.750, 0.030) |
| ORG_Hand.L | (-0.550, 0.350, 0.030) |
| ORG_Hand.R | (0.550, 0.350, 0.030) |
| ORG_LowerArm.L | (-0.675, 0.188, 1.060) |
| ORG_LowerArm.R | (0.675, 0.188, 1.060) |
| ORG_LowerLeg.L | (-0.477, -0.821, 0.016) |
| ORG_LowerLeg.R | (0.477, -0.821, 0.016) |
| ORG_UpperArm.L | (-0.999, -0.283, 1.733) |
| ORG_UpperArm.R | (0.999, -0.283, 1.733) |
| ORG_UpperLeg.L | (-0.500, 0.000, 0.000) |
| ORG_UpperLeg.R | (0.500, 0.000, 0.000) |

### 3.5 Torso Control

The torso lean is applied via **UpTorso** bone (rotation around X), which drives UpperTorso through a `COPY_TRANSFORMS` constraint. The `TORSO` bone is the master torso control. Do NOT rotate UpperTorso directly — it will be overwritten by the constraint.

IK hands are parented to ROOT (ARM_IK_PARENT=0), so they stay planted when the torso rotates. This is the correct setup for a hands-on-ground support pose.

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

**"Seated on the ground, leaned back"** — natural, relaxed, hands supporting:
1. **Butt on ground:** LowerTorso at Z=0 (achieved via ROOT at Z=-2.0)
2. **Legs extended forward:** Feet at Y=-1.75, knees near ground (Z=0.016) — achieved by POLE_LEG at Z=0.20
3. **Hands on ground behind hips** for support (Y=+0.35) — achieved with IK_Hand targets behind body
4. **Torso leaned back ~12°** via UpTorso X rotation — shoulders shift back (Y=-0.283), head tilts back
5. **Head tilted back** from torso lean, looking slightly upward
6. **Elbows bent naturally** — arms angle from shoulders (Z=1.73) down to ground (Z=0.03) with elbows at Z=1.06

---

## 7. Blender 5.1 API Notes

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

## 8. Project Context

- **Repo:** `/home/willi/Documents/GearRNG` — git, main branch
- **Roblox game:** "Gear RNG" — loot/rng simulator
- **Main menu scene:** Character sitting under a tree in a grassy field at golden hour
- **All UI uses React** (jsdotlua/react@17.2.1) — no native Instance.new()
- **FBX imports strip materials** — MenuSceneBuilder.lua re-applies Color + Material + SurfaceAppearance

---

## 9. Git Workflow

```bash
cd /home/willi/Documents/GearRNG
git add assets/MenuScene.blend assets/MenuScene.fbx assets/BLENDER_POSING_REFERENCE.md
git commit -m "Refine seated pose: knees flat, hands behind hips, torso leaned back"
# Co-Authored-By: Claude <noreply@anthropic.com>
```

`*.blend1`, `*.blend2`, and `assets/viewport_*.png` are gitignored.
