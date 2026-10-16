# Art bible — 3D isometric pixel art

## Look

Low-res 3D rendered into a **SubViewport** at **640×360**, displayed through `PixelRenderRoot` with **nearest-neighbor** filtering and **integer** upscale (floor of window size ÷ render size). Orthographic camera at **~35°** isometric (`PixelCameraRig`).

**Pixel stability:** each physics frame the camera origin is projected onto the camera **right/up** axes and snapped in steps of `units_per_pixel` (world units per texel). The fractional remainder drives a **sub-pixel offset** on the upscaled `SubViewportContainer`, computed via `Camera3D.unproject_position` so iso views compensate in real screen space. Follow targets move on the camera **right** axis in world space for even screen motion during tests.

## Render pipeline

| Stage | Resource |
|-------|----------|
| Cel surface | `shaders/cel_spatial.gdshader` — hue-shifted hard bands, optional rim |
| Mood | `RenderMoodResource` + `RenderMoodController` (`resources/moods/`) |
| Low-res 3D | `SubViewport` 640×360 inside `scenes/render_test.tscn` |
| Outline + palette | `shaders/pixel_viewport_composite.gdshader` on `SubViewportContainer` (1-texel color edges, dual-tone outline). `shaders/pixel_post.gdshader` kept for Forward+ experiments. |
| Palette quantize | Optional; `quantize_palette` on `PixelRenderRoot` |

**Lighting & depth:** warm **key** (`DirectionalLight3D` sun) + cool **ambient**, cool **rim** fill, **SSAO** for contact read, **distance fog** tinted per mood, **hard** sun shadows (`shadow_filter = none`). Cel bands use separate shadow/mid/highlight tints (not only darker albedo).

**Viewport upscale:** `SubViewportContainer.stretch = true` with `stretch_shrink = integer_scale` (nearest filter). Default window **1280×720** → 2× upscale fills the window.

**Test scene:** `scenes/render_test.tscn` (main scene). Press **M** to cycle moods (`warm_day` → `cool_dungeon`). Reference captures: `docs/screenshots/warm_day.png`, `cool_dungeon.png`, `motion_*.png`.

**Renderer:** Project pins **Forward+** (`rendering/renderer/rendering_method=forward_plus`) for macOS Metal. Composite post runs on the container material (works on Compatibility/OpenGL too).

## Shaders

- Toon/cel: `band_count` (2–4), hue-shifted `band_shadow` / `band_mid` / `band_highlight`, `rim_tint` + `rim_strength`
- Outline: 1-texel depth + normal neighbors; boosted on upward-facing normals; `outline_dark` / `outline_light` chosen per face luminance
- Palette: nearest-color match across palette texels (toggle on root)

## Mood resource (`RenderMoodResource`)

| Field | Role |
|-------|------|
| `key_light_color`, `key_light_energy` | Sun warmth / strength |
| `ambient_color`, `ambient_energy` | Cool/warm fill |
| `shadow_tint`, `mid_tint`, `highlight_tint` | Cel band hues |
| `rim_tint`, `rim_strength` | Edge separation |
| `fog_color`, `fog_density`, `fog_aerial_perspective` | Depth / mood |
| `ssao_intensity` | Contact shadow feel |
| `band_count` | 2–4 cel steps |
| `outline_dark`, `outline_light` | Post outline contrast |

Presets: `resources/moods/warm_day.tres`, `resources/moods/cool_dungeon.tres`.

## Assets

- **Blender** → glTF (.glb), low poly, shared scale
- **Palette texture** `assets/palette/starter_palette.png` (6×1, point-filtered)
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

Emad can revise after first in-engine blockout.
