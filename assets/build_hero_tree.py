"""
HeroTree Builder — Run directly in Blender's Scripting workspace.
Open this file (Text Editor > Open), press Run Script (or Alt+P).
Tweak the SETTINGS section below, re-run until it looks right.
"""
import bpy
import math
import random
import os

# ═══════════════════════════════════════════════════════════════
# SETTINGS — tweak these and re-run
# ═══════════════════════════════════════════════════════════════
TRUNK_WIDTH = 1.2        # X/Y thickness of trunk (meters)
TRUNK_HEIGHT = 10.0      # Total trunk height
TRUNK_BEVEL = 0.08       # Edge rounding amount
TRUNK_SUBDIV = 2         # Subdivision levels for smoothness

BRANCH_COUNT = 12        # Number of branches
BRANCH_START_Z = 2.0     # Lowest branch height
BRANCH_END_Z = 8.5       # Highest branch height
BRANCH_MIN_LENGTH = 0.7
BRANCH_MAX_LENGTH = 3.0
BRANCH_MIN_RADIUS = 0.05
BRANCH_MAX_RADIUS = 0.12
BRANCH_UP_ANGLE = 45     # Degrees upward from horizontal

FOLIAGE_PER_TIP = 2      # Ico_spheres per branch tip
FOLIAGE_MIN_R = 0.4
FOLIAGE_MAX_R = 0.65
FOLIAGE_SUBDIV = 3       # 2=162tris, 3=642tris

CROWN_COUNT = 10
CROWN_MIN_R = 0.5
CROWN_MAX_R = 1.0
CROWN_Z_BASE = 9.0

SEED = 42
AUTO_DECIMATE = True     # Automatically reduce to fit under 10K tris
EXPORT_PATH = os.path.expanduser("~/Documents/GearRNG/assets/HeroTree.fbx")
SAVE_BLEND = os.path.expanduser("~/Documents/GearRNG/assets/MenuAssets.blend")

# ═══════════════════════════════════════════════════════════════

random.seed(SEED)

def clean_scene():
    """Remove all mesh and curve objects, meshes, materials."""
    for obj in list(bpy.data.objects):
        if obj.type in ('MESH', 'CURVE'):
            bpy.data.objects.remove(obj, do_unlink=True)
    for m in list(bpy.data.meshes):
        bpy.data.meshes.remove(m)
    for m in list(bpy.data.materials):
        bpy.data.materials.remove(m)

def make_material(name, color, roughness=0.5):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get('Principled BSDF')
    if bsdf:
        bsdf.inputs['Base Color'].default_value = color
        bsdf.inputs['Roughness'].default_value = roughness
    return mat

def build_trunk():
    """Thick beveled cube trunk."""
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, TRUNK_HEIGHT/2))
    trunk = bpy.context.object
    trunk.name = 'Trunk'
    trunk.scale = (TRUNK_WIDTH, TRUNK_WIDTH, TRUNK_HEIGHT)
    bpy.ops.object.transform_apply(scale=True)

    # Bevel
    mod = trunk.modifiers.new('Bevel', 'BEVEL')
    mod.width = TRUNK_BEVEL
    mod.segments = 3
    mod.limit_method = 'ANGLE'

    # Subdivision for smoothness
    sub = trunk.modifiers.new('Subdivision', 'SUBSURF')
    sub.levels = TRUNK_SUBDIV
    sub.render_levels = TRUNK_SUBDIV

    # Apply
    bpy.context.view_layer.objects.active = trunk
    for mod in list(trunk.modifiers):
        bpy.ops.object.modifier_apply(modifier=mod.name)

    return trunk

def build_branches(trunk):
    """Cylinder branches attached to trunk, angled outward and up."""
    branches = []
    for i in range(BRANCH_COUNT):
        t = i / (BRANCH_COUNT - 1) if BRANCH_COUNT > 1 else 0.5
        z = BRANCH_START_Z + t * (BRANCH_END_Z - BRANCH_START_Z)
        length = BRANCH_MIN_LENGTH + t * (BRANCH_MAX_LENGTH - BRANCH_MIN_LENGTH)
        radius = BRANCH_MAX_RADIUS - t * (BRANCH_MAX_RADIUS - BRANCH_MIN_RADIUS)
        angle = random.uniform(0, math.pi * 2)
        up = BRANCH_UP_ANGLE + random.uniform(-15, 15)

        bpy.ops.mesh.primitive_cylinder_add(
            vertices=10, radius=radius, depth=length,
            location=(0, 0, z)
        )
        br = bpy.context.object
        br.name = f'Branch_{i:02d}'
        br.parent = trunk

        # Rotate to point outward and upward from trunk surface
        br.rotation_euler = (math.radians(90 - up), 0, angle)

        # Offset to trunk surface + halfway along branch
        surface_r = TRUNK_WIDTH / 2 * 1.05  # Just outside trunk
        half_len = length / 2
        up_r = math.radians(up)
        br.location.x = math.cos(angle) * surface_r + math.cos(angle) * half_len * math.cos(up_r)
        br.location.y = math.sin(angle) * surface_r + math.sin(angle) * half_len * math.cos(up_r)
        br.location.z = z + half_len * math.sin(up_r)

        branches.append((br, angle, length, up))
    return branches

def add_foliage(trunk, branches):
    """Ico_sphere clusters at branch tips and crown."""
    for br, angle, length, up in branches:
        # Tip position in world space
        up_r = math.radians(up)
        tip_x = br.location.x + math.cos(angle) * length * 0.35 * math.cos(up_r)
        tip_y = br.location.y + math.sin(angle) * length * 0.35 * math.cos(up_r)
        tip_z = br.location.z + length * 0.35 * math.sin(up_r)

        for j in range(FOLIAGE_PER_TIP):
            r = random.uniform(FOLIAGE_MIN_R, FOLIAGE_MAX_R)
            bpy.ops.mesh.primitive_ico_sphere_add(
                subdivisions=FOLIAGE_SUBDIV, radius=r,
                location=(
                    tip_x + random.uniform(-0.2, 0.2),
                    tip_y + random.uniform(-0.2, 0.2),
                    tip_z + random.uniform(-0.1, 0.3)
                )
            )
            f = bpy.context.object
            f.name = f'Foliage_B{br.name[-2:]}_{j}'
            f.scale = (
                random.uniform(0.8, 1.3),
                random.uniform(0.8, 1.3),
                random.uniform(0.9, 1.4)
            )
            f.rotation_euler = (
                random.uniform(0, math.pi * 2),
                random.uniform(0, math.pi * 2),
                random.uniform(0, math.pi * 2)
            )
            f.parent = trunk

    # Crown
    for i in range(CROWN_COUNT):
        x = random.uniform(-0.5, 0.5)
        y = random.uniform(-0.5, 0.5)
        z = CROWN_Z_BASE + random.uniform(-0.5, 1.5)
        r = random.uniform(CROWN_MIN_R, CROWN_MAX_R)
        bpy.ops.mesh.primitive_ico_sphere_add(
            subdivisions=FOLIAGE_SUBDIV, radius=r,
            location=(x, y, z)
        )
        f = bpy.context.object
        f.name = f'Foliage_C{i:02d}'
        f.scale = (
            random.uniform(0.8, 1.3),
            random.uniform(0.8, 1.3),
            random.uniform(0.9, 1.5)
        )
        f.rotation_euler = (
            random.uniform(0, math.pi * 2),
            random.uniform(0, math.pi * 2),
            random.uniform(0, math.pi * 2)
        )
        f.parent = trunk

def count_tris(trunk):
    """Return total triangle count for trunk + all children."""
    total = 0
    for obj in [trunk] + list(trunk.children_recursive):
        if obj.type == 'MESH':
            obj.data.calc_loop_triangles()
            total += len(obj.data.loop_triangles)
    return total

def export_fbx(trunk):
    """Export trunk + all children as FBX."""
    bpy.ops.object.select_all(action='DESELECT')
    def select_recursive(obj):
        obj.select_set(True)
        for child in obj.children:
            select_recursive(child)
    select_recursive(trunk)
    bpy.context.view_layer.objects.active = trunk

    os.makedirs(os.path.dirname(EXPORT_PATH), exist_ok=True)
    bpy.ops.export_scene.fbx(
        filepath=EXPORT_PATH,
        use_selection=True,
        axis_forward='-Z',
        axis_up='Y',
        apply_unit_scale=True,
        apply_scale_options='FBX_SCALE_ALL',
        mesh_smooth_type='OFF',
        use_tspace=True,
    )
    print(f'Exported: {EXPORT_PATH} ({os.path.getsize(EXPORT_PATH)} bytes)')

# ═══════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════

print('=' * 60)
print('HeroTree Builder')
print('=' * 60)

# Clean
clean_scene()
print('Scene cleaned.')

# Materials
bark = make_material('Bark', (0.15, 0.09, 0.04, 1.0), 0.85)
leaf = make_material('Leaves', (0.08, 0.50, 0.12, 1.0), 0.5)
print('Materials created.')

# Build
trunk = build_trunk()
trunk.data.materials.append(bark)
print(f'Trunk: {len(trunk.data.vertices)} verts')

branches = build_branches(trunk)
for br, _, _, _ in branches:
    br.data.materials.append(bark)
print(f'Branches: {len(branches)}')

add_foliage(trunk, branches)
print(f'Foliage added.')

# Stats
tris = count_tris(trunk)
children = len(trunk.children)
print(f'Total: {tris} tris, {children} children')

# Assign leaf material to all foliage
for obj in trunk.children_recursive:
    if obj.type == 'MESH' and 'Foliage' in obj.name:
        obj.data.materials.clear()
        obj.data.materials.append(leaf)

# Export if under 10K (or auto-decimate)
if AUTO_DECIMATE and tris > 10000:
    print(f'Decimating from {tris} tris...')
    bpy.ops.object.select_all(action='DESELECT')
    def select_recursive(obj):
        obj.select_set(True)
        for child in obj.children:
            select_recursive(child)
    select_recursive(trunk)
    bpy.context.view_layer.objects.active = trunk
    mod = trunk.modifiers.new('Decimate', 'DECIMATE')
    mod.decimate_type = 'COLLAPSE'
    mod.ratio = 9500.0 / tris
    mod.use_collapse_triangulate = True
    bpy.ops.object.modifier_apply(modifier='Decimate')
    tris = count_tris(trunk)
    print(f'After decimate: {tris} tris')

if tris <= 10000:
    export_fbx(trunk)
    if SAVE_BLEND:
        os.makedirs(os.path.dirname(SAVE_BLEND), exist_ok=True)
        bpy.ops.wm.save_as_mainfile(filepath=SAVE_BLEND)
        print(f'Saved: {SAVE_BLEND}')
else:
    print(f'WARNING: {tris} tris exceeds 10K limit. Reduce settings and re-run.')

print('Done!')
