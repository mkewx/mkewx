#!/usr/bin/env python3
"""Verify every Chapter One display list and object-positioning invariant."""
from pathlib import Path
import re
import sys

rom = Path(sys.argv[1]).read_bytes()
symbols = Path(sys.argv[2]).read_text()
source = Path(sys.argv[3]).read_text()


def address(name: str) -> int:
    match = re.search(rf"^{re.escape(name)}\s+([0-9a-fA-F]{{4}})\b", symbols, re.M)
    if not match:
        raise SystemExit(f"missing object symbol: {name}")
    return int(match.group(1), 16)


def constant(name: str) -> int:
    # Conditional lab builds can legally assemble different values for the
    # same source-level constant. Trust the assembled symbol table first so
    # this verifier checks the ROM being tested, not the first textual branch.
    assembled = re.search(rf"^{name}\s+([0-9a-fA-F]{{4}})\b", symbols, re.M)
    if assembled:
        return int(assembled.group(1), 16)
    match = re.search(rf"^{name}\s*=\s*(\d+)", source, re.M)
    if not match:
        raise SystemExit(f"missing object constant: {name}")
    return int(match.group(1))


stage_specs = {
    1: ((9, 29, 49, 77, 97, 123, 145, 161), (23, 45, 65, 93, 115, 139, 159)),
    2: ((9, 31, 51, 75, 95, 119, 141, 157), (23, 47, 67, 91, 111, 135, 155)),
    3: ((11, 33, 53, 75, 95, 117, 139, 155), (25, 49, 67, 91, 109, 133, 153)),
    4: ((13, 33, 53, 79, 99, 121, 143, 159), (27, 49, 67, 95, 113, 137, 157)),
    5: ((9, 29, 49, 83, 103, 125, 143, 159), (23, 45, 63, 99, 117, 141, 157)),
}
bank_by_stage = {1: 7, 2: 6, 3: 5, 4: 4, 5: 3}


def bank_bytes(stage: int, label: str, length: int) -> bytes:
    start = bank_by_stage[stage] * 4096 + (address(label) & 0x0FFF)
    return rom[start : start + length]


world_pages = []
for stage, (tops, service_rows) in stage_specs.items():
    prefix = "" if stage == 1 else f"Stage{stage}"
    world = bank_bytes(stage, f"{prefix}WorldGraphics", 176)
    service = bank_bytes(stage, f"{prefix}ServiceCode", 176)
    world_pages.append(world)

    expected_service = {line: code for code, line in enumerate(service_rows, 1)}
    for line, value in enumerate(service):
        if value != expected_service.get(line, 0):
            raise SystemExit(
                f"stage {stage} has service code {value} on room line {line}"
            )

    expected_nonzero = set()
    for index, top in enumerate(tops):
        height = 15 if index in (1, 3, 5) else 14
        expected_nonzero.update(range(top, top + height, 2))
    actual_nonzero = {line for line, value in enumerate(world) if value}
    if actual_nonzero != expected_nonzero:
        raise SystemExit(f"stage {stage} display list has shifted object art")

if len(set(world_pages)) != 5:
    raise SystemExit("Chapter One stages still share an object display page")

for required_text in (
    "jsr CheckCollectibles", "sta collectDraw0", "sta collectDraw1",
    "sta collectDraw2", "sta collectDraw3", "cmp #3", "sta objectiveDone",
    "lda dishColorA", "lda dishColorB", "lda dishColorC",
    "lda requiredP1Color", "lda optionalP1Color", "sta dishColorA,x",
    "lda exitDraw", "lda exitP1Color", "sta stageComplete",
    "lda currentP1Color", "lda OptionalXByStage,x",
    "sta optionalXAdjusted", "sta optionalFineMotion",
):
    if required_text not in source:
        raise SystemExit(f"missing objective-state operation: {required_text}")

positioner = re.search(
    r"lda\s+optionalXAdjusted\s+sec\s+\.gameP1Divide15:\s+"
    r"sbc\s+#15\s+bcs\s+\.gameP1Divide15\s+sta\s+RESP1\s+"
    r"lda\s+optionalFineMotion\s+sta\s+HMP1",
    source,
    re.S,
)
if not positioner:
    raise SystemExit("generic upper-object positioning sequence changed")
if re.search(r"sta\s+WSYNC\s+sta\s+HMOVE\s+sta\s+HMCLR", source):
    raise SystemExit("HMCLR cancels active gameplay fine motion immediately after HMOVE")


def rendered_player_x(declared_x: int) -> int:
    adjusted = declared_x + constant("POSITION_BIAS")
    divides = adjusted // 15 + 1
    remainder = (adjusted - 15 * divides) & 0xFF
    resp_cycle = 5 * divides + 2
    coarse_x = 3 * resp_cycle - 63
    fine_nibble = (((remainder ^ 0xFF) + 0xF9) & 0xFF) & 0x0F
    fine_motion = -fine_nibble if fine_nibble < 8 else 16 - fine_nibble
    return coarse_x + fine_motion


for declared_x in range(constant("RIGHT_LIMIT") + 1):
    actual_x = rendered_player_x(declared_x)
    if actual_x != declared_x:
        raise SystemExit(
            f"P0 coordinate conversion drifts at X={declared_x}: renders at {actual_x}"
        )

# P1 starts its divide five CPU cycles later than P0 because it loads its
# adjusted coordinate from RAM and executes SEC on the new scanline. Its bias
# must compensate by fifteen color clocks, and its own timing formula—not
# P0's—must reproduce every authored logical/collision coordinate.
if constant("P1_POSITION_BIAS") != constant("POSITION_BIAS") - 15:
    raise SystemExit("P1 bias does not compensate for its five-cycle setup")


def rendered_optional_x(declared_x: int) -> int:
    adjusted = declared_x + constant("P1_POSITION_BIAS")
    divides = adjusted // 15 + 1
    remainder = (adjusted - 15 * divides) & 0xFF
    resp_cycle = 5 * divides + 7
    coarse_x = 3 * resp_cycle - 63
    fine_nibble = (((remainder ^ 0xFF) + 0xF9) & 0xFF) & 0x0F
    fine_motion = -fine_nibble if fine_nibble < 8 else 16 - fine_nibble
    return coarse_x + fine_motion


optional_names = (
    "OPTIONAL_LEFT", "STAGE2_OPTIONAL_LEFT", "STAGE3_OPTIONAL_LEFT",
    "STAGE4_OPTIONAL_LEFT", "STAGE5_OPTIONAL_LEFT",
)
for name in (
    *optional_names,
):
    declared_x = constant(name)
    actual_x = rendered_optional_x(declared_x)
    if actual_x != declared_x:
        raise SystemExit(
            f"{name}={declared_x} renders at {actual_x}; collision would disagree"
        )


def bank7_bytes(name: str, length: int) -> bytes:
    start = 7 * 4096 + (address(name) & 0x0FFF)
    return rom[start : start + length]


declared_optional = [constant(name) for name in optional_names]
expected_adjusted = bytes(
    value + constant("P1_POSITION_BIAS") for value in declared_optional
)
expected_fine = []
for adjusted in expected_adjusted:
    divides = adjusted // 15 + 1
    remainder = (adjusted - 15 * divides) & 0xFF
    fine_nibble = (((remainder ^ 0xFF) + 0xF9) & 0xFF) & 0x0F
    expected_fine.append(fine_nibble << 4)
if bank7_bytes("GameplayOptionalAdjusted", 5) != expected_adjusted:
    raise SystemExit("Bank 7 optional adjusted-X refresh table is stale")
if bank7_bytes("GameplayOptionalFine", 5) != bytes(expected_fine):
    raise SystemExit("Bank 7 optional fine-motion refresh table is stale")
refresh = re.search(
    r"jsr\s+PrepareTomFineMotion.*?jsr\s+RefreshOptionalPosition",
    source,
    re.S,
)
if not refresh:
    raise SystemExit("optional P1 coordinates are not refreshed after physics")
refresh_body = re.search(
    r"RefreshOptionalPosition:\s+ldx\s+currentStage.*?"
    r"lda\s+GameplayOptionalAdjusted,x.*?sta\s+optionalXAdjusted\s+"
    r".*?lda\s+GameplayOptionalFine,x.*?sta\s+optionalFineMotion\s+rts",
    source,
    re.S,
)
if not refresh_body:
    raise SystemExit("optional P1 refresh routine changed")

for stage in range(1, 6):
    suffix = "" if stage == 1 else f"STAGE{stage}_"
    for beacon, dish in (("BEACON_AX", "DISH_A_LEFT"),
                         ("BEACON_BX", "DISH_B_LEFT"),
                         ("BEACON_CX", "DISH_C_LEFT")):
        if constant(suffix + beacon) != constant(suffix + dish) + 4:
            raise SystemExit(f"stage {stage} {beacon} is not centered")

print(
    "Thursday's Child object verification passed: five unique display lists, "
    "five exact service schedules, exact optional-salvage P1 coordinates, "
    "centered satellite beacons, and drift-free Major Tom coordinates"
)
