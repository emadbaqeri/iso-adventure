# Iso Adventure

Zelda-like 3D isometric low-poly action-adventure (prototype). Godot 4 + typed GDScript.

## Godot version

**Pin: Godot `4.7.2-stable`** — match this locally (see `GODOT_VERSION` and CI). Download: [Godot 4.7.2 stable](https://github.com/godotengine/godot/releases/tag/4.7.2-stable).

Emad: use the same editor build on your machine so imports and exports stay consistent with CI.

## Open the project

1. Install [Git LFS](https://git-lfs.com/) and run `git lfs install` once per machine.
2. Clone the repo and open the folder in **Godot 4.7.2**.
3. Run the main scene (`scenes/main.tscn`) — placeholder orthographic isometric view.

## Run tests

From the repo root (Godot on `PATH` as `godot`, or set `GODOT_BIN`):

```bash
./addons/gdUnit4/runtest.sh --godot_binary "$GODOT_BIN" -a res://tests/unit
godot --headless --path . -s res://tests/smoke/scene_smoke_runner.gd
```

Or use the **GdUnit4** panel in the editor for unit tests.

## CI builds

On pushes and PRs, GitHub Actions runs tests and desktop exports (Linux, Windows, macOS unsigned). Download artifacts from the **Export** workflow run (names: `linux-desktop`, `windows-desktop`, `macos-desktop`).

## Layout

| Path | Purpose |
|------|---------|
| `scenes/` | Game scenes |
| `scripts/` | Typed GDScript (`components/`, `state_machine/`) |
| `assets/` | Models, textures, palette, audio |
| `materials/` | Low-poly StandardMaterial3D presets |
| `tests/` | gdUnit4 unit + scene smoke tests |
| `addons/gdUnit4/` | Vendored test framework (MIT) |
| `tools/blender/` | Blender export notes / scripts |
| `docs/` | GDD, art bible, audio, licenses, backlog |

## Docs

- [GDD](docs/GDD.md) — vision and V1 scope  
- [Art bible](docs/art-bible.md) — 3D isometric low-poly look  
- [Audio](docs/audio.md) — sourcing plan  
- [Asset licenses](docs/assets-licenses.md)  
- [ADR 0001](docs/decisions/0001-engine-and-art-style.md)
