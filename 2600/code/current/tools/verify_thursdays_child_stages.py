#!/usr/bin/env python3
"""Audit Thursday's Child 0.9B four-stage Chapter One descriptors."""

from pathlib import Path
import re
import sys


if len(sys.argv) != 4:
    raise SystemExit("usage: verify_thursdays_child_stages.py ROM SYM SOURCE")

rom = Path(sys.argv[1]).read_bytes()
symbols = Path(sys.argv[2]).read_text()
source = Path(sys.argv[3]).read_text()
if len(rom) != 32768:
    raise SystemExit("production stage audit requires the 32K F4 ROM")


def symbol(name: str) -> int:
    match = re.search(rf"^{re.escape(name)}\s+([0-9a-fA-F]{{4}})\b", symbols, re.M)
    if not match:
        raise SystemExit(f"missing production-stage symbol: {name}")
    return int(match.group(1), 16)


stage_count = symbol("STAGE_COUNT")
if stage_count != 5:
    raise SystemExit("0.9B must expose exactly five Chapter One stages")


def table(name: str, length: int = stage_count) -> list[int]:
    address = symbol(name)
    if not 0xF000 <= address <= 0xFFFF:
        raise SystemExit(f"{name} is outside cartridge space")
    start = address & 0x0FFF  # every descriptor currently belongs to Bank 0
    values = list(rom[start : start + length])
    if len(values) != length:
        raise SystemExit(f"{name} is truncated")
    return values


field_names = (
    "StageSpawnX", "StageSpawnY",
    "StageVelocityXHi", "StageVelocityXLo",
    "StageVelocityYHi", "StageVelocityYLo",
    "StageBeaconOffset", "StageTerrainId", "StagePaletteId",
    "StageBehaviorId", "StageMusicId", "StageRoomBank", "StageNextByStage",
    "Dish0XByStage", "Dish0YByStage", "Dish1XByStage", "Dish1YByStage",
    "Dish2XByStage", "Dish2YByStage",
    "Collect0XByStage", "Collect0YByStage",
    "Collect1XByStage", "Collect1YByStage",
    "Collect2XByStage", "Collect2YByStage",
    "OptionalXByStage", "OptionalYByStage", "ExitXByStage", "ExitYByStage",
)
fields = {name: table(name) for name in field_names}

# Every stage must be reachable exactly once from Stage 1, and the final stage
# must terminate explicitly instead of falling into arbitrary ROM data.
seen: list[int] = []
stage = 0
while stage != 0xFF:
    if stage >= stage_count:
        raise SystemExit(f"stage chain points outside descriptor range: {stage}")
    if stage in seen:
        raise SystemExit(f"stage chain contains a loop at stage {stage + 1}")
    seen.append(stage)
    stage = fields["StageNextByStage"][stage]
if seen != list(range(stage_count)):
    raise SystemExit(f"stage chain is not ordered and complete: {seen}")

if fields["StageRoomBank"] != [7, 6, 5, 4, 3]:
    raise SystemExit("Stage 1-5 renderers are not assigned to Banks 7-3")
if fields["StageTerrainId"] != [0, 1, 2, 3, 4]:
    raise SystemExit("Chapter One stages lost their independent terrain identities")
if len(set(fields["StagePaletteId"])) != stage_count:
    raise SystemExit("Chapter One stages unexpectedly share a palette")
if any(value != 0 for value in fields["StageBehaviorId"]):
    raise SystemExit("0.9B stages must retain normal-rock behavior")
if any(value != 0 for value in fields["StageMusicId"]):
    raise SystemExit("all five stages must retain the Chapter One theme")

# Reset is the only special boot path. Its constants must remain byte-identical
# to descriptor row zero so starting a new game and loading a stage agree.
if fields["StageSpawnX"][0] != symbol("SPAWN_X"):
    raise SystemExit("Stage 1 reset X disagrees with descriptor row zero")
if fields["StageSpawnY"][0] != symbol("SPAWN_Y"):
    raise SystemExit("Stage 1 reset Y disagrees with descriptor row zero")
if [fields[name][0] for name in (
    "StageVelocityXHi", "StageVelocityXLo", "StageVelocityYHi", "StageVelocityYLo"
)] != [0x00, 0x60, 0xFF, 0xA0]:
    raise SystemExit("Stage 1 reset velocity disagrees with descriptor row zero")

beacon_x = table("BeaconXTable", stage_count * 3)
beacon_y = table("BeaconYTable", stage_count * 3)
for stage in range(stage_count):
    offset = fields["StageBeaconOffset"][stage]
    if offset != stage * 3 or offset + 2 >= len(beacon_x):
        raise SystemExit(f"stage {stage + 1} has an invalid beacon triplet offset")
    for dish in range(3):
        dish_x = fields[f"Dish{dish}XByStage"][stage]
        dish_y = fields[f"Dish{dish}YByStage"][stage]
        if beacon_x[offset + dish] != dish_x + 4:
            raise SystemExit(f"stage {stage + 1} satellite {dish + 1} is not X-centered")
        if beacon_y[offset + dish] != dish_y + 7:
            raise SystemExit(f"stage {stage + 1} satellite {dish + 1} is not Y-centered")

terrain = {
    0: (table("TerrainLeftInsetByBand", 22), table("TerrainRightInsetByBand", 22)),
    1: (table("Stage2LeftInsetByBand", 22), table("Stage2RightInsetByBand", 22)),
    2: (table("Stage3LeftInsetByBand", 22), table("Stage3RightInsetByBand", 22)),
    3: (table("Stage4LeftInsetByBand", 22), table("Stage4RightInsetByBand", 22)),
    4: (table("Stage5LeftInsetByBand", 22), table("Stage5RightInsetByBand", 22)),
}


def require_clear(stage: int, name: str, x: int, y: int, width: int, height: int):
    left, right = terrain[fields["StageTerrainId"][stage]]
    if not 0 <= x <= 160 - width or not 0 <= y <= 176 - height:
        raise SystemExit(f"stage {stage + 1} {name} leaves the 160x176 room")
    for band in range(y // 8, (y + height - 1) // 8 + 1):
        open_left = left[band]
        open_right = 160 - right[band]
        if x < open_left or x + width > open_right:
            raise SystemExit(
                f"stage {stage + 1} {name} enters terrain in band {band}: "
                f"x={x}..{x + width - 1}, open={open_left}..{open_right - 1}"
            )


for stage in range(stage_count):
    spawn_x = fields["StageSpawnX"][stage]
    spawn_y = fields["StageSpawnY"][stage]
    require_clear(stage, "spawn", spawn_x, spawn_y, 8, 14)

    for dish in range(3):
        require_clear(
            stage, f"satellite {dish + 1}",
            fields[f"Dish{dish}XByStage"][stage],
            fields[f"Dish{dish}YByStage"][stage], 8, 15,
        )

    pickups = []
    for item in range(3):
        x = fields[f"Collect{item}XByStage"][stage]
        y = fields[f"Collect{item}YByStage"][stage]
        require_clear(stage, f"required collectible {item + 1}", x, y, 8, 14)
        pickups.append((x, y))
    optional_x = fields["OptionalXByStage"][stage]
    optional_y = fields["OptionalYByStage"][stage]
    require_clear(stage, "optional salvage", optional_x, optional_y, 8, 14)
    pickups.append((optional_x, optional_y))

    for x, y in pickups:
        if spawn_x + 8 > x and x + 8 > spawn_x and spawn_y + 14 > y and y + 14 > spawn_y:
            raise SystemExit(f"stage {stage + 1} spawn overlaps a collectible")

    exit_x = fields["ExitXByStage"][stage]
    exit_y = fields["ExitYByStage"][stage]
    if not 0 <= exit_x <= 152 or not 0 <= exit_y <= 162:
        raise SystemExit(f"stage {stage + 1} extraction gate leaves the room")

# Each renderer now owns an authored display schedule. Physics metadata must
# agree exactly so what the player sees and what collision code tests coincide.
expected_dish_y = (
    (29, 77, 123), (31, 75, 119), (33, 75, 117),
    (33, 79, 121), (29, 83, 125),
)
expected_collect_y = (
    (49, 97, 145), (51, 95, 141), (53, 95, 139),
    (53, 99, 143), (49, 103, 143),
)
expected_optional_y = (9, 9, 11, 13, 9)
expected_exit_y = (161, 157, 155, 159, 159)
for stage in range(stage_count):
    if tuple(fields[f"Dish{i}YByStage"][stage] for i in range(3)) != expected_dish_y[stage]:
        raise SystemExit(f"stage {stage + 1} dish Y data disagrees with its service page")
    if tuple(fields[f"Collect{i}YByStage"][stage] for i in range(3)) != expected_collect_y[stage]:
        raise SystemExit(f"stage {stage + 1} collectible Y data disagrees with its service page")
    if (fields["OptionalYByStage"][stage] != expected_optional_y[stage]
            or fields["ExitYByStage"][stage] != expected_exit_y[stage]):
        raise SystemExit(f"stage {stage + 1} upper/exit Y data disagrees with renderer")

layout_signatures = []
for stage in range(stage_count):
    signature = []
    for kind in ("Dish", "Collect"):
        for item in range(3):
            signature.extend((
                fields[f"{kind}{item}XByStage"][stage],
                fields[f"{kind}{item}YByStage"][stage],
            ))
    signature.extend((
        fields["OptionalXByStage"][stage], fields["OptionalYByStage"][stage],
        fields["ExitXByStage"][stage], fields["ExitYByStage"][stage],
    ))
    layout_signatures.append(tuple(signature))
if len(set(layout_signatures)) != stage_count:
    raise SystemExit("two Chapter One stages still share the same object layout")

# Stage 1 deliberately teaches a gentle ladder. Every later stage must avoid
# the old repeated S template where the first and third satellites share X.
satellite_shapes = []
for stage in range(stage_count):
    xs = tuple(fields[f"Dish{i}XByStage"][stage] for i in range(3))
    satellite_shapes.append((xs[1] - xs[0], xs[2] - xs[1]))
    if stage and xs[0] == xs[2]:
        raise SystemExit(f"stage {stage + 1} reverted to the repeated S layout")
if len(set(satellite_shapes)) != stage_count:
    raise SystemExit("two Chapter One stages share the same satellite silhouette")

loader = re.search(r"^LoadCurrentStage:(?P<body>.*?)^CheckBeaconRange:", source, re.M | re.S)
if not loader:
    raise SystemExit("cannot isolate generic stage loader")
if "STAGE2_" in loader.group("body"):
    raise SystemExit("generic stage loader still contains Stage-2-specific constants")
for name in (
    "StageSpawnX", "StageSpawnY",
    "StageVelocityXHi", "StageVelocityXLo", "StageVelocityYHi", "StageVelocityYLo",
):
    if name not in loader.group("body"):
        raise SystemExit(f"generic stage loader ignores {name}")
if "sta stageOffset" in loader.group("body"):
    raise SystemExit("generic stage loader stores a stack-vulnerable beacon offset")
if "BeginStage2" in source:
    raise SystemExit("legacy Stage-2-specific transition routine remains")

print(
    "Thursday's Child 0.9B stage verification passed: five ordered descriptors, "
    "generic advancement/loading, complete spawn/velocity/object metadata, "
    "centered beacon triplets, distinct terrain/palettes/object layouts, shared "
    "Chapter One music, renderer-matched schedules, and terrain-safe footprints"
)
