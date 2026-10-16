#!/usr/bin/env python3
"""
Procedural low-poly environment kit for Ashfrost (headless: blender -b -P tools/blender/build_env_kit.py).
Modular pieces on a 2 m grid; UV-snapped to tools/blender/palette.png. Exports GLBs to assets/env/.
"""

from __future__ import annotations

import math
import struct
import sys
import zlib
from pathlib import Path
from typing import Callable

import bpy
import bmesh
from mathutils import Vector

SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

from palette_data import PALETTE_COLS, PALETTE_ROWS, SW, SWATCH_RGB, TEX_H, TEX_W  # noqa: E402

ROOT = SCRIPT_DIR.parent.parent
PALETTE_PATH = SCRIPT_DIR / "palette.png"
EXPORT_DIR = ROOT / "assets" / "env"

GRID = 2.0
WALL_H = 2.4
WALL_D = 1.2


def _write_palette_png(path: Path) -> None:
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
            row.extend((int(r * 255), int(g * 255), int(b * 255), 255))
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


def _swatch_uv(name: str) -> tuple[float, float]:
    c, r = SW[name]
    return _uv_center(c, r)


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


def _cone_tier(bm: bmesh.types.BMesh, radius: float, height: float, z_base: float, swatch: str, snow: bool = False) -> None:
    segments = 6
    bottom = [Vector((math.cos(2 * math.pi * i / segments) * radius, math.sin(2 * math.pi * i / segments) * radius, z_base)) for i in range(segments)]
    top = Vector((0, 0, z_base + height))
    verts = [bm.verts.new(p) for p in bottom]
    apex = bm.verts.new(top)
    sw = SW[swatch]
    u, v = _uv_center(*sw)
    uv_layer = bm.loops.layers.uv.verify()
    for i in range(segments):
        face = bm.faces.new((verts[i], verts[(i + 1) % segments], apex))
        for loop in face.loops:
            loop[uv_layer].uv = (u, v)
    if snow:
        snow_z = z_base + height * 0.92
        _box_bmesh(bm, Vector((radius * 1.1, radius * 1.1, height * 0.12)), Vector((0, 0, snow_z)), SW["snow"])


def _clear_scene() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for block in list(bpy.data.meshes):
        bpy.data.meshes.remove(block)
    for block in list(bpy.data.materials):
        bpy.data.materials.remove(block)
    for block in list(bpy.data.images):
        bpy.data.images.remove(block)


def _make_palette_material() -> bpy.types.Material:
    img_path = str(PALETTE_PATH)
    mat = bpy.data.materials.new("EnvPalette")
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
    obj.data.materials.append(mat)
    return obj


def _join_objects(objs: list[bpy.types.Object], name: str) -> bpy.types.Object:
    if len(objs) == 1:
        objs[0].name = name
        return objs[0]
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.object.join()
    joined = bpy.context.active_object
    joined.name = name
    return joined


def _export_glb(obj: bpy.types.Object, filename: str) -> None:
    EXPORT_DIR.mkdir(parents=True, exist_ok=True)
    path = EXPORT_DIR / filename
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.export_scene.gltf(
        filepath=str(path),
        export_format="GLB",
        use_selection=True,
        export_apply=True,
        export_yup=True,
        export_animations=False,
        export_materials="EXPORT",
        export_image_format="AUTO",
    )
    print(f"Exported {path} ({path.stat().st_size} bytes)")


def _build_floor_tile(variant: int, mat: bpy.types.Material) -> bpy.types.Object:
    bm = bmesh.new()
    h = 0.12
    _box_bmesh(bm, Vector((GRID, GRID, h)), Vector((0, 0, h * 0.5)), SW["stone_mid"])
    if variant == 0:
        _box_bmesh(bm, Vector((0.6, 0.6, 0.04)), Vector((0.5, 0.3, h + 0.02)), SW["stone_light"])
        _box_bmesh(bm, Vector((0.5, 0.5, 0.04)), Vector((-0.6, -0.5, h + 0.02)), SW["stone_dark"])
    else:
        _box_bmesh(bm, Vector((1.2, 0.35, 0.04)), Vector((0, -0.7, h + 0.02)), SW["stone_dark"])
        _box_bmesh(bm, Vector((0.35, 1.0, 0.04)), Vector((0.7, 0.5, h + 0.02)), SW["stone_moss"])
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.0001)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return _mesh_from_bmesh(bm, "floor_tile", mat)


def _build_wall_straight(mat: bpy.types.Material) -> bpy.types.Object:
    bm = bmesh.new()
    _box_bmesh(bm, Vector((GRID, WALL_D, WALL_H)), Vector((0, 0, WALL_H * 0.5)), SW["stone_mid"])
    _box_bmesh(bm, Vector((GRID, 0.08, 0.12)), Vector((0, WALL_D * 0.5 + 0.04, WALL_H - 0.06)), SW["stone_light"])
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.0001)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return _mesh_from_bmesh(bm, "wall_straight", mat)


def _build_wall_corner(mat: bpy.types.Material) -> bpy.types.Object:
    bm = bmesh.new()
    _box_bmesh(bm, Vector((GRID, WALL_D, WALL_H)), Vector((GRID * 0.25, 0, WALL_H * 0.5)), SW["stone_mid"])
    _box_bmesh(bm, Vector((WALL_D, GRID, WALL_H)), Vector((0, GRID * 0.25, WALL_H * 0.5)), SW["stone_dark"])
    _box_bmesh(bm, Vector((0.5, 0.5, WALL_H)), Vector((0, 0, WALL_H * 0.5)), SW["stone_light"])
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.0001)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return _mesh_from_bmesh(bm, "wall_corner", mat)


def _build_wall_broken(mat: bpy.types.Material) -> bpy.types.Object:
    bm = bmesh.new()
    _box_bmesh(bm, Vector((GRID, WALL_D, WALL_H * 0.75)), Vector((0, 0, WALL_H * 0.375)), SW["stone_mid"])
    _box_bmesh(bm, Vector((0.8, WALL_D, 0.5)), Vector((0.5, 0, WALL_H * 0.75 + 0.25)), SW["stone_dark"])
    _box_bmesh(bm, Vector((0.6, 0.6, 0.4)), Vector((-0.5, 0, WALL_H * 0.85)), SW["stone_light"])
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.0001)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return _mesh_from_bmesh(bm, "wall_broken", mat)


def _build_pillar(mat: bpy.types.Material) -> bpy.types.Object:
    bm = bmesh.new()
    _box_bmesh(bm, Vector((0.6, 0.6, WALL_H)), Vector((0, 0, WALL_H * 0.5)), SW["stone_mid"])
    _box_bmesh(bm, Vector((0.75, 0.75, 0.2)), Vector((0, 0, WALL_H + 0.1)), SW["stone_light"])
    _box_bmesh(bm, Vector((0.85, 0.85, 0.15)), Vector((0, 0, 0.08)), SW["stone_dark"])
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.0001)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return _mesh_from_bmesh(bm, "pillar", mat)


def _build_rune_stone(mat: bpy.types.Material) -> bpy.types.Object:
    bm = bmesh.new()
    _box_bmesh(bm, Vector((0.5, 0.35, 1.6)), Vector((0, 0, 0.8)), SW["stone_dark"])
    _box_bmesh(bm, Vector((0.35, 0.08, 0.5)), Vector((0, 0.2, 1.2)), SW["ice"])
    _box_bmesh(bm, Vector((0.7, 0.5, 0.25)), Vector((0, 0, 0.12)), SW["stone_mid"])
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.0001)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return _mesh_from_bmesh(bm, "rune_stone", mat)


def _build_crate(mat: bpy.types.Material) -> bpy.types.Object:
    bm = bmesh.new()
    s = 0.9
    _box_bmesh(bm, Vector((s, s, s)), Vector((0, 0, s * 0.5)), SW["wood"])
    _box_bmesh(bm, Vector((s * 1.02, 0.08, 0.08)), Vector((0, 0, s * 0.5)), SW["stone_dark"])
    _box_bmesh(bm, Vector((0.08, s * 1.02, 0.08)), Vector((0, 0, s * 0.25)), SW["stone_dark"])
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.0001)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return _mesh_from_bmesh(bm, "crate", mat)


def _build_brazier(mat: bpy.types.Material) -> bpy.types.Object:
    bm = bmesh.new()
    _box_bmesh(bm, Vector((0.7, 0.7, 0.5)), Vector((0, 0, 0.25)), SW["stone_dark"])
    _box_bmesh(bm, Vector((0.85, 0.85, 0.12)), Vector((0, 0, 0.56)), SW["stone_mid"])
    _box_bmesh(bm, Vector((0.35, 0.35, 0.35)), Vector((0, 0, 0.85)), SW["ember"])
    _box_bmesh(bm, Vector((0.15, 0.15, 0.25)), Vector((0.2, 0.15, 1.0)), SW["ember"])
    _box_bmesh(bm, Vector((0.12, 0.12, 0.2)), Vector((-0.18, -0.1, 0.95)), SW["ember"])
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.0001)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return _mesh_from_bmesh(bm, "brazier", mat)


def _build_pine(variant: int, mat: bpy.types.Material) -> bpy.types.Object:
    bm = bmesh.new()
    trunk_h = 1.2 + variant * 0.15
    _box_bmesh(bm, Vector((0.28, 0.28, trunk_h)), Vector((0, 0, trunk_h * 0.5)), SW["dead_wood"])
    tiers = 3 + (variant % 2)
    for i in range(tiers):
        r = 1.1 - i * 0.22
        z = trunk_h + i * 0.55
        h = 0.65 - i * 0.05
        _cone_tier(bm, r, h, z, "pine" if i < tiers - 1 else "pine_dark", snow=True)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.0001)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return _mesh_from_bmesh(bm, f"pine_{variant}", mat)


def _build_dead_tree(mat: bpy.types.Material) -> bpy.types.Object:
    bm = bmesh.new()
    _box_bmesh(bm, Vector((0.32, 0.32, 2.2)), Vector((0, 0, 1.1)), SW["dead_wood"])
    for ang in (0.4, 2.1, 3.8):
        dx = math.cos(ang) * 0.9
        dy = math.sin(ang) * 0.9
        _box_bmesh(bm, Vector((0.12, 0.12, 0.9)), Vector((dx * 0.5, dy * 0.5, 1.6)), SW["dead_wood"])
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.0001)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return _mesh_from_bmesh(bm, "dead_tree", mat)


def _build_bush(variant: int, mat: bpy.types.Material) -> bpy.types.Object:
    bm = bmesh.new()
    sw = "bush" if variant == 0 else "heather"
    for ox, oz, sc in ((0, 0, 1.0), (0.35, 0.2, 0.75), (-0.3, 0.25, 0.7)):
        _box_bmesh(bm, Vector((0.55 * sc, 0.55 * sc, 0.45 * sc)), Vector((ox, oz, 0.22 * sc)), SW[sw])
    if variant == 1:
        _box_bmesh(bm, Vector((0.25, 0.25, 0.2)), Vector((0.1, -0.2, 0.35)), SW["snow"])
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.0001)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return _mesh_from_bmesh(bm, f"bush_{variant}", mat)


def _build_tuft(kind: str, mat: bpy.types.Material) -> bpy.types.Object:
    bm = bmesh.new()
    sw = "grass" if kind == "grass" else "heather"
    for i in range(4):
        ang = i * 1.57
        _box_bmesh(
            bm,
            Vector((0.08, 0.22, 0.35)),
            Vector((math.cos(ang) * 0.12, math.sin(ang) * 0.12, 0.18)),
            SW[sw],
        )
    _box_bmesh(bm, Vector((0.2, 0.2, 0.08)), Vector((0, 0, 0.04)), SW["stone_dark"])
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.0001)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return _mesh_from_bmesh(bm, f"{kind}_tuft", mat)


def _build_rock(variant: int, mat: bpy.types.Material) -> bpy.types.Object:
    bm = bmesh.new()
    scales = ((0.9, 0.7, 0.5), (1.1, 0.85, 0.55), (0.65, 0.55, 0.4))
    sx, sy, sz = scales[variant % 3]
    _box_bmesh(bm, Vector((sx, sy, sz)), Vector((0, 0, sz * 0.5)), SW["rock"])
    _box_bmesh(bm, Vector((sx * 0.5, sy * 0.4, sz * 0.25)), Vector((sx * 0.2, 0, sz * 0.85)), SW["stone_dark"])
    if variant % 2 == 0:
        _box_bmesh(bm, Vector((sx * 0.6, sy * 0.5, 0.08)), Vector((0, 0, sz + 0.04)), SW["snow"])
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.0001)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return _mesh_from_bmesh(bm, f"rock_{variant}", mat)


def _build_snow_patch(mat: bpy.types.Material) -> bpy.types.Object:
    bm = bmesh.new()
    _box_bmesh(bm, Vector((1.4, 1.0, 0.06)), Vector((0, 0, 0.03)), SW["snow_patch"])
    _box_bmesh(bm, Vector((0.5, 0.4, 0.05)), Vector((0.4, 0.3, 0.025)), SW["snow"])
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.0001)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return _mesh_from_bmesh(bm, "snow_patch", mat)


PIECES: list[tuple[str, Callable[[bpy.types.Material], bpy.types.Object]]] = [
    ("stone_floor_tile_a.glb", lambda m: _build_floor_tile(0, m)),
    ("stone_floor_tile_b.glb", lambda m: _build_floor_tile(1, m)),
    ("stone_wall_straight.glb", _build_wall_straight),
    ("stone_wall_corner.glb", _build_wall_corner),
    ("stone_wall_broken.glb", _build_wall_broken),
    ("stone_pillar.glb", _build_pillar),
    ("rune_stone.glb", _build_rune_stone),
    ("crate.glb", _build_crate),
    ("brazier.glb", _build_brazier),
    ("pine_tree_a.glb", lambda m: _build_pine(0, m)),
    ("pine_tree_b.glb", lambda m: _build_pine(1, m)),
    ("pine_tree_c.glb", lambda m: _build_pine(2, m)),
    ("dead_tree.glb", _build_dead_tree),
    ("bush_a.glb", lambda m: _build_bush(0, m)),
    ("bush_b.glb", lambda m: _build_bush(1, m)),
    ("grass_tuft.glb", lambda m: _build_tuft("grass", m)),
    ("heather_tuft.glb", lambda m: _build_tuft("heather", m)),
    ("rock_a.glb", lambda m: _build_rock(0, m)),
    ("rock_b.glb", lambda m: _build_rock(1, m)),
    ("rock_c.glb", lambda m: _build_rock(2, m)),
    ("snow_patch.glb", _build_snow_patch),
]


def main() -> None:
    _write_palette_png(PALETTE_PATH)
    import shutil

    EXPORT_DIR.mkdir(parents=True, exist_ok=True)
    shutil.copy2(PALETTE_PATH, EXPORT_DIR / "palette.png")
    shutil.copy2(PALETTE_PATH, ROOT / "assets" / "characters" / "warden" / "palette.png")

    for filename, builder in PIECES:
        _clear_scene()
        mat = _make_palette_material()
        obj = builder(mat)
        _export_glb(obj, filename)

    print(f"Env kit: exported {len(PIECES)} GLBs to {EXPORT_DIR}")


if __name__ == "__main__":
    main()
