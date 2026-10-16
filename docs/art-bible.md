# Art bible — 3D isometric pixel art

## Look

Low-res 3D rendered into a **SubViewport** (e.g. 640×360), upscaled with **nearest-neighbor**. Orthographic camera at **~30–45°** isometric; snap camera to texel/pixel grid where possible.

## Shaders (planned)

- Toon/cel: hard color bands
- Outline pass: depth + normal discontinuities, pixel-aligned
- Optional palette quantization / ordered dither on final composite

## Assets

- **Blender** → glTF (.glb), low poly, shared scale
- One **palette texture** (point-filtered); per-object UVs sample palette
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
