# Art bible — 3D isometric pixel art

## Look

Low-res 3D rendered into a **SubViewport** at **640×360**, displayed through `PixelRenderRoot` with **nearest-neighbor** filtering and **integer** upscale (floor of window size ÷ render size). Orthographic camera at **~35°** isometric (`PixelCameraRig`); camera origin snaps to the texel grid each frame with **sub-pixel offset** applied to the `SubViewportContainer` position.

## Render pipeline (implemented)

| Stage | Resource |
|-------|----------|
| Cel surface | `shaders/cel_spatial.gdshader` — three hard light bands via `light()` |
| Low-res 3D | `SubViewport` 640×360 inside `scenes/render_test.tscn` |
| Outline + palette | `shaders/pixel_post.gdshader` on camera-mounted fullscreen quad (depth + normal edges) |
| Palette quantize | Optional; `quantize_palette` on `PixelRenderRoot`, `assets/palette/starter_palette.png` |

**Lighting:** `DirectionalLight3D` sun + `WorldEnvironment` ambient (color ambient, ~0.55 energy) so blockout meshes read clearly.

**Test scene:** `scenes/render_test.tscn` (main scene for now) — floor, cubes, pillars, and a moving cube the camera follows.

## Shaders

- Toon/cel: hard color bands (`band_shadow` / `band_mid` / `band_highlight`)
- Outline pass: depth + normal discontinuities, pixel-aligned (1-texel neighbors)
- Palette: nearest-color match across palette texels (toggle on root)

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
