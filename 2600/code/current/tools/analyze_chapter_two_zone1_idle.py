#!/usr/bin/env python3
"""Verify Zone 2-1 layout, terrain collision, and unattended launch safety."""

from pathlib import Path
import re
import sys

GRAVITY = 4
MAX_FALL = 0x00E0
LEFT_LIMIT = 16
RIGHT_LIMIT = 136
TOP_LIMIT = 8
BOTTOM_LIMIT = 154
ASTRONAUT_LAST = 13

LEFT_INSETS = (80, 32, 28, 24, 20, 16, 48, 28, 24, 20, 16,
               16, 16, 20, 24, 20, 16, 20, 24, 28, 32, 80)
RIGHT_INSETS = (80, 20, 16, 16, 16, 20, 24, 28, 24, 48, 32,
                16, 20, 28, 32, 24, 16, 16, 20, 24, 28, 80)
JUNK = ((108, 49), (75, 97), (84, 145))


def signed(value):
    return value - 0x10000 if value & 0x8000 else value


def terrain_hit(x, y):
    if y < 8 or y + ASTRONAUT_LAST >= 168:
        return True
    bands = range(y // 8, (y + ASTRONAUT_LAST) // 8 + 1)
    left = max(LEFT_INSETS[index] for index in bands)
    right = max(RIGHT_INSETS[index] for index in bands)
    return x < left or x > 152 - right


def overlaps(x, y, object_x, object_y):
    return (x + 8 > object_x and object_x + 8 > x and
            y + 14 > object_y and object_y + 14 > y)


def step(state):
    x, y, vx, vy = state
    safe_x, safe_y = x, y
    vy = min(signed((vy + GRAVITY) & 0xFFFF), MAX_FALL)
    x = (x + signed(vx)) & 0xFFFF
    y = (y + signed(vy)) & 0xFFFF
    x_hi, y_hi = (x >> 8) & 0xFF, (y >> 8) & 0xFF

    if signed(vy) >= 0 and y_hi >= BOTTOM_LIMIT + 1:
        y = BOTTOM_LIMIT << 8
        doubled = min(signed(vy) * 2, 0x01C0)
        doubled = max(doubled, 0x0080)
        vy = (-doubled) & 0xFFFF
        y_hi = BOTTOM_LIMIT
    if signed(vy) < 0 and (y_hi >= 240 or y_hi < TOP_LIMIT):
        y = TOP_LIMIT << 8
        vy = 0x0080
        y_hi = TOP_LIMIT
    if signed(vx) >= 0 and x_hi >= RIGHT_LIMIT + 1:
        x = RIGHT_LIMIT << 8
        vx = 0xFF80
        x_hi = RIGHT_LIMIT
    elif signed(vx) < 0 and (x_hi >= 160 or x_hi < LEFT_LIMIT + 1):
        x = LEFT_LIMIT << 8
        vx = 0x0080
        x_hi = LEFT_LIMIT

    if terrain_hit(x_hi, y_hi):
        candidate_x, candidate_y = x_hi, y_hi
        x_axis = terrain_hit(candidate_x, safe_y >> 8)
        y_axis = terrain_hit(safe_x >> 8, candidate_y)
        if not x_axis and not y_axis:
            x_axis = y_axis = True
        x, y = safe_x, safe_y
        if x_axis:
            vx = (-signed(vx)) & 0xFFFF
        if y_axis:
            vy = 0x0080 if signed(vy) < 0 else 0xFF40
        if signed(vx) == 0:
            vx = 0x0080 if (x >> 8) < 80 else 0xFF80
    return x, y, vx, vy


def idle_hits(spawn_x, spawn_y, vx, vy, frames=1200):
    state = (spawn_x << 8, spawn_y << 8, vx & 0xFFFF, vy & 0xFFFF)
    hits = set()
    for frame in range(frames):
        state = step(state)
        x, y = state[0] >> 8, state[1] >> 8
        for index, (junk_x, junk_y) in enumerate(JUNK):
            if overlaps(x, y, junk_x, junk_y):
                hits.add(index)
        if len(hits) == len(JUNK):
            break
    return hits


def main():
    if len(sys.argv) != 3:
        raise SystemExit("usage: analyze_chapter_two_zone1_idle.py ROM SYMBOLS")
    rom = Path(sys.argv[1]).read_bytes()
    symbols = Path(sys.argv[2]).read_text()

    def address(name):
        match = re.search(
            rf"^(?:0\.)?{re.escape(name)}\s+([0-9a-fA-F]{{4}})\b",
            symbols,
            re.M,
        )
        if not match:
            raise SystemExit(f"missing Zone 2-1 symbol: {name}")
        return int(match.group(1), 16)

    def bank_bytes(bank, name, length):
        start = bank * 4096 + (address(name) & 0x0FFF)
        return tuple(rom[start:start + length])

    expected_tables = {
        "StageSpawnX": (40,),
        "StageSpawnY": (136,),
        "StageVelocityXHi": (0xFF,),
        "StageVelocityXLo": (0xC0,),
        "StageVelocityYHi": (0xFF,),
        "StageVelocityYLo": (0x80,),
        "Dish0XByStage": (108,),
        "Dish1XByStage": (66,),
        "Dish2XByStage": (75,),
        "BeaconXTable": (112, 70, 79),
        "Collect0XByStage": (108,),
        "Collect1XByStage": (75,),
        "Collect2XByStage": (84,),
        "OptionalXByStage": (28,),
        "ExitXByStage": (111,),
    }
    for name, expected in expected_tables.items():
        actual = bank_bytes(0, name, len(expected))
        if actual != expected:
            raise SystemExit(f"{name} drifted: expected {expected}, got {actual}")

    if bank_bytes(0, "TerrainLeftInsetByBand", 22) != LEFT_INSETS:
        raise SystemExit("Zone 2-1 left collision shelf drifted")
    if bank_bytes(0, "TerrainRightInsetByBand", 22) != RIGHT_INSETS:
        raise SystemExit("Zone 2-1 right collision shelf drifted")

    left_pf = bank_bytes(7, "TerrainLeftPF1", 176)
    right_pf = bank_bytes(7, "TerrainRightPF1", 176)
    pf_depth = {0x00: 16, 0x80: 20, 0xC0: 24, 0xE0: 28,
                0xF0: 32, 0xFF: 48}
    for band in range(1, 21):
        visible_left = pf_depth[left_pf[band * 8]]
        visible_right = pf_depth[right_pf[band * 8]]
        if visible_left != LEFT_INSETS[band]:
            raise SystemExit(f"left shelf/collision mismatch in band {band}")
        if visible_right != RIGHT_INSETS[band]:
            raise SystemExit(f"right shelf/collision mismatch in band {band}")

    hits = idle_hits(40, 136, -0x40, -0x80, 3000)
    if hits:
        raise SystemExit(f"unattended launch intersects Junk objects {sorted(hits)}")
    print(
        "Chapter 2 Zone 1 layout verification passed: left/right satellite and "
        "Junk distribution, two renderer-matched collision shelves, displaced "
        "exit, and zero unattended Junk contacts during the 3,000-frame "
        "opening route"
    )


if __name__ == "__main__":
    main()
