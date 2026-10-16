#!/usr/bin/env bash
# Visual captures (xvfb + X11). Forward+ correctness is enforced by render_forward_smoke.sh.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
GODOT="${GODOT_BIN:-$ROOT/.ci/godot/Godot}"
OUT="$ROOT/docs/screenshots"
LOG="/tmp/godot-capture-forward.log"

mkdir -p "$OUT"
rm -f "$OUT"/frame_*.png "$OUT"/warm_day.png "$OUT"/cool_dungeon.png
rm -f "$OUT"/motion_00.png "$OUT"/motion_01.png "$OUT"/motion_02.png "$OUT"/motion_03.png

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

if grep -q "Can't change the size of a SubViewport" "$LOG"; then
  echo "capture: SubViewport stretch warning in log" >&2
  exit 1
fi

cp -f "$OUT/frame_02.png" "$OUT/warm_day.png"
cp -f "$OUT/frame_07.png" "$OUT/cool_dungeon.png"
cp -f "$OUT/frame_00.png" "$OUT/motion_00.png"
cp -f "$OUT/frame_01.png" "$OUT/motion_01.png"
cp -f "$OUT/frame_02.png" "$OUT/motion_02.png"
cp -f "$OUT/frame_03.png" "$OUT/motion_03.png"

echo "capture: screenshots saved under $OUT"
