#!/usr/bin/env python3
"""Verify Zone 2-3 geometry, orbit clearance, connectivity, and launch safety."""

from collections import deque
from pathlib import Path
import re
import sys

GRAVITY = 4
MAX_FALL = 0x00E0
LEFT_LIMIT, RIGHT_LIMIT = 16, 136
TOP_LIMIT, BOTTOM_LIMIT = 8, 154
ASTRONAUT_W, ASTRONAUT_H = 8, 14
LEFT_INSETS = (80, 24, 20, 16, 20, 24, 28, 32, 40, 48, 36,
               44, 32, 24, 20, 16, 24, 28, 32, 36, 28, 80)
RIGHT_INSETS = (80, 28, 32, 36, 28, 24, 20, 16, 16, 16, 16,
                16, 16, 16, 16, 16, 20, 24, 28, 32, 36, 80)
PLATFORMS = ((64, 96, 64, 72), (64, 96, 80, 88), (64, 96, 104, 112))
BEACONS = ((79, 34), (121, 88), (79, 138))
JUNK = ((81, 49), (102, 99), (81, 147))
RELIC = (24, 11)


def signed(value):
    return value - 0x10000 if value & 0x8000 else value


def rect_overlap(x, y, left, right, top, bottom):
    return x + ASTRONAUT_W > left and x < right and y + ASTRONAUT_H > top and y < bottom


def terrain_hit(x, y):
    if y < TOP_LIMIT or y + ASTRONAUT_H > 168:
        return True
    bands = range(y // 8, (y + ASTRONAUT_H - 1) // 8 + 1)
    if x < max(LEFT_INSETS[b] for b in bands):
        return True
    if x > 152 - max(RIGHT_INSETS[b] for b in bands):
        return True
    return any(rect_overlap(x, y, *platform) for platform in PLATFORMS)


def overlaps(x, y, object_x, object_y):
    return (x + ASTRONAUT_W > object_x and object_x + 8 > x and
            y + ASTRONAUT_H > object_y and object_y + 14 > y)


def elastic_contact(x, y):
    return (rect_overlap(x, y, *PLATFORMS[0]) or
            rect_overlap(x, y, *PLATFORMS[2]))


def step(state):
    x, y, vx, vy = state
    safe_x, safe_y = x, y
    vy = min(signed((vy + GRAVITY) & 0xFFFF), MAX_FALL)
    x = (x + signed(vx)) & 0xFFFF
    y = (y + signed(vy)) & 0xFFFF
    x_hi, y_hi = (x >> 8) & 0xFF, (y >> 8) & 0xFF
    if signed(vy) >= 0 and y_hi >= BOTTOM_LIMIT + 1:
        y, vy, y_hi = BOTTOM_LIMIT << 8, (-max(signed(vy) * 2, 0x80)) & 0xFFFF, BOTTOM_LIMIT
    if signed(vy) < 0 and (y_hi >= 240 or y_hi < TOP_LIMIT):
        y, vy, y_hi = TOP_LIMIT << 8, 0x0080, TOP_LIMIT
    if signed(vx) >= 0 and x_hi >= RIGHT_LIMIT + 1:
        x, vx, x_hi = RIGHT_LIMIT << 8, 0xFF80, RIGHT_LIMIT
    elif signed(vx) < 0 and (x_hi >= 160 or x_hi < LEFT_LIMIT + 1):
        x, vx, x_hi = LEFT_LIMIT << 8, 0x0080, LEFT_LIMIT
    if terrain_hit(x_hi, y_hi):
        x_axis = terrain_hit(x_hi, safe_y >> 8)
        y_axis = terrain_hit(safe_x >> 8, y_hi)
        if not x_axis and not y_axis:
            x_axis = y_axis = True
        hit_elastic = elastic_contact(x_hi, y_hi)
        x, y = safe_x, safe_y
        if x_axis:
            vx = (-signed(vx)) & 0xFFFF
            if hit_elastic:
                vx = max(-0x01C0, min(0x01C0, signed(vx) * 2)) & 0xFFFF
        if y_axis:
            if hit_elastic:
                vy = 0x0100 if signed(vy) < 0 else 0xFE80
            else:
                vy = 0x0080 if signed(vy) < 0 else 0xFF40
    return x, y, vx, vy


def main():
    if len(sys.argv) != 3:
        raise SystemExit("usage: analyze_chapter_two_zone3.py ROM SYMBOLS")
    rom = Path(sys.argv[1]).read_bytes()
    symbols = Path(sys.argv[2]).read_text()

    def address(name):
        match = re.search(rf"^(?:0\.)?{re.escape(name)}\s+([0-9a-fA-F]{{4}})\b", symbols, re.M)
        if not match:
            raise SystemExit(f"missing Zone 2-3 symbol: {name}")
        return int(match.group(1), 16)

    def bank_bytes(bank, name, length):
        start = bank * 4096 + (address(name) & 0x0FFF)
        return tuple(rom[start:start + length])

    expected = {
        "StageSpawnX": (50, 40, 48), "StageSpawnY": (16, 16, 40),
        "StageVelocityXHi": (0, 0, 0xFF), "StageVelocityXLo": (0x60, 0x60, 0x70),
        "StageVelocityYHi": (0xFF, 0xFF, 0xFF), "StageVelocityYLo": (0xA0, 0xA0, 0xA0),
        "Dish0XByStage": (96, 75, 75), "Dish1XByStage": (102, 90, 117),
        "Dish2XByStage": (96, 96, 75), "Collect0XByStage": (102, 114, 81),
        "Collect1XByStage": (75, 78, 102), "Collect2XByStage": (84, 102, 81),
        "OptionalXByStage": (130, 100, 24), "ExitXByStage": (78, 90, 99),
    }
    for name, values in expected.items():
        actual = bank_bytes(0, name, len(values))
        if actual != values:
            raise SystemExit(f"{name} drifted: expected {values}, got {actual}")
    if bank_bytes(0, "Stage3LeftInsetByBand", 22) != LEFT_INSETS:
        raise SystemExit("Zone 2-3 left collision terrain drifted")
    if bank_bytes(0, "Stage3RightInsetByBand", 22) != RIGHT_INSETS:
        raise SystemExit("Zone 2-3 right collision terrain drifted")

    pf_depth = {0x00: 16, 0x80: 20, 0xC0: 24, 0xE0: 28,
                0xF0: 32, 0xF8: 36, 0xFC: 40, 0xFE: 44, 0xFF: 48}
    left_pf = bank_bytes(5, "Stage3TerrainLeftPF1", 176)
    right_pf = bank_bytes(5, "Stage3TerrainRightPF1", 176)
    for band in range(1, 21):
        if pf_depth[left_pf[band * 8]] != LEFT_INSETS[band]:
            raise SystemExit(f"left visible/collision mismatch in band {band}")
        if pf_depth[right_pf[band * 8]] != RIGHT_INSETS[band]:
            raise SystemExit(f"right visible/collision mismatch in band {band}")
    expected_pf2 = ((0xFF,) * 8 + (0,) * 56 + (0xF0,) * 8 + (0,) * 8 +
                    (0xF0,) * 8 + (0,) * 16 + (0xF0,) * 8 + (0,) * 56 +
                    (0xFF,) * 8)
    if bank_bytes(5, "Stage3TerrainPF2", 176) != expected_pf2:
        raise SystemExit("Zone 2-3 center-platform rendering drifted")

    def signed_byte(value):
        return value - 256 if value >= 128 else value
    for radius in ("Near", "Mid", "Far"):
        ox = tuple(map(signed_byte, bank_bytes(0, f"OrbitX{radius}", 64)))
        oy = tuple(map(signed_byte, bank_bytes(0, f"OrbitY{radius}", 64)))
        for beacon in BEACONS:
            for angle, (dx, dy) in enumerate(zip(ox, oy)):
                point = beacon[0] + dx - 4, beacon[1] + dy - 7
                if terrain_hit(*point):
                    raise SystemExit(f"{radius} orbit {angle} at {beacon} intersects terrain at {point}")

    legal = {(x, y) for y in range(TOP_LIMIT, BOTTOM_LIMIT + 1)
             for x in range(LEFT_LIMIT, RIGHT_LIMIT + 1) if not terrain_hit(x, y)}
    spawn = (48, 40)
    if spawn not in legal:
        raise SystemExit("Zone 2-3 spawn intersects terrain")
    reached, queue = {spawn}, deque((spawn,))
    while queue:
        x, y = queue.popleft()
        for neighbor in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
            if neighbor in legal and neighbor not in reached:
                reached.add(neighbor); queue.append(neighbor)
    if reached != legal:
        raise SystemExit(f"Zone 2-3 has {len(legal - reached)} legal positions in a sealed pocket")
    for beacon_x, beacon_y in BEACONS:
        if not any(abs(x + 4 - beacon_x) < 20 and abs(y + 7 - beacon_y) < 20 and
                   abs(x + 4 - beacon_x) + abs(y + 7 - beacon_y) < 30 for x, y in reached):
            raise SystemExit(f"satellite at {(beacon_x, beacon_y)} has no reachable capture field")
    for label, point in (("relic", RELIC), *(("junk", item) for item in JUNK)):
        if terrain_hit(*point):
            raise SystemExit(f"Zone 2-3 {label} at {point} intersects terrain")

    state = (48 << 8, 40 << 8, 0xFF70, 0xFFA0)
    hits = set()
    for _ in range(1200):
        state = step(state)
        for i, point in enumerate(JUNK):
            if overlaps(state[0] >> 8, state[1] >> 8, *point):
                hits.add(i)
    if hits:
        raise SystemExit(f"unattended launch intersects Junk objects {sorted(hits)}")

    source = Path("src/thursdays-child.asm").read_text()
    for fragment in ("cmp #72", "cmp #65", "cmp #112", "cmp #105",
                     "jsr IsChapter2ElasticContact", "jsr DoubleHorizontalVelocityCapped"):
        if fragment not in source:
            raise SystemExit("Zone 2-3 full-sprite elastic collision contract drifted")
    print("Chapter 2 Zone 3 verification passed: three renderer-matched center platforms, animated 2x elastic upper/lower surfaces, one connected recovery cavity, three complete terrain-clear orbit families, distributed mission objects, and no opening-path Junk contacts")


if __name__ == "__main__":
    main()
