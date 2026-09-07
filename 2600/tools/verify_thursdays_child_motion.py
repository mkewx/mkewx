#!/usr/bin/env python3
"""Verify the interpolated 60 Hz wide-orbit path has no held frames."""
from pathlib import Path
import math
import re
import sys

text = Path(sys.argv[1]).read_text()


def constant(name: str) -> int:
    match = re.search(rf"^{name}\s*=\s*(\d+)", text, re.M)
    if not match:
        raise SystemExit(f"missing motion constant: {name}")
    return int(match.group(1))


def table(name: str, next_name: str) -> list[int]:
    match = re.search(rf"^{name}:$(.*?)^{next_name}:$", text, re.M | re.S)
    if not match:
        raise SystemExit(f"missing orbit table: {name}")
    values: list[int] = []
    for line in match.group(1).splitlines():
        line = line.split(";", 1)[0].strip()
        if not line.startswith("byte "):
            continue
        values.extend(int(token.strip()) for token in line[5:].split(","))
    if len(values) != 64:
        raise SystemExit(f"{name} contains {len(values)} values, expected 64")
    return values


x_near = table("OrbitXNear", "OrbitYNear")
y_near = table("OrbitYNear", "OrbitXMid")
x_mid = table("OrbitXMid", "OrbitYMid")
y_mid = table("OrbitYMid", "OrbitXFar")
x_values = table("OrbitXFar", "OrbitYFar")
y_match = re.search(r"^OrbitYFar:$(.*?)(?:^\s*$){2}", text, re.M | re.S)
if not y_match:
    raise SystemExit("missing orbit table: OrbitYFar")
y_values: list[int] = []
for line in y_match.group(1).splitlines():
    line = line.split(";", 1)[0].strip()
    if line.startswith("byte "):
        y_values.extend(int(token.strip()) for token in line[5:].split(","))
if len(y_values) != 64:
    raise SystemExit(f"OrbitYFar contains {len(y_values)} values, expected 64")

near_positions = [(x_near[index], y_near[index]) for index in range(0, 64, 2)]
mid_positions = list(zip(x_mid, y_mid))
for tier, tier_positions in (("tight", near_positions), ("medium", mid_positions)):
    if any(
        position == tier_positions[(index + 1) % len(tier_positions)]
        for index, position in enumerate(tier_positions)
    ):
        raise SystemExit(f"{tier} orbit contains a held frame")

positions: list[tuple[int, int]] = []
for index in range(64):
    current = (x_values[index], y_values[index])
    following = (x_values[(index + 1) & 63], y_values[(index + 1) & 63])
    midpoint = (
        (current[0] + following[0]) // 2,
        (current[1] + following[1]) // 2,
    )
    positions.append(current)
    if midpoint not in (current, following):
        positions.append(midpoint)

steps = [
    (
        positions[(index + 1) % len(positions)][0] - position[0],
        positions[(index + 1) % len(positions)][1] - position[1],
    )
    for index, position in enumerate(positions)
]
if any(step == (0, 0) for step in steps):
    raise SystemExit("wide orbit still contains a held frame")
if max(max(abs(dx), abs(dy)) for dx, dy in steps) > 2:
    raise SystemExit("wide orbit contains a jump larger than two clocks")
if "jsr CalculateOrbitFarHalf" not in text or "bcs .advanceOrbit" not in text:
    raise SystemExit("wide-orbit interpolation is not connected to UpdateOrbit")

# Terrain is authoritative during free flight, but authored satellite rings are
# protected corridors. A runtime terrain rollback here can reverse on both
# sides of an entry point and pin Major Tom beside a satellite forever.
begin_capture = re.search(r"^BeginCapture:$(.*?)^SelectClosestOrbitAngle:$", text, re.M | re.S)
update_orbit = re.search(r"^UpdateOrbit:$(.*?)^PlaceOrbitAtCurrentAngle:$", text, re.M | re.S)
if not begin_capture or not update_orbit:
    raise SystemExit("missing capture/orbit routines")
for label, block in (("BeginCapture", begin_capture.group(1)),
                     ("UpdateOrbit", update_orbit.group(1))):
    if "CheckTerrainSoftware" in block or "RestoreSafePosition" in block:
        raise SystemExit(f"{label} improperly routes a protected orbit through terrain rollback")

# The 2600 stack mirrors upper RIOT RAM. A persistent stageOffset byte in that
# region was overwritten by nested JSRs, silently selecting Chapter 1 beacon
# coordinates in later zones. Beacon indexing must be derived from currentStage
# at each use instead of trusting stored upper RAM.
beacon_range = re.search(r"^CheckBeaconRange:$(.*?)^MeasureBeaconDistance:$", text, re.M | re.S)
if not beacon_range:
    raise SystemExit("missing CheckBeaconRange routine")
if "stageOffset" in beacon_range.group(1):
    raise SystemExit("CheckBeaconRange still trusts stack-mirrored stageOffset RAM")
if beacon_range.group(1).count("adc currentStage") < 3:
    raise SystemExit("CheckBeaconRange does not derive all three table indices from currentStage")

# Mirror MeasureBeaconDistance's strict axis and Manhattan comparisons. The
# capture field may include a tiny input tolerance, but it must no longer reach
# materially beyond the visible radius-19 wide orbit. Every tier also needs at
# least one valid distance after tightening the outer boundary.
capture_range = constant("CAPTURE_RANGE")
near_max = constant("TIER_NEAR_MAX")
mid_max = constant("TIER_MID_MAX")
accepted = [
    (dx, dy)
    for dx in range(capture_range)
    for dy in range(capture_range)
    if dx + dy < capture_range + 10
]
outer_distance = max(math.hypot(dx, dy) for dx, dy in accepted)
if outer_distance > 22:
    raise SystemExit(
        f"capture field extends {outer_distance:.2f} pixels from a radius-19 orbit"
    )
max_manhattan = max(dx + dy for dx, dy in accepted)
if not (0 < near_max < mid_max <= max_manhattan):
    raise SystemExit("tightened capture field does not retain all three tiers")

print(
    "Thursday's Child motion verification passed: "
    f"{len(near_positions)}/{len(mid_positions)}/{len(positions)} moving frames "
    f"per tight/medium/wide revolution, no held frames; capture edge "
    f"{outer_distance:.2f}px"
)
