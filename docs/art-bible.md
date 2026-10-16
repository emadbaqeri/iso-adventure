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

## Pipeline

1. Model in Blender at **fixed world scale**, export **glTF**.
2. Assign `StandardMaterial3D` (roughness 1, no specular) per mesh or surface.
3. Place in scenes; use `IsoCameraRig` + `WorldEnvironment` as in `scenes/render_test.tscn`.

## Test scene

`scenes/render_test.tscn` — floor, cubes, pillars, sliding cube. Screenshots: `docs/screenshots/warm_day.png`, `cool_dungeon.png`.

**CI:** `tools/ci/render_forward_smoke.sh` (Forward+, zero `ERROR:` lines).
