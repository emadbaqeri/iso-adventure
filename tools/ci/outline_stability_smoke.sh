#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
GODOT="${GODOT_BIN:-$ROOT/.ci/godot/Godot}"
LOG="${1:-/tmp/godot-outline-stability.log}"

if [[ ! -x "$GODOT" ]]; then
  echo "Godot binary not found: $GODOT" >&2
  exit 1
fi

# X11 + Vulkan: texture readback for pixel diff (headless readback logs errors on 4.7).
xvfb-run -a -s "-screen 0 1280x720x24" "$GODOT" \
  --path "$ROOT" \
  --display-driver x11 \
  --rendering-driver vulkan \
  --audio-driver Dummy \
  -s res://tests/smoke/outline_stability_smoke.gd \
  2>&1 | tee "$LOG"

if grep -qE '^(ERROR:|SCRIPT ERROR:|USER ERROR:)' "$LOG"; then
  echo "outline_stability_smoke: ERROR lines found in log" >&2
  grep -E '^(ERROR:|SCRIPT ERROR:|USER ERROR:)' "$LOG" >&2 || true
  exit 1
fi

if ! grep -q "outline_stability: static_hold_changed_pixels=" "$LOG"; then
  echo "outline_stability_smoke: missing result line" >&2
  exit 1
fi

if ! grep -qE "outline_stability: static_hold_changed_pixels=0 " "$LOG"; then
  echo "outline_stability_smoke: static hold drift detected" >&2
  exit 1
fi

echo "outline_stability_smoke: OK"
