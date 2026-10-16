# Art bible — 3D Pixel Art

## Style name

**3D Pixel Art:** low-poly 3D scenes rendered to a fixed **pixel grid** (640×360 internal resolution), then integer-upscaled with nearest filtering. Not painterly or heavily stylised post — readable light/shadow, hard cast shadows, simple **1px dark outlines**.

## Look

Orthographic isometric camera (`PixelCameraRig`, ~35°). **Pixel stability** is required:

- Camera origin snapped to the render texel grid each physics frame.
- Sub-texel remainder applied via **`Camera3D.frustum_offset`** (not fractional UI container shifts).
- Dynamic props snap to the same grid in camera space (`render_test_mover.gd` pattern).
- Outlines are detected on **texel centers** with neighbor support to avoid单-pixel sparkle.

CI checks: `tools/ci/outline_stability_smoke.sh` reports `static_hold_changed_pixels` and `pan_aligned_changed_pixels` (expect **0**).

## Render pipeline

| Stage | Resource |
|-------|----------|
| Surfaces | `shaders/cel_spatial.gdshader` — 3 bands (top / side / shadow) + hard sun shadow band |
| Mood | `RenderMoodResource` + `RenderMoodController` — **subtle** warm/cool presets |
| Low-res 3D | `SubViewport` 640×360 in `scenes/render_test.tscn` |
| Outlines | `PixelPostQuad` on `Camera3D`, `shaders/pixel_post.gdshader` (Forward+) |
| Palette | Optional on `SubViewportContainer` (`pixel_viewport_composite.gdshader`) |

### Lighting

- Directional **sun** with hard shadow maps (`shadow_filter = none`).
- Cast shadows select the **shadow cel band** (not a smooth gradient).
- Light **ambient** + mild **rim** (low `rim_strength`); moods tweak colors gently.
- **Fog** and **SSAO** for depth and floor contact — kept subtle in presets.

### Outlines

- Single **`outline_color`** (near-black), 1px depth silhouettes and interior creases.
- Depth edges use **Laplacian gating** so flat floors stay clean.
- Weak / isolated edge pixels suppressed (neighbor support + thresholds).

### Controls (test scene)

- **M** — cycle moods (`warm_day`, `cool_dungeon`)
- **B** — toggle optional band dither (`band_dither` on `PixelRenderRoot`)

Default window **1280×720** → 2× integer upscale.

**Renderer:** Forward+ (`rendering/renderer/rendering_method=forward_plus`). Smoke: `tools/ci/render_forward_smoke.sh`.

## Mood resource (`RenderMoodResource`)

| Field | Role |
|-------|------|
| `key_light_*`, `ambient_*` | Sun and fill |
| `shadow_tint`, `mid_tint`, `highlight_tint`, `top_tint` | Cel bands |
| `rim_tint`, `rim_strength` | Subtle edge separation |
| `fog_*`, `ssao_intensity` | Depth (subtle) |
| `outline_color` | Post outline |
| `band_dither_strength` | Optional dither when enabled on root |

Presets: `resources/moods/warm_day.tres`, `cool_dungeon.tres`.

## Assets

- Blender → glTF, low poly, shared scale
- Palette: `assets/palette/starter_palette.png` (nearest)
- Textures: low resolution, point filtering only
