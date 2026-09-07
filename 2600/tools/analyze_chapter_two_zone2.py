#!/usr/bin/env python3
"""Verify Zone 2-2 layout, collision geometry, and unattended launch safety."""

from collections import deque
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

LEFT_INSETS = (80, 28, 20, 24, 36, 16, 48, 40, 16, 40, 36,
               16, 28, 36, 24, 20, 32, 48, 44, 28, 28, 80)
RIGHT_INSETS = (80, 24, 24, 40, 48, 16, 24, 20, 24, 36, 28,
                32, 40, 16, 48, 44, 44, 40, 28, 16, 32, 80)
JUNK = ((84, 51), (63, 95), (102, 141))
RELIC = (30, 9)
BEACONS = ((79, 38), (94, 82), (79, 126))


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
        magnitude = max(signed(vy) * 2, 0x80)
        vy = (-magnitude) & 0xFFFF
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
    return x, y, vx, vy


def idle_hits(spawn_x, spawn_y, vx, vy, frames=3000):
    state = (spawn_x << 8, spawn_y << 8, vx & 0xFFFF, vy & 0xFFFF)
    hits = set()
    for _ in range(frames):
        state = step(state)
        x, y = state[0] >> 8, state[1] >> 8
        for index, (junk_x, junk_y) in enumerate(JUNK):
            if overlaps(x, y, junk_x, junk_y):
                hits.add(index)
    return hits


def main():
    if len(sys.argv) != 3:
        raise SystemExit("usage: analyze_chapter_two_zone2.py ROM SYMBOLS")
    rom = Path(sys.argv[1]).read_bytes()
    symbols = Path(sys.argv[2]).read_text()

    def address(name):
        match = re.search(rf"^(?:0\.)?{re.escape(name)}\s+([0-9a-fA-F]{{4}})\b", symbols, re.M)
        if not match:
            raise SystemExit(f"missing Zone 2-2 symbol: {name}")
        return int(match.group(1), 16)

    def bank_bytes(bank, name, length):
        start = bank * 4096 + (address(name) & 0x0FFF)
        return tuple(rom[start:start + length])

    expected = {
        "StageSpawnX": (50, 68), "StageSpawnY": (16, 146),
        "StageVelocityXHi": (0, 0xFF), "StageVelocityXLo": (0x60, 0xA0),
        "StageVelocityYHi": (0xFF, 0x00), "StageVelocityYLo": (0xA0, 0x60),
        "Dish0XByStage": (96, 75), "Dish1XByStage": (102, 90),
        "Dish2XByStage": (96, 75), "Collect0XByStage": (102, 84),
        "Collect1XByStage": (75, 63), "Collect2XByStage": (84, 102),
        "OptionalXByStage": (130, 30), "ExitXByStage": (78, 87),
    }
    for name, values in expected.items():
        actual = bank_bytes(0, name, len(values))
        if actual != values:
            raise SystemExit(f"{name} drifted: expected {values}, got {actual}")

    if bank_bytes(0, "Stage2LeftInsetByBand", 22) != LEFT_INSETS:
        raise SystemExit("Zone 2-2 left collision terrain drifted")
    if bank_bytes(0, "Stage2RightInsetByBand", 22) != RIGHT_INSETS:
        raise SystemExit("Zone 2-2 right collision terrain drifted")

    left_pf = bank_bytes(6, "Stage2TerrainLeftPF1", 176)
    right_pf = bank_bytes(6, "Stage2TerrainRightPF1", 176)
    pf_depth = {0x00: 16, 0x80: 20, 0xC0: 24, 0xE0: 28,
                0xF0: 32, 0xF8: 36, 0xFC: 40, 0xFE: 44, 0xFF: 48}
    for band in range(1, 21):
        visible_left = pf_depth[left_pf[band * 8]]
        visible_right = pf_depth[right_pf[band * 8]]
        if visible_left != LEFT_INSETS[band]:
            raise SystemExit(f"left visible/collision mismatch in band {band}")
        if visible_right != RIGHT_INSETS[band]:
            raise SystemExit(f"right visible/collision mismatch in band {band}")

    pf2 = bank_bytes(6, "Stage2TerrainPF2", 176)
    if pf2[:8] != (0xFF,) * 8 or pf2[168:] != (0xFF,) * 8:
        raise SystemExit("Zone 2-2 ceiling or floor geometry drifted")
    expected_pf2 = (0xFF,) * 8 + (0,) * 160 + (0xFF,) * 8
    if pf2 != expected_pf2:
        raise SystemExit("Zone 2-2 contains an unapproved chamber-spanning PF2 obstacle")

    colors = bank_bytes(6, "Stage2TerrainColor", 176)
    elastic_a = (0x4C, 0x3E, 0x2E, 0xCE, 0xAE, 0x8E, 0x6E, 0x5E)
    elastic_b = tuple(reversed(elastic_a))
    if colors[72:80] != elastic_a or colors[80:88] != elastic_b:
        raise SystemExit("Zone 2-2 elastic side bands lost their opposing rainbow ramps")

    # Odd shelf rows pre-stage the next even row's animated color. This keeps
    # the approved playfield writes untouched and confines motion to elastic.
    source = Path("src/thursdays-child.asm").read_text()
    animation_contract = (
        "and #7\n        sta stageOffset",
        "adc stageOffset\n        and #7",
        "lda Stage2ElasticFlowColors,y\n        jmp Stage2ShelfColorReady",
        "byte 8,0,2,0,4,0,6,0,7,0,5,0,3,0,1,0,$80",
    )
    for fragment in animation_contract:
        if fragment not in source:
            raise SystemExit("Zone 2-2 elastic material animation contract drifted")

    # Elastic classification must use the candidate sprite rectangle, not its
    # top or center point: Y=59 is the first position that overlaps shelf Y=72.
    overlap_contract = (
        "cmp #88",
        "adc #ASTRONAUT_H",
        "cmp #73",
        "jsr DoubleHorizontalVelocityCapped",
    )
    for fragment in overlap_contract:
        if fragment not in source:
            raise SystemExit("Zone 2-2 2x elastic-overlap contract drifted")

    # Every authored orbit point must fit. This catches terrain that is globally
    # navigable but locally blocks a satellite and makes Major Tom appear offset
    # instead of circling it.
    def signed_byte(value):
        return value - 256 if value >= 128 else value

    for radius in ("Near", "Mid", "Far"):
        orbit_x = tuple(map(signed_byte, bank_bytes(0, f"OrbitX{radius}", 64)))
        orbit_y = tuple(map(signed_byte, bank_bytes(0, f"OrbitY{radius}", 64)))
        for beacon in BEACONS:
            for angle, (dx, dy) in enumerate(zip(orbit_x, orbit_y)):
                top_left = (beacon[0] + dx - 4, beacon[1] + dy - 7)
                if terrain_hit(*top_left):
                    raise SystemExit(
                        f"{radius} orbit angle {angle} at satellite {beacon} "
                        f"intersects terrain at {top_left}"
                    )

    # The far tier also renders a midpoint between every adjacent table pair.
    # These are live orbit positions and must obey the same terrain contract.
    far_x = tuple(map(signed_byte, bank_bytes(0, "OrbitXFar", 64)))
    far_y = tuple(map(signed_byte, bank_bytes(0, "OrbitYFar", 64)))
    for beacon in BEACONS:
        for angle in range(64):
            next_angle = (angle + 1) & 63
            dx = ((far_x[angle] + 32 + far_x[next_angle] + 32) >> 1) - 32
            dy = ((far_y[angle] + 32 + far_y[next_angle] + 32) >> 1) - 32
            top_left = (beacon[0] + dx - 4, beacon[1] + dy - 7)
            if terrain_hit(*top_left):
                raise SystemExit(
                    f"Far orbit midpoint {angle} at satellite {beacon} "
                    f"intersects terrain at {top_left}"
                )

    # An eight-pixel-wide astronaut route must remain open through every band.
    # This makes sealed upper/lower pockets structurally impossible.
    for band, (left, right) in enumerate(zip(LEFT_INSETS[1:-1], RIGHT_INSETS[1:-1]), 1):
        if 152 - right - left < 8:
            raise SystemExit(f"Zone 2-2 band {band} closes the recovery corridor")
    # Prove that every legal astronaut position belongs to one connected free-
    # space component and that the component reaches every satellite field.
    legal = {(x, y) for y in range(TOP_LIMIT, BOTTOM_LIMIT + 1)
             for x in range(LEFT_LIMIT, RIGHT_LIMIT + 1)
             if not terrain_hit(x, y)}
    spawn = (68, 146)
    if spawn not in legal:
        raise SystemExit("Zone 2-2 spawn intersects terrain")
    reached = {spawn}
    queue = deque((spawn,))
    while queue:
        x, y = queue.popleft()
        for neighbor in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
            if neighbor in legal and neighbor not in reached:
                reached.add(neighbor)
                queue.append(neighbor)
    if reached != legal:
        raise SystemExit(f"Zone 2-2 has {len(legal - reached)} legal positions in a sealed pocket")
    for beacon_x, beacon_y in BEACONS:
        capture_cells = {(x, y) for x, y in reached
                         if abs(x + 4 - beacon_x) < 20
                         and abs(y + 7 - beacon_y) < 20
                         and abs(x + 4 - beacon_x) + abs(y + 7 - beacon_y) < 30}
        if not capture_cells:
            raise SystemExit(f"satellite at {(beacon_x, beacon_y)} has no reachable capture field")

    for label, (x, y) in (("relic", RELIC), *(('junk', item) for item in JUNK)):
        if terrain_hit(x, y):
            raise SystemExit(f"Zone 2-2 {label} at {(x, y)} intersects terrain")

    # The natural launch is allowed to travel, but it must leave a substantial
    # control window rather than collecting the room on its opening descent.
    hits = idle_hits(68, 146, 0xFFA0, 0x0060, frames=1200)
    if hits:
        raise SystemExit(f"unattended launch intersects Junk objects {sorted(hits)}")
    print("Chapter 2 Zone 2 verification passed: aggressive renderer-matched side teeth, two animated rainbow elastic side bands with full-sprite 2x contact, one connected cavity, three complete terrain-clear orbit families, distributed objects, displaced exit, and no Junk contacts during the 1,200-frame opening window")


if __name__ == "__main__":
    main()
