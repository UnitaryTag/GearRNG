#!/usr/bin/env python3
"""
Blender Vision System — programmatic scene description for AI-assisted posing.

Drop this into a Blender Text Editor or exec() it from MCP.
Provides text-based "vision" of the 3D scene so the AI can reason about
pose, composition, and lighting without needing image support.

Usage:
    exec(open("/home/willi/Documents/GearRNG/assets/blender_vision.py").read())
    print(describe_full_scene())
    print(diagnose_issues())
"""

import bpy
from mathutils import Vector, Matrix
import math
import os

ASSETS_DIR = os.path.join(os.path.expanduser("~"), "Documents", "GearRNG", "assets")


# ── World-space bone helpers ──────────────────────────────────────────

def _get_arm():
    return bpy.data.objects.get("Roblox_R15")

def bone_world_pos(bone_name):
    """Return Vector of bone head position in world space."""
    arm = _get_arm()
    if not arm:
        return None
    return (arm.matrix_world @ arm.pose.bones[bone_name].matrix).translation.copy()

def bone_world_tail(bone_name):
    """Return Vector of bone tail position in world space."""
    arm = _get_arm()
    if not arm:
        return None
    pb = arm.pose.bones[bone_name]
    return (arm.matrix_world @ pb.matrix @ Matrix.Translation(pb.bone.tail_local)).translation.copy()


# ── Scene description ─────────────────────────────────────────────────

def describe_full_scene():
    """Generate a comprehensive text description of the visible scene."""
    lines = []

    # Scene objects
    lines.append("=" * 64)
    lines.append("SCENE OBJECTS (visible meshes only)")
    lines.append("=" * 64)
    for obj in sorted(bpy.data.objects, key=lambda o: o.name):
        if obj.type != 'MESH':
            continue
        if obj.hide_viewport or not obj.visible_get():
            continue
        mesh = obj.data
        bbox = [obj.matrix_world @ Vector(v) for v in obj.bound_box]
        xs = [v.x for v in bbox]; ys = [v.y for v in bbox]; zs = [v.z for v in bbox]
        lines.append(
            f"  {obj.name:20s}  "
            f"bbox: X[{min(xs):6.1f}:{max(xs):6.1f}]  "
            f"Y[{min(ys):6.1f}:{max(ys):6.1f}]  "
            f"Z[{min(zs):6.1f}:{max(zs):6.1f}]  "
            f"verts={len(mesh.vertices):,}"
        )

    # Character pose
    lines.append("")
    lines.append("=" * 64)
    lines.append("CHARACTER POSE (world-space bone positions)")
    lines.append("=" * 64)

    arm = _get_arm()
    if arm:
        def _p(b): return bone_world_pos(b)

        lines.append("  Body core:")
        for b in ["ROOT", "LowerTorso", "UpTorso", "UpperTorso", "Head"]:
            p = _p(b)
            lines.append(f"    {b:20s} ({p.x:7.3f}, {p.y:7.3f}, {p.z:7.3f})")

        lines.append("  Arms:")
        for side in ['L', 'R']:
            for b in [f"ORG_UpperArm.{side}", f"ORG_LowerArm.{side}", f"ORG_Hand.{side}"]:
                p = _p(b)
                lines.append(f"    {b:20s} ({p.x:7.3f}, {p.y:7.3f}, {p.z:7.3f})")

        lines.append("  Legs:")
        for side in ['L', 'R']:
            for b in [f"ORG_UpperLeg.{side}", f"ORG_LowerLeg.{side}", f"ORG_Foot.{side}"]:
                p = _p(b)
                lines.append(f"    {b:20s} ({p.x:7.3f}, {p.y:7.3f}, {p.z:7.3f})")

        lines.append("  IK controls:")
        for b in ["IK_Hand.L", "IK_Hand.R", "IK_LEG.L", "IK_LEG.R",
                  "POLE_ARM.L", "POLE_ARM.R", "POLE_LEG.L", "POLE_LEG.R"]:
            p = _p(b)
            lines.append(f"    {b:20s} ({p.x:7.3f}, {p.y:7.3f}, {p.z:7.3f})")

    # Environment
    lines.append("")
    lines.append("=" * 64)
    lines.append("ENVIRONMENT")
    lines.append("=" * 64)

    lights = [obj for obj in bpy.data.objects if obj.type == 'LIGHT']
    if lights:
        for light in lights:
            ld = light.data
            lines.append(
                f"  {light.name:20s} type={ld.type:4s}  energy={ld.energy:5.1f}  "
                f"color=({ld.color[0]:.2f}, {ld.color[1]:.2f}, {ld.color[2]:.2f})"
            )
    else:
        lines.append("  No lights")

    world = bpy.context.scene.world
    if world and world.use_nodes:
        for node in world.node_tree.nodes:
            if node.type == 'BACKGROUND':
                c = node.inputs['Color'].default_value
                s = node.inputs['Strength'].default_value
                lines.append(f"  World: color=({c[0]:.2f}, {c[1]:.2f}, {c[2]:.2f}), strength={s:.2f}")

    cam = bpy.context.scene.camera
    if cam:
        lines.append(f"  Camera: {cam.name}  loc={cam.location}  lens={cam.data.lens}mm")
    lines.append(f"  Render: {bpy.context.scene.render.engine}  "
                 f"{bpy.context.scene.render.resolution_x}x{bpy.context.scene.render.resolution_y}")

    return "\n".join(lines)


# ── Diagnostics ────────────────────────────────────────────────────────

def diagnose_issues():
    """Check pose for common problems: symmetry, ground contact, clipping."""
    arm = _get_arm()
    if not arm:
        return "No Roblox_R15 armature found."

    issues = []
    p = lambda b: bone_world_pos(b)

    # Ground contact
    l_foot_z = p("ORG_Foot.L").z
    r_foot_z = p("ORG_Foot.R").z
    if abs(l_foot_z) > 0.05:
        issues.append(f"⚠ Left foot off ground: Z={l_foot_z:.3f}")
    if abs(r_foot_z) > 0.05:
        issues.append(f"⚠ Right foot off ground: Z={r_foot_z:.3f}")

    l_hand_z = p("ORG_Hand.L").z
    r_hand_z = p("ORG_Hand.R").z
    if abs(l_hand_z) > 0.05:
        issues.append(f"⚠ Left hand off ground: Z={l_hand_z:.3f}")
    if abs(r_hand_z) > 0.05:
        issues.append(f"⚠ Right hand off ground: Z={r_hand_z:.3f}")

    # Knee height
    l_knee = p("ORG_LowerLeg.L").z
    r_knee = p("ORG_LowerLeg.R").z
    if l_knee > 0.3:
        issues.append(f"⚠ Left knee high: Z={l_knee:.3f}")
    if r_knee > 0.3:
        issues.append(f"⚠ Right knee high: Z={r_knee:.3f}")

    # Butt on ground
    hip_z = p("LowerTorso").z
    if abs(hip_z) > 0.01:
        issues.append(f"⚠ Hips not at ground: Z={hip_z:.3f}")

    # Symmetry check
    asym_pairs = [
        ("ORG_Hand.L", "ORG_Hand.R", "x"),
        ("ORG_Foot.L", "ORG_Foot.R", "x"),
        ("ORG_LowerLeg.L", "ORG_LowerLeg.R", "x"),
        ("ORG_LowerArm.L", "ORG_LowerArm.R", "x"),
        ("ORG_UpperArm.L", "ORG_UpperArm.R", "x"),
        ("ORG_UpperLeg.L", "ORG_UpperLeg.R", "x"),
    ]
    for bl, br, axis in asym_pairs:
        lv = abs(getattr(p(bl), axis))
        rv = abs(getattr(p(br), axis))
        if abs(lv - rv) > 0.05:
            issues.append(f"⚠ Asymmetry — {bl} vs {br}: |{axis}| diff={abs(lv-rv):.3f}")

    # Bone-below-ground check (actual clipping, not bbox overlap)
    # Roblox blocky body parts (~1 stud cubes) naturally overlap at joints in
    # a seated pose. Instead, check that no deform bone has sunk below ground.
    deform_bones = [
        "Head", "UpperTorso", "LowerTorso",
        "ORG_Hand.L", "ORG_Hand.R", "ORG_LowerArm.L", "ORG_LowerArm.R",
        "ORG_UpperArm.L", "ORG_UpperArm.R",
        "ORG_Foot.L", "ORG_Foot.R", "ORG_LowerLeg.L", "ORG_LowerLeg.R",
        "ORG_UpperLeg.L", "ORG_UpperLeg.R",
    ]
    for b in deform_bones:
        z = p(b).z
        if z < -0.05:
            issues.append(f"⚠ {b} below ground: Z={z:.3f}")

    # Cross-region mesh interpenetration only — arms vs legs, L vs R arms/legs.
    # These indicate the pose is contorted, not just joint-adjacent overlap.
    cross_region_pairs = [
        ("LeftHand", "LeftLowerLeg"), ("LeftHand", "RightLowerLeg"),
        ("RightHand", "LeftLowerLeg"), ("RightHand", "RightLowerLeg"),
        ("LeftHand", "RightHand"), ("LeftLowerLeg", "RightLowerLeg"),
    ]
    for a_name, b_name in cross_region_pairs:
        a = bpy.data.objects.get(a_name)
        b = bpy.data.objects.get(b_name)
        if not a or not b: continue
        a_bbox = [a.matrix_world @ Vector(v) for v in a.bound_box]
        b_bbox = [b.matrix_world @ Vector(v) for v in b.bound_box]
        if _bbox_overlap(a_bbox, b_bbox, margin=0.12):
            issues.append(f"⚠ Cross-region penetration: {a_name} ∩ {b_name}")

    if not issues:
        return "✓ All diagnostics passed."
    return "\n".join(issues)


def _bbox_overlap(a_bbox, b_bbox, margin=0.02):
    """Check if two bounding boxes overlap (with margin for tolerance)."""
    a_min = Vector((min(v.x for v in a_bbox), min(v.y for v in a_bbox), min(v.z for v in a_bbox)))
    a_max = Vector((max(v.x for v in a_bbox), max(v.y for v in a_bbox), max(v.z for v in a_bbox)))
    b_min = Vector((min(v.x for v in b_bbox), min(v.y for v in b_bbox), min(v.z for v in b_bbox)))
    b_max = Vector((max(v.x for v in b_bbox), max(v.y for v in b_bbox), max(v.z for v in b_bbox)))
    # Shrink boxes by margin
    a_min += Vector((margin, margin, margin))
    a_max -= Vector((margin, margin, margin))
    b_min += Vector((margin, margin, margin))
    b_max -= Vector((margin, margin, margin))
    return (a_min.x < b_max.x and a_max.x > b_min.x and
            a_min.y < b_max.y and a_max.y > b_min.y and
            a_min.z < b_max.z and a_max.z > b_min.z)


# ── Viewport / screenshot ──────────────────────────────────────────────

def save_viewport(filepath=None):
    """Save current 3D viewport screenshot to file."""
    if filepath is None:
        filepath = os.path.join(ASSETS_DIR, "viewport_current.png")
    area = next(a for a in bpy.context.screen.areas if a.type == 'VIEW_3D')
    with bpy.context.temp_override(area=area):
        bpy.ops.screen.screenshot_area(filepath=filepath)
    size_kb = os.path.getsize(filepath) // 1024
    print(f"Viewport saved: {filepath} ({size_kb}KB)")
    return filepath


def save_render(filepath=None):
    """Render current camera view and save to file."""
    if filepath is None:
        filepath = os.path.join(ASSETS_DIR, "render_preview.png")
    bpy.context.scene.render.filepath = filepath
    bpy.ops.render.render(write_still=True)
    size_kb = os.path.getsize(filepath) // 1024
    print(f"Render saved: {filepath} ({size_kb}KB)")
    return filepath


# ── Quick check (run when imported) ────────────────────────────────────

if __name__ == "__main__":
    print(describe_full_scene())
    print("\n" + diagnose_issues())
