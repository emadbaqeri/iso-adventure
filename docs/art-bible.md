# Art bible — 3D isometric low-poly

## Style

**3D isometric low-poly:** simple meshes (Blender → glTF) with **flat** `StandardMaterial3D` colors from a small palette. Native **1280×720** render with **MSAA** (Forward+). No low-res SubViewport, pixel snapping, or screen-space outline passes.

## Camera

- `IsoCameraRig`: orthographic, **~35° pitch** and **45° yaw**, smooth follow of a target with `follow_offset` and `follow_smooth`.
- Test scene: follows `MovingCube` with `ortho_size` ~14.

## Lighting & environment

| Element | Notes |
|---------|--------|
| Sun | `DirectionalLight3D`, **soft PCF shadows** (bias tuned to avoid acne) |
| Sky | `ProceduralSkyMaterial` + ambient |
| SSAO | Contact shading at object bases |
| Fog | Light density for depth |
| Tonemap | **ACES** (`Environment.tonemap_mode`) |

## Moods

`RenderMoodResource` presets (`warm_day`, `cool_dungeon`) adjust sun, ambient, sky, fog, and SSAO only. **M** toggles moods in `render_test`.

## Palette (starter)

| Role | Use |
|------|-----|
| Floor gray-blue | `materials/lowpoly_floor.tres` |
| Default gray | `lowpoly_default.tres` |
| Accent blue | `lowpoly_accent.tres` |
| Warm gold | `lowpoly_warm.tres` |

Texture reference: `assets/palette/starter_palette.png` (authoring guide; materials use flat colors).

### Warden character palette (`tools/blender/palette.png`)

Procedural **8×4** swatch grid (256×128 PNG). Each mesh face UV-snaps to the **center** of a swatch; Godot uses `materials/lowpoly_palette_warden.tres` with **nearest** filtering for crisp flat color.

| Swatch (col, row) | Role |
|-------------------|------|
| (0,0) | Cloak blue-gray |
| (1,0) | Cloak shadow |
| (2,0) | Fur trim (hood/collar) |
| (3,0) | Skin |
| (4,0) | Hood |
| (5,0) | Leather belt |
| (6,0) | Metal buckle |
| (7,0) | Boots |
| (0,1) | Pants |
| (1,1) | Gloves |
| (2,1) | Trim accent |
| (3,1) | Deep shadow |

Shipped copy: `assets/characters/warden/palette.png` (regenerated with `blender -b -P tools/blender/build_warden.py`).

### Environment palette (rows 2–3, shared `tools/blender/palette.png`)

Same **8×4** grid and UV rules as the warden. Row **2** is stone, wood, ember, snow, and ice; row **3** is pine, bush, dead wood, grass, heather, rock, and snow patch. Godot material: `materials/lowpoly_palette_env.tres` → `assets/env/palette.png`.

| Swatch (col, row) | Role |
|-------------------|------|
| (0,2)–(3,2) | Stone light / mid / dark / moss |
| (4,2) | Weathered wood |
| (5,2) | Brazier ember |
| (6,2)–(7,2) | Snow / ice highlight |
| (0,3)–(1,3) | Pine / pine shadow |
| (2,3)–(3,3) | Bush / dead wood |
| (4,3)–(5,3) | Grass / heather |
| (6,3)–(7,3) | Rock / snow patch |

### Environment kit (2 m modular grid)

Procedural Blender build: `tools/blender/build_env_kit.py` → `assets/env/*.glb` (1 unit = 1 m). Wrapper scenes: `scenes/env/`. Room dressing: `scripts/levels/room_env_dressing.gd` on `test_room` / `puzzle_room`.

| Piece | GLB |
|-------|-----|
| Floor tiles (2 variants) | `stone_floor_tile_a.glb`, `stone_floor_tile_b.glb` |
| Walls straight / corner / broken | `stone_wall_straight.glb`, `stone_wall_corner.glb`, `stone_wall_broken.glb` |
| Pillar, rune stone, crate, brazier | `stone_pillar.glb`, `rune_stone.glb`, `crate.glb`, `brazier.glb` |
| Pines ×3, dead tree | `pine_tree_a/b/c.glb`, `dead_tree.glb` |
| Bushes ×2, tufts | `bush_a/b.glb`, `grass_tuft.glb`, `heather_tuft.glb` |
| Rocks ×3, snow patch | `rock_a/b/c.glb`, `snow_patch.glb` |

Regenerate: `blender -b -P tools/blender/build_env_kit.py` then `python3 tools/godot/generate_env_scenes.py` if collision sizes change.

## Pipeline

1. Model in Blender at **fixed world scale**, export **glTF**.
2. Assign `StandardMaterial3D` (roughness 1, no specular) per mesh or surface.
3. Place in scenes; use `IsoCameraRig` + `WorldEnvironment` as in `scenes/render_test.tscn`.

## Test scene

`scenes/render_test.tscn` — floor, cubes, pillars, sliding cube. Screenshots: `docs/screenshots/warm_day.png`, `cool_dungeon.png`.

**CI:** `tools/ci/render_forward_smoke.sh` (Forward+, zero `ERROR:` lines).
