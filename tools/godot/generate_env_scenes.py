#!/usr/bin/env python3
"""Generate Godot wrapper scenes for assets/env/*.glb."""

from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SCENES = ROOT / "scenes" / "env"

PIECE_CONFIG: dict[str, dict] = {
    "stone_floor_tile_a": {"collision": None},
    "stone_floor_tile_b": {"collision": None},
    "stone_wall_straight": {"collision": (2.0, 2.4, 1.2)},
    "stone_wall_corner": {"collision": (2.0, 2.4, 2.0)},
    "stone_wall_broken": {"collision": (2.0, 1.8, 1.2)},
    "stone_pillar": {"collision": (0.6, 2.4, 0.6)},
    "rune_stone": {"collision": (0.5, 1.6, 0.35)},
    "crate": {"collision": (0.9, 0.9, 0.9)},
    "brazier": {"collision": (0.7, 0.9, 0.7)},
    "pine_tree_a": {"collision": (0.5, 2.8, 0.5)},
    "pine_tree_b": {"collision": (0.5, 3.2, 0.5)},
    "pine_tree_c": {"collision": (0.55, 3.5, 0.55)},
    "dead_tree": {"collision": (0.4, 2.2, 0.4)},
    "bush_a": {"collision": None},
    "bush_b": {"collision": None},
    "grass_tuft": {"collision": None},
    "heather_tuft": {"collision": None},
    "rock_a": {"collision": (0.9, 0.5, 0.7)},
    "rock_b": {"collision": (1.1, 0.55, 0.85)},
    "rock_c": {"collision": (0.65, 0.4, 0.55)},
    "snow_patch": {"collision": None},
}


def _scene_for(name: str, cfg: dict) -> str:
    glb = f"res://assets/env/{name}.glb"
    script = "res://scripts/env/env_palette_visual.gd"
    col = cfg.get("collision")
    if col is None:
        return f"""[gd_scene load_steps=3 format=3]

[ext_resource type="PackedScene" path="{glb}" id="1_glb"]
[ext_resource type="Script" path="{script}" id="2_script"]

[node name="{name}" type="Node3D"]
script = ExtResource("2_script")

[node name="Visual" parent="." instance=ExtResource("1_glb")]
"""
    sx, sy, sz = col
    cy = sy * 0.5
    return f"""[gd_scene load_steps=4 format=3]

[ext_resource type="PackedScene" path="{glb}" id="1_glb"]
[ext_resource type="Script" path="{script}" id="2_script"]

[sub_resource type="BoxShape3D" id="BoxShape3D_col"]
size = Vector3({sx}, {sy}, {sz})

[node name="{name}" type="StaticBody3D"]
collision_layer = 1
collision_mask = 0
script = ExtResource("2_script")

[node name="CollisionShape3D" type="CollisionShape3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, {cy}, 0)
shape = SubResource("BoxShape3D_col")

[node name="Visual" parent="." instance=ExtResource("1_glb")]
"""


def main() -> None:
    SCENES.mkdir(parents=True, exist_ok=True)
    for name, cfg in PIECE_CONFIG.items():
        path = SCENES / f"{name}.tscn"
        path.write_text(_scene_for(name, cfg), encoding="utf-8")
        print("wrote", path.relative_to(ROOT))


if __name__ == "__main__":
    main()
