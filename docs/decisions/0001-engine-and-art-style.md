# ADR 0001: Engine and art style

**Status:** Accepted  
**Date:** 2026-10-16

## Context

Need a Zelda-like 3D isometric pixel-art action-adventure with fast iteration and typed scripting.

## Decision

- **Engine:** Godot **4.7.2-stable**, **typed GDScript only**
- **Art:** 3D low-poly in Blender → glTF; render through low-res SubViewport with nearest upscale, orthographic isometric camera, cel + outline shaders, limited palette
- **Tests:** gdUnit4 (vendored), headless CI
- **Version control:** Git LFS for binary art/audio

## Consequences

- Team aligns on one Godot patch release (`GODOT_VERSION` / CI pin)
- No C# / GDExtension requirement for gameplay code in V1
- Art pipeline favors palette texture + simple meshes over high-res PBR
