# ADR 0001: Engine and art style

**Status:** Accepted  
**Date:** 2026-10-16

## Context

Need a Zelda-like **3D isometric low-poly** action-adventure with fast iteration and typed scripting.

## Decision

- **Engine:** Godot **4.7.2-stable**, **typed GDScript only**
- **Art style:** **3D isometric low-poly** — Blender meshes exported as **glTF** at a **fixed scale**; flat `StandardMaterial3D` colors from a small palette; no pixel-grid SubViewport pipeline
- **Camera:** Orthographic iso rig (`IsoCameraRig`) with smooth follow
- **Rendering:** Forward+, native resolution, MSAA, ACES tonemap, SSAO, soft directional shadows, light fog
- **Tests:** gdUnit4 (vendored), headless CI including Forward+ render smoke
- **Version control:** Git LFS for binary art/audio

## Consequences

- Team aligns on one Godot patch release (`GODOT_VERSION` / CI pin)
- No C# / GDExtension requirement for gameplay code in V1
- Art pipeline favors simple low-poly assets and flat materials over PBR complexity
