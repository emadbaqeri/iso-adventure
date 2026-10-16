"""Shared 8×4 palette swatches for Ashfrost (warden + environment)."""

from __future__ import annotations

PALETTE_COLS = 8
PALETTE_ROWS = 4
TEX_W = 256
TEX_H = 128

# (col, row) — rows 0–1 warden, 2–3 environment
SW = {
    # Warden (row 0–1)
    "cloak": (0, 0),
    "cloak_dark": (1, 0),
    "fur": (2, 0),
    "skin": (3, 0),
    "hood": (4, 0),
    "belt": (5, 0),
    "metal": (6, 0),
    "boot": (7, 0),
    "pants": (0, 1),
    "glove": (1, 1),
    "trim": (2, 1),
    "shadow": (3, 1),
    # Environment (row 2)
    "stone_light": (0, 2),
    "stone_mid": (1, 2),
    "stone_dark": (2, 2),
    "stone_moss": (3, 2),
    "wood": (4, 2),
    "ember": (5, 2),
    "snow": (6, 2),
    "ice": (7, 2),
    # Environment (row 3)
    "pine": (0, 3),
    "pine_dark": (1, 3),
    "bush": (2, 3),
    "dead_wood": (3, 3),
    "grass": (4, 3),
    "heather": (5, 3),
    "rock": (6, 3),
    "snow_patch": (7, 3),
}

SWATCH_RGB: list[tuple[float, float, float, float]] = [
    # Row 0 — warden
    (0.22, 0.28, 0.38, 1.0),
    (0.14, 0.18, 0.26, 1.0),
    (0.78, 0.76, 0.72, 1.0),
    (0.55, 0.48, 0.42, 1.0),
    (0.18, 0.22, 0.30, 1.0),
    (0.32, 0.24, 0.16, 1.0),
    (0.62, 0.52, 0.28, 1.0),
    (0.12, 0.12, 0.14, 1.0),
    # Row 1 — warden
    (0.26, 0.30, 0.38, 1.0),
    (0.20, 0.24, 0.30, 1.0),
    (0.42, 0.36, 0.30, 1.0),
    (0.10, 0.12, 0.16, 1.0),
    # Row 2 — stone / props
    (0.52, 0.56, 0.62, 1.0),
    (0.42, 0.46, 0.52, 1.0),
    (0.30, 0.34, 0.40, 1.0),
    (0.36, 0.42, 0.34, 1.0),
    (0.38, 0.28, 0.18, 1.0),
    (0.92, 0.42, 0.18, 1.0),
    (0.88, 0.90, 0.94, 1.0),
    (0.72, 0.82, 0.92, 1.0),
    # Row 3 — foliage
    (0.22, 0.34, 0.28, 1.0),
    (0.14, 0.22, 0.18, 1.0),
    (0.28, 0.38, 0.26, 1.0),
    (0.32, 0.28, 0.24, 1.0),
    (0.48, 0.52, 0.38, 1.0),
    (0.58, 0.48, 0.62, 1.0),
    (0.46, 0.48, 0.52, 1.0),
    (0.94, 0.96, 0.98, 1.0),
]

# Pad to full grid
while len(SWATCH_RGB) < PALETTE_COLS * PALETTE_ROWS:
    SWATCH_RGB.append(SWATCH_RGB[0])
