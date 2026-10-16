#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
GODOT="${GODOT_BIN:-$ROOT/.ci/godot/Godot}"
LOG="${1:-/tmp/godot-render-forward-smoke.log}"

if [[ ! -x "$GODOT" ]]; then
  echo "Godot binary not found: $GODOT" >&2
  exit 1
fi

# Headless display + Vulkan uses Forward+ (lavapipe on Linux CI; Metal on macOS).
"$GODOT" \
  --path "$ROOT" \
  --headless \
  --display-driver headless \
  --rendering-driver vulkan \
  --audio-driver Dummy \
  -s res://tests/smoke/render_forward_smoke.gd \
  2>&1 | tee "$LOG"

if grep -qE '^(ERROR:|SCRIPT ERROR:|USER ERROR:)' "$LOG"; then
  echo "render_forward_smoke: ERROR lines found in log" >&2
  grep -E '^(ERROR:|SCRIPT ERROR:|USER ERROR:)' "$LOG" >&2 || true
  exit 1
fi

if grep -q "Can't change the size of a SubViewport" "$LOG"; then
  echo "render_forward_smoke: SubViewport stretch warning treated as failure" >&2
  exit 1
fi

echo "render_forward_smoke: no ERROR lines"
