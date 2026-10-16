# ADR 0001: Engine and art style

**Status:** Accepted  
**Date:** 2026-10-16

## Context

Need a Zelda-like isometric action-adventure with fast iteration and typed scripting.

## Decision

- **Engine:** Godot **4.7.2-stable**, **typed GDScript only**
- **Art style:** **3D Pixel Art** — low-poly 3D in Blender → glTF; render through a low-res SubViewport (640×360) with nearest integer upscale, orthographic isometric camera, readable cel bands, hard cast shadows, simple 1px dark outlines, optional limited palette
- **Pixel stability:** camera and movers snapped to the render texel grid; outline temporal stability covered by CI (`outline_stability_smoke`)
- **Tests:** gdUnit4 (vendored), headless CI
- **Version control:** Git LFS for binary art/audio

## Consequences

- Team aligns on one Godot patch release (`GODOT_VERSION` / CI pin)
- No C# / GDExtension requirement for gameplay code in V1
- Art pipeline favors simple meshes and palette texture over high-res PBR
