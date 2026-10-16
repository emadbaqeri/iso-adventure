#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
GODOT="${GODOT_BIN:-$ROOT/.ci/godot/Godot}"
LOG="${1:-/tmp/godot-render-forward-smoke.log}"

if [[ ! -x "$GODOT" ]]; then
  echo "Godot binary not found: $GODOT" >&2
  exit 1
fi

if ! command -v xvfb-run >/dev/null 2>&1; then
  echo "xvfb-run is required for Forward+ render smoke (real window, virtual framebuffer)" >&2
  exit 1
fi

# Real window on xvfb (not --headless): closer to desktop Forward+ / Metal behavior.
xvfb-run -a "$GODOT" \
  --path "$ROOT" \
  --rendering-driver vulkan \
  --audio-driver Dummy \
  -s res://tests/smoke/render_forward_smoke.gd \
  2>&1 | tee "$LOG"

if grep -qE 'surface_override_materials\.size\(\) = 0|set_surface_override_material \(mesh_instance_3d' "$LOG"; then
  echo "render_forward_smoke: MeshInstance3D surface override error in log" >&2
  grep -E 'surface_override_materials\.size\(\) = 0|set_surface_override_material \(mesh_instance_3d' "$LOG" >&2 || true
  exit 1
fi

if grep -qE '^(ERROR:|SCRIPT ERROR:|USER ERROR:)' "$LOG"; then
  echo "render_forward_smoke: ERROR lines found in log" >&2
  grep -E '^(ERROR:|SCRIPT ERROR:|USER ERROR:)' "$LOG" >&2 || true
  exit 1
fi

if grep -qE 'det == 0|invert \(core/math/basis\.cpp' "$LOG"; then
  echo "render_forward_smoke: degenerate basis (zero scale / bad look_at) in log" >&2
  grep -E 'det == 0|invert \(core/math/basis\.cpp' "$LOG" >&2 || true
  exit 1
fi

if grep -q "Can't change the size of a SubViewport" "$LOG"; then
  echo "render_forward_smoke: SubViewport stretch warning treated as failure" >&2
  exit 1
fi

echo "render_forward_smoke: no ERROR lines"
