# Asset licenses

Track every shipped asset (art, audio, fonts, third-party code).

| Asset / path | Source | License | Author | AI-generated? |
|--------------|--------|---------|--------|----------------|
| `addons/gdUnit4/` | [gdUnit4](https://github.com/MikeSchulze/gdUnit4) v6.2.2 | MIT | Mike Schulze | No |
| `icon.svg` | Project placeholder | CC0 (project) | Iso Adventure | No |
| `assets/characters/warden/warden.glb` | Procedural Blender build (`tools/blender/build_warden.py`) | CC0 (project) | AI-written generator, project-owned mesh | Yes (mesh/script) |
| `assets/characters/warden/palette.png` | Same build script (`tools/blender/palette.png` source) | CC0 (project) | AI-written generator | Yes |
| `tools/blender/palette.png` | Warden + environment palette source swatches | CC0 (project) | AI-written generator | Yes |
| `assets/env/*.glb` | Procedural Blender build (`tools/blender/build_env_kit.py`) | CC0 (project) | AI-written generator, project-owned meshes | Yes (mesh/script) |
| `assets/env/palette.png` | Copied from `tools/blender/palette.png` by env kit build | CC0 (project) | AI-written generator | Yes |

Add a row before committing new `.png`, `.wav`, `.ogg`, `.glb`, or `.blend` files.
