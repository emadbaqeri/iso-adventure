#!/usr/bin/env python3
"""
Procedural low-poly Warden for Ashfrost (headless: blender -b -P tools/blender/build_warden.py).
Exports res://assets/characters/warden/warden.glb (~1.8 m, mesh faces -Y / Godot -Z forward).
"""

from __future__ import annotations

import math
import os
import struct
import zlib
from pathlib import Path

import bpy
import bmesh
from mathutils import Matrix, Vector

SCRIPT_DIR = Path(bpy.data.filepath).parent if bpy.data.filepath else Path(__file__).resolve().parent
if not (SCRIPT_DIR / "palette.png").exists():
    SCRIPT_DIR = Path(__file__).resolve().parent

ROOT = SCRIPT_DIR.parent.parent
PALETTE_PATH = SCRIPT_DIR / "palette.png"
EXPORT_DIR = ROOT / "assets" / "characters" / "warden"
EXPORT_PATH = EXPORT_DIR / "warden.glb"

PALETTE_COLS = 8
PALETTE_ROWS = 4
TEX_W = 256
TEX_H = 128

# (col, row) swatches — Ashfrost warden palette
SW = {
    "cloak": (0, 0),
    "cloak_dark": (1, 0),
    "fur": (2, 0),
    "skin": (3, 0),
    "hood": (4, 0),
    "belt": (5, 0),
    "metal": (6, 0),
    "boot": (7, 0),
    "pants": (0, 1),
    "glove": (1, 1),
    "trim": (2, 1),
    "shadow": (3, 1),
}

# RGBA swatch colors (flat low-poly)
SWATCH_RGB = [
    (0.22, 0.28, 0.38, 1.0),  # cloak
    (0.14, 0.18, 0.26, 1.0),  # cloak_dark
    (0.78, 0.76, 0.72, 1.0),  # fur
    (0.55, 0.48, 0.42, 1.0),  # skin
    (0.18, 0.22, 0.30, 1.0),  # hood
    (0.32, 0.24, 0.16, 1.0),  # belt
    (0.62, 0.52, 0.28, 1.0),  # metal
    (0.12, 0.12, 0.14, 1.0),  # boot
    (0.26, 0.30, 0.38, 1.0),  # pants
    (0.20, 0.24, 0.30, 1.0),  # glove
    (0.42, 0.36, 0.30, 1.0),  # trim
    (0.10, 0.12, 0.16, 1.0),  # shadow
]


def _write_palette_png(path: Path) -> None:
    """Minimal PNG writer (no Pillow) for palette swatches."""
    path.parent.mkdir(parents=True, exist_ok=True)
    cw = TEX_W // PALETTE_COLS
    ch = TEX_H // PALETTE_ROWS
    rows = []
    for py in range(TEX_H):
        row = bytearray()
        for px in range(TEX_W):
            col = px // cw
            row_i = py // ch
            idx = row_i * PALETTE_COLS + col
            if idx >= len(SWATCH_RGB):
                idx = 0
            r, g, b, _a = SWATCH_RGB[idx]
            row.extend(
                (
                    int(r * 255),
                    int(g * 255),
                    int(b * 255),
                    255,
                )
            )
        rows.append(bytes(row))

    def _chunk(tag: bytes, data: bytes) -> bytes:
        crc = zlib.crc32(tag + data) & 0xFFFFFFFF
        return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", crc)

    raw = b"".join(b"\x00" + rows[y] for y in range(TEX_H))
    compressed = zlib.compress(raw, 9)
    ihdr = struct.pack(">IIBBBBB", TEX_W, TEX_H, 8, 6, 0, 0, 0)
    png = b"\x89PNG\r\n\x1a\n" + _chunk(b"IHDR", ihdr) + _chunk(b"IDAT", compressed) + _chunk(b"IEND", b"")
    path.write_bytes(png)


def _uv_center(col: int, row: int) -> tuple[float, float]:
    cw = 1.0 / PALETTE_COLS
    rh = 1.0 / PALETTE_ROWS
    u = (col + 0.5) * cw
    v = 1.0 - (row + 0.5) * rh
    return u, v


def _box_bmesh(
    bm: bmesh.types.BMesh,
    size: Vector,
    loc: Vector,
    swatch: tuple[int, int],
) -> None:
    bmesh.ops.create_cube(bm, size=1.0)
    verts = bm.verts[-8:]
    for v in verts:
        v.co = Vector(
            (
                (v.co.x * size.x * 0.5) + loc.x,
                (v.co.y * size.y * 0.5) + loc.y,
                (v.co.z * size.z * 0.5) + loc.z,
            )
        )
    u, v = _uv_center(*swatch)
    uv_layer = bm.loops.layers.uv.verify()
    for face in bm.faces[-6:]:
        for loop in face.loops:
            loop[uv_layer].uv = (u, v)


def _clear_scene() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for block in bpy.data.meshes:
        bpy.data.meshes.remove(block)
    for block in bpy.data.armatures:
        bpy.data.armatures.remove(block)
    for block in bpy.data.materials:
        bpy.data.materials.remove(block)
    for block in bpy.data.images:
        bpy.data.images.remove(block)
    for block in bpy.data.actions:
        bpy.data.actions.remove(block)


def _make_palette_material() -> bpy.types.Material:
    img_path = str(PALETTE_PATH)
    if not PALETTE_PATH.exists():
        _write_palette_png(PALETTE_PATH)
    mat = bpy.data.materials.new("WardenPalette")
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    nodes.clear()
    out = nodes.new("ShaderNodeOutputMaterial")
    bsdf = nodes.new("ShaderNodeBsdfPrincipled")
    tex = nodes.new("ShaderNodeTexImage")
    tex.image = bpy.data.images.load(img_path)
    tex.interpolation = "Closest"
    links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    bsdf.inputs["Roughness"].default_value = 1.0
    bsdf.inputs["Specular IOR Level"].default_value = 0.0
    links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    return mat


def _mesh_from_bmesh(bm: bmesh.types.BMesh, name: str, mat: bpy.types.Material) -> bpy.types.Object:
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    if obj.data.materials:
        obj.data.materials[0] = mat
    else:
        obj.data.materials.append(mat)
    return obj


def _build_body_mesh(mat: bpy.types.Material) -> bpy.types.Object:
    bm = bmesh.new()
    # Facing -Y (Godot -Z forward). Z up, ~1.8 m tall.
    _box_bmesh(bm, Vector((0.42, 0.32, 0.52)), Vector((0, 0, 0.98)), SW["cloak"])
    _box_bmesh(bm, Vector((0.48, 0.36, 0.22)), Vector((0, 0, 1.38)), SW["cloak"])
    _box_bmesh(bm, Vector((0.52, 0.40, 0.18)), Vector((0, 0.02, 1.58)), SW["hood"])
    _box_bmesh(bm, Vector((0.38, 0.34, 0.14)), Vector((0, -0.04, 1.68)), SW["hood"])
    _box_bmesh(bm, Vector((0.50, 0.08, 0.10)), Vector((0, -0.02, 1.72)), SW["fur"])
    _box_bmesh(bm, Vector((0.54, 0.44, 0.12)), Vector((0, 0.04, 1.48)), SW["fur"])
    _box_bmesh(bm, Vector((0.22, 0.18, 0.24)), Vector((0.28, 0, 1.12)), SW["cloak_dark"])
    _box_bmesh(bm, Vector((0.22, 0.18, 0.24)), Vector((-0.28, 0, 1.12)), SW["cloak_dark"])
    _box_bmesh(bm, Vector((0.14, 0.14, 0.22)), Vector((0.34, 0, 0.72)), SW["pants"])
    _box_bmesh(bm, Vector((0.14, 0.14, 0.22)), Vector((-0.34, 0, 0.72)), SW["pants"])
    _box_bmesh(bm, Vector((0.16, 0.20, 0.24)), Vector((0.34, 0, 0.38)), SW["boot"])
    _box_bmesh(bm, Vector((0.16, 0.20, 0.24)), Vector((-0.34, 0, 0.38)), SW["boot"])
    _box_bmesh(bm, Vector((0.44, 0.10, 0.08)), Vector((0, 0, 0.88)), SW["belt"])
    _box_bmesh(bm, Vector((0.10, 0.08, 0.06)), Vector((0.12, -0.02, 0.88)), SW["metal"])
    _box_bmesh(bm, Vector((0.12, 0.12, 0.28)), Vector((0.42, 0, 1.02)), SW["glove"])
    _box_bmesh(bm, Vector((0.12, 0.12, 0.28)), Vector((-0.42, 0, 1.02)), SW["glove"])
    _box_bmesh(bm, Vector((0.10, 0.10, 0.10)), Vector((0, -0.06, 1.64)), SW["skin"])
    # Cloak panels & fur trim (iso-readable silhouette)
    for side in (-1.0, 1.0):
        _box_bmesh(bm, Vector((0.10, 0.28, 0.46)), Vector((side * 0.30, 0.06, 0.78)), SW["cloak"])
        _box_bmesh(bm, Vector((0.08, 0.22, 0.38)), Vector((side * 0.34, 0.10, 0.52)), SW["cloak_dark"])
        _box_bmesh(bm, Vector((0.06, 0.06, 0.12)), Vector((side * 0.36, 0.12, 0.32)), SW["boot"])
        _box_bmesh(bm, Vector((0.14, 0.08, 0.10)), Vector((side * 0.22, -0.02, 1.50)), SW["fur"])
        _box_bmesh(bm, Vector((0.12, 0.08, 0.08)), Vector((side * 0.18, -0.04, 1.62)), SW["fur"])
    for z in (1.12, 0.98, 0.84):
        _box_bmesh(bm, Vector((0.56, 0.06, 0.06)), Vector((0, 0.10, z)), SW["fur"])
        _box_bmesh(bm, Vector((0.56, 0.06, 0.06)), Vector((0, -0.10, z)), SW["fur"])
    _box_bmesh(bm, Vector((0.20, 0.14, 0.18)), Vector((0, -0.14, 1.02)), SW["cloak_dark"])
    _box_bmesh(bm, Vector((0.18, 0.12, 0.14)), Vector((0, -0.18, 0.86)), SW["shadow"])
    _box_bmesh(bm, Vector((0.16, 0.10, 0.10)), Vector((0.20, 0, 1.30)), SW["trim"])
    _box_bmesh(bm, Vector((0.16, 0.10, 0.10)), Vector((-0.20, 0, 1.30)), SW["trim"])
    _box_bmesh(bm, Vector((0.10, 0.08, 0.20)), Vector((0.46, 0, 1.18)), SW["glove"])
    _box_bmesh(bm, Vector((0.10, 0.08, 0.20)), Vector((-0.46, 0, 1.18)), SW["glove"])
    _box_bmesh(bm, Vector((0.12, 0.16, 0.10)), Vector((0.14, 0, 0.48)), SW["boot"])
    _box_bmesh(bm, Vector((0.12, 0.16, 0.10)), Vector((-0.14, 0, 0.48)), SW["boot"])
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.0001)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return _mesh_from_bmesh(bm, "WardenMesh", mat)


def _create_armature() -> bpy.types.Object:
    bpy.ops.object.armature_add(enter_editmode=True, location=(0, 0, 0))
    arm_obj = bpy.context.active_object
    arm_obj.name = "WardenArmature"
    arm = arm_obj.data
    arm.name = "WardenArmature"
    eb = arm.edit_bones

    def bone(name: str, head: Vector, tail: Vector, parent: bpy.types.EditBone | None = None) -> bpy.types.EditBone:
        b = eb.new(name)
        b.head = head
        b.tail = tail
        if parent:
            b.parent = parent
        return b

    hips = bone("hips", Vector((0, 0, 0.92)), Vector((0, 0, 1.02)))
    spine = bone("spine", Vector((0, 0, 1.02)), Vector((0, 0, 1.22)), hips)
    chest = bone("chest", Vector((0, 0, 1.22)), Vector((0, 0, 1.42)), spine)
    head = bone("head", Vector((0, 0, 1.42)), Vector((0, 0, 1.72)), chest)
    arm_l = bone("upper_arm.L", Vector((0.18, 0, 1.38)), Vector((0.38, 0, 1.28)), chest)
    fore_l = bone("lower_arm.L", Vector((0.38, 0, 1.28)), Vector((0.52, 0, 1.12)), arm_l)
    arm_r = bone("upper_arm.R", Vector((-0.18, 0, 1.38)), Vector((-0.38, 0, 1.28)), chest)
    fore_r = bone("lower_arm.R", Vector((-0.38, 0, 1.28)), Vector((-0.52, 0, 1.12)), arm_r)
    leg_l = bone("upper_leg.L", Vector((0.14, 0, 0.92)), Vector((0.14, 0, 0.58)), hips)
    shin_l = bone("lower_leg.L", Vector((0.14, 0, 0.58)), Vector((0.14, 0, 0.12)), leg_l)
    leg_r = bone("upper_leg.R", Vector((-0.14, 0, 0.92)), Vector((-0.14, 0, 0.58)), hips)
    shin_r = bone("lower_leg.R", Vector((-0.14, 0, 0.58)), Vector((-0.14, 0, 0.12)), leg_r)

    bpy.ops.object.mode_set(mode="OBJECT")
    return arm_obj


def _parent_mesh_to_armature(mesh_obj: bpy.types.Object, arm_obj: bpy.types.Object) -> None:
    mesh_obj.select_set(True)
    arm_obj.select_set(True)
    bpy.context.view_layer.objects.active = arm_obj
    bpy.ops.object.parent_set(type="ARMATURE_AUTO")


def _animate_idle(arm_obj: bpy.types.Object) -> bpy.types.Action:
    action = bpy.data.actions.new("idle")
    if arm_obj.animation_data is None:
        arm_obj.animation_data_create()
    arm_obj.animation_data.action = action
    bpy.context.view_layer.objects.active = arm_obj
    bpy.ops.object.mode_set(mode="POSE")
    scene = bpy.context.scene
    scene.frame_start = 0
    scene.frame_end = 48
    spine = arm_obj.pose.bones["spine"]
    head = arm_obj.pose.bones["head"]
    for frame in (0, 24, 48):
        scene.frame_set(frame)
        spine.rotation_mode = "XYZ"
        head.rotation_mode = "XYZ"
        bob = 0.02 if frame == 24 else 0.0
        spine.location = (0, 0, bob)
        head.location = (0, 0, bob * 0.5)
        spine.keyframe_insert(data_path="location", frame=frame)
        head.keyframe_insert(data_path="location", frame=frame)
        spine.rotation_euler = (0.04 if frame == 24 else 0.0, 0, 0)
        head.keyframe_insert(data_path="rotation_euler", frame=frame)
    bpy.ops.object.mode_set(mode="OBJECT")
    return action


def _animate_run(arm_obj: bpy.types.Object) -> bpy.types.Action:
    action = bpy.data.actions.new("run")
    if arm_obj.animation_data is None:
        arm_obj.animation_data_create()
    arm_obj.animation_data.action = action
    bpy.context.view_layer.objects.active = arm_obj
    bpy.ops.object.mode_set(mode="POSE")
    scene = bpy.context.scene
    scene.frame_start = 0
    scene.frame_end = 16
    pairs = [
        ("upper_leg.L", "lower_leg.L"),
        ("upper_leg.R", "lower_leg.R"),
        ("upper_arm.L", "lower_arm.L"),
        ("upper_arm.R", "lower_arm.R"),
    ]
    for frame, phase in ((0, 0.0), (8, 1.0), (16, 0.0)):
        scene.frame_set(frame)
        swing = math.sin(phase * math.pi) * 0.45
        for i, (u, l) in enumerate(pairs):
            sign = 1.0 if i % 2 == 0 else -1.0
            ub = arm_obj.pose.bones[u]
            lb = arm_obj.pose.bones[l]
            ub.rotation_mode = "XYZ"
            lb.rotation_mode = "XYZ"
            ub.rotation_euler = (sign * swing, 0, 0)
            lb.rotation_euler = (sign * swing * 0.6, 0, 0)
            ub.keyframe_insert(data_path="rotation_euler", frame=frame)
            lb.keyframe_insert(data_path="rotation_euler", frame=frame)
        spine = arm_obj.pose.bones["spine"]
        spine.rotation_mode = "XYZ"
        spine.rotation_euler = (0.08, 0, math.sin(phase * math.pi) * 0.04)
        spine.keyframe_insert(data_path="rotation_euler", frame=frame)
    bpy.ops.object.mode_set(mode="OBJECT")
    action.use_fake_user = True
    return action


def _animate_attack(arm_obj: bpy.types.Object) -> bpy.types.Action:
    action = bpy.data.actions.new("attack")
    if arm_obj.animation_data is None:
        arm_obj.animation_data_create()
    arm_obj.animation_data.action = action
    bpy.context.view_layer.objects.active = arm_obj
    bpy.ops.object.mode_set(mode="POSE")
    scene = bpy.context.scene
    scene.frame_start = 0
    scene.frame_end = 12
    fore = arm_obj.pose.bones["lower_arm.R"]
    upper = arm_obj.pose.bones["upper_arm.R"]
    chest = arm_obj.pose.bones["chest"]
    for frame, u_rot, f_rot, c_rot in (
        (0, (0, 0, 0.2), (0, 0, 0), (0, 0, 0)),
        (3, (-0.5, 0, 0.1), (-0.2, 0, 0), (0.1, 0, 0)),
        (5, (0.9, 0, -0.3), (1.2, 0, 0), (0.15, 0, -0.2)),
        (12, (0, 0, 0.2), (0, 0, 0), (0, 0, 0)),
    ):
        scene.frame_set(frame)
        for bone, rot in ((upper, u_rot), (fore, f_rot), (chest, c_rot)):
            bone.rotation_mode = "XYZ"
            bone.rotation_euler = rot
            bone.keyframe_insert(data_path="rotation_euler", frame=frame)
    bpy.ops.object.mode_set(mode="OBJECT")
    action.use_fake_user = True
    return action


def _assign_all_actions(arm_obj: bpy.types.Object) -> None:
    """Push idle / run / attack actions to NLA for glTF export."""
    if arm_obj.animation_data is None:
        arm_obj.animation_data_create()
    for track in list(arm_obj.animation_data.nla_tracks):
        arm_obj.animation_data.nla_tracks.remove(track)
    for fn in (_animate_idle, _animate_run, _animate_attack):
        act = fn(arm_obj)
        track = arm_obj.animation_data.nla_tracks.new()
        track.strips.new(act.name, int(act.frame_range[0]), act)
    arm_obj.animation_data.action = None


def _tri_count(obj: bpy.types.Object) -> int:
    return sum(len(p.loop_indices) // 3 for p in obj.data.polygons) if obj.type == "MESH" else 0


def main() -> None:
    _write_palette_png(PALETTE_PATH)
    _clear_scene()
    mat = _make_palette_material()
    mesh_obj = _build_body_mesh(mat)
    arm_obj = _create_armature()
    _parent_mesh_to_armature(mesh_obj, arm_obj)
    _assign_all_actions(arm_obj)

    tris = _tri_count(mesh_obj)
    print(f"Warden mesh triangles (approx faces): {len(mesh_obj.data.polygons)}")
    if len(mesh_obj.data.polygons) < 200 or len(mesh_obj.data.polygons) > 2500:
        print("WARNING: triangle count outside target band; continuing export.")

    EXPORT_DIR.mkdir(parents=True, exist_ok=True)
    bpy.ops.object.select_all(action="DESELECT")
    mesh_obj.select_set(True)
    arm_obj.select_set(True)
    bpy.context.view_layer.objects.active = arm_obj
    bpy.ops.export_scene.gltf(
        filepath=str(EXPORT_PATH),
        export_format="GLB",
        use_selection=True,
        export_apply=True,
        export_yup=True,
        export_animations=True,
        export_nla_strips=False,
        export_def_bones=True,
        export_skins=True,
        export_materials="EXPORT",
        export_image_format="AUTO",
    )
    import shutil

    dest_palette = EXPORT_DIR / "palette.png"
    shutil.copy2(PALETTE_PATH, dest_palette)
    print(f"Exported {EXPORT_PATH} ({EXPORT_PATH.stat().st_size} bytes)")
    print(f"Copied palette to {dest_palette}")


if __name__ == "__main__":
    main()
