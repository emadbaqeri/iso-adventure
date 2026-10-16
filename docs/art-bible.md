# Art bible — 3D isometric pixel art (t3ssel8r-inspired)

## Look

Low-res 3D rendered into a **SubViewport** at **640×360**, displayed through `PixelRenderRoot` with **nearest-neighbor** filtering and **integer** upscale (floor of window size ÷ render size). Orthographic camera at **~35°** isometric (`PixelCameraRig`).

**Pixel stability:** each physics frame the camera origin is projected onto the camera **right/up** axes and snapped in steps of `units_per_pixel` (world units per texel). The fractional remainder drives a **sub-pixel offset** on the upscaled `SubViewportContainer`, computed via `Camera3D.unproject_position` so iso views compensate in real screen space.

## Render pipeline

| Stage | Resource |
|-------|----------|
| Cel surface | `shaders/cel_spatial.gdshader` — **top / lit side / shadow** bands, cast shadows snap to shadow band |
| Mood | `RenderMoodResource` + `RenderMoodController` (`resources/moods/`) |
| Low-res 3D | `SubViewport` 640×360 inside `scenes/render_test.tscn` |
| Outlines | `PixelPostQuad` on **Camera3D** + `shaders/pixel_post.gdshader` (Forward+) |
| Palette | Optional quantize on `SubViewportContainer` (`pixel_viewport_composite.gdshader`) |

### Cel shading (3 tones + cast shadows)

- **Top faces** (`normal.y > 0.55`): `band_top` — warmest read.
- **Lit sides**: `band_mid` → `band_highlight` by `ndotl` vs `band_thresholds` (hard steps).
- **Shadow sides**: `band_shadow` — hue-shifted **cool** (blue/purple).
- **Sun shadows**: when `ATTENUATION < 0.5`, force **shadow band** (crisp, pixel-aligned; not a smooth gradient).
- **Rim/back** light: separate directional pass; only rim term when light direction ≠ key sun (`key_light_dir` alignment).
- **Band dither** (optional): light-direction hash on band thresholds — toggle **`B`** or `band_dither` on `PixelRenderRoot`.

### Outlines (t3ssel8r-style)

| Edge type | Treatment |
|-----------|-----------|
| **Silhouette / depth** | 1px **hue-darkened** line from local surface color (cool-shifted), not a global outline color |
| **Convex crease (lit)** | 1px **warm highlight** along normal discontinuity facing the sun |
| **Concave / occluded crease** | Darkened, hue-shifted crease |

Depth edges use **Laplacian gating** so flat floors stay clean. Mood drives `outline_darken`, `outline_cool_shift`, `crease_*`, and `outline_light`.

### Lighting & depth

- **Key** sun + stronger **rim** fill; lower ambient so bands read clearly.
- **Fog**: height/distance tint per mood (`fog_density`, `fog_aerial_perspective`).
- **SSAO**: contact darkening at object bases (enabled when viewport ≥ 16px).
- **Hard** shadow maps (`shadow_filter = none`); bias tuned for ortho scene scale.

**Viewport upscale:** `SubViewportContainer.stretch = true` with `stretch_shrink = integer_scale`. Default window **1280×720** → 2× upscale.

**Test scene:** `scenes/render_test.tscn` (main). **M** = cycle moods. Reference captures:

| | Before style push | After |
|--|-------------------|--------|
| Warm | `docs/screenshots/before_style_warm_day.png` | `docs/screenshots/after_style_warm_day.png` |
| Cool | `docs/screenshots/before_style_cool_dungeon.png` | `docs/screenshots/after_style_cool_dungeon.png` |

Also: `warm_day.png`, `cool_dungeon.png`, `motion_00–03.png`.

**Renderer:** Forward+ (`rendering/renderer/rendering_method=forward_plus`). CI: `tools/ci/render_forward_smoke.sh` (zero `ERROR:` lines).

## Mood resource (`RenderMoodResource`)

| Field | Role |
|-------|------|
| `key_light_color`, `key_light_energy` | Sun warmth / strength |
| `ambient_color`, `ambient_energy` | Fill (kept moderate for band contrast) |
| `shadow_tint`, `mid_tint`, `highlight_tint`, `top_tint` | Cel bands (cool shadow, warm light/top) |
| `rim_tint`, `rim_strength` | Back/rim separation |
| `fog_*`, `ssao_intensity` | Depth and contact |
| `band_count`, `band_dither_strength` | Cel steps + optional dither |
| `outline_light`, `outline_darken`, `outline_cool_shift`, `crease_*` | Post edge stylization |

Presets: `resources/moods/warm_day.tres`, `resources/moods/cool_dungeon.tres`.

## Assets

- **Blender** → glTF (.glb), low poly, shared scale
- **Palette** `assets/palette/starter_palette.png` (6×1, nearest)
- Textures: low resolution, nearest filtering only

## Starter palette (sRGB hex)

| Role | Hex |
|------|-----|
| Shadow | `#1c2330` |
| Mid | `#3d4f6f` |
| Highlight | `#8fa4c4` |
| Accent | `#5b8cff` |
| Warm | `#e8a838` |
| Danger | `#d94f4f` |
