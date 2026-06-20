"""
Split HeroTree mesh into Roblox-compatible <20k triangle bands.
Run this in Blender's Scripting tab after opening Tree.blend.

Strategy:
  - Select the tree mesh (not the curve, not leaves)
  - Split into 4 horizontal Z-bands, each under 18k tris
  - Export each as FBX to assets/

Usage:
  1. Open Tree.blend in Blender
  2. Switch to Scripting workspace
  3. Paste this script and Run Script
"""
import bpy
import os
import math

OUTPUT_DIR = os.path.dirname(bpy.data.filepath) or "/home/willi/Documents/GearRNG/assets"
TRI_LIMIT = 18000  # Under Roblox's 20k limit

def get_tree_mesh():
    """Find the tree mesh object (not the curve, not leaves)."""
    # Sapling creates a curve for trunk/branches. If it's still a curve,
    # the user needs to convert it first.
    for obj in bpy.data.objects:
        if obj.type == 'MESH' and 'leaf' not in obj.name.lower():
            # The larger mesh is the tree body
            mesh = obj.data
            if len(mesh.polygons) > 1000:
                return obj
    # Fallback: maybe it's still a curve
    for obj in bpy.data.objects:
        if obj.type == 'CURVE':
            return obj  # Will convert below
    return None

def convert_curve_to_mesh(curve_obj):
    """Convert sapling curve to mesh."""
    bpy.context.view_layer.objects.active = curve_obj
    curve_obj.select_set(True)
    bpy.ops.object.convert(target='MESH')
    return bpy.context.active_object

def split_by_ztri(obj, tri_limit=TRI_LIMIT):
    """
    Split mesh into bands by Z-height, each under tri_limit.
    Uses vertex groups to track which vertices belong to each band.
    Returns list of separated objects.
    """
    mesh = obj.data
    total_tris = len(mesh.polygons)

    # Get Z bounds
    verts = [v.co for v in mesh.vertices]
    z_min = min(v.z for v in verts)
    z_max = max(v.z for v in verts)
    z_range = z_max - z_min
    z_mid = (z_min + z_max) / 2

    print(f"Tree mesh: {total_tris:,} tris, Z range: {z_min:.1f} to {z_max:.1f}")

    if total_tris <= tri_limit:
        print("Mesh already under limit — no split needed.")
        return [obj]

    # Build vertex→face mapping to count tris per Z-slice
    vtx_tri_count = [0] * len(mesh.vertices)
    for poly in mesh.polygons:
        for vi in poly.vertices:
            vtx_tri_count[vi] += 1

    # Scan Z from bottom to top, accumulating tris until we hit tri_limit
    bands = []
    current_band_verts = set()
    current_tris = 0
    z_step = z_range / 200  # fine-grained scanning

    # Strategy: split at Z points where cumulative tris ≈ tri_limit
    # Simpler approach — split into equal Z-chunks, measure tris, adjust

    # Actually, the simplest reliable approach:
    # Split into N equal bands, N = ceil(total_tris / tri_limit)
    num_bands = math.ceil(total_tris / tri_limit)
    band_height = z_range / num_bands

    print(f"Splitting into {num_bands} bands of ~{band_height:.1f} units each")

    pieces = []
    for i in range(num_bands):
        z_lo = z_min + i * band_height
        z_hi = z_min + (i + 1) * band_height
        if i == num_bands - 1:
            z_hi = z_max + 0.01  # ensure we get the top

        # Duplicate and separate
        bpy.ops.object.select_all(action='DESELECT')
        obj.select_set(True)
        bpy.context.view_layer.objects.active = obj

        # Enter edit mode, select by Z
        bpy.ops.object.mode_set(mode='EDIT')
        bpy.ops.mesh.select_all(action='DESELECT')
        bpy.ops.object.mode_set(mode='OBJECT')

        # Select vertices in Z range
        for v in mesh.vertices:
            if z_lo <= v.co.z <= z_hi:
                v.select = True

        bpy.ops.object.mode_set(mode='EDIT')

        # Separate selected
        try:
            bpy.ops.mesh.separate(type='SELECTED')
        except RuntimeError:
            pass  # Nothing selected or all selected

        bpy.ops.object.mode_set(mode='OBJECT')

        # The new object is the separated piece
        new_obj = bpy.context.selected_objects[-1] if bpy.context.selected_objects else None
        if new_obj and new_obj != obj:
            new_obj.name = f"Tree_Band_{i+1:02d}"
            piece_tris = len(new_obj.data.polygons)
            print(f"  Band {i+1}: {piece_tris:,} tris")
            pieces.append(new_obj)

    return pieces

def export_pieces(pieces):
    """Export each piece as FBX."""
    paths = []
    for piece in pieces:
        bpy.ops.object.select_all(action='DESELECT')
        piece.select_set(True)

        path = os.path.join(OUTPUT_DIR, f"{piece.name}.fbx")
        bpy.ops.export_scene.fbx(
            filepath=path,
            use_selection=True,
            mesh_smooth_type='OFF',
            use_mesh_modifiers=False,
        )
        paths.append(path)
        print(f"  Exported: {path}")
    return paths

# ── Main ──────────────────────────────────────────────────────
def main():
    print("=" * 60)
    print("GearRNG Tree Splitter")
    print("=" * 60)

    obj = get_tree_mesh()
    if not obj:
        print("ERROR: No tree mesh found. Is Tree.blend open?")
        return

    # Convert curve to mesh if needed
    if obj.type == 'CURVE':
        print("Converting curve to mesh...")
        obj = convert_curve_to_mesh(obj)

    pieces = split_by_ztri(obj)

    if len(pieces) <= 1:
        print("Tree is already under the triangle limit.")
        # Export single piece
        pieces[0].name = "Tree"
        export_pieces(pieces)
        return

    exported = export_pieces(pieces)
    print(f"\nDone! {len(exported)} files saved to {OUTPUT_DIR}")
    print("Import each .fbx into Roblox Studio and place at the same position.")

main()
