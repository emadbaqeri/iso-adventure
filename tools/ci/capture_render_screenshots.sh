#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
GODOT="${GODOT_BIN:-$ROOT/.ci/godot/Godot}"
OUT="$ROOT/docs/screenshots"
LOG="/tmp/godot-capture-forward.log"

mkdir -p "$OUT"

xvfb-run -a -s "-screen 0 1280x720x24" "$GODOT" \
  --path "$ROOT" \
  --rendering-driver vulkan \
  --display-driver x11 \
  --audio-driver Dummy \
  -s res://tests/visual/render_test_capture.gd \
  2>&1 | tee "$LOG"

if grep -qE '^(ERROR:|SCRIPT ERROR:|USER ERROR:)' "$LOG"; then
  echo "capture: ERROR lines in Godot log" >&2
  grep -E '^(ERROR:|SCRIPT ERROR:|USER ERROR:)' "$LOG" >&2 || true
  exit 1
fi

echo "capture: screenshots saved under $OUT"
