#!/usr/bin/env python3
"""Verify Thursday's Child 0.7B bank layout and approved Stage 1 data."""

from pathlib import Path
import re
import sys


if len(sys.argv) != 4:
    raise SystemExit("usage: verify_f4_thursdays_child_07b.py ROM SYM APPROVED_07A")

rom = Path(sys.argv[1]).read_bytes()
symbols = Path(sys.argv[2]).read_text()
approved = Path(sys.argv[3]).read_bytes()
if len(rom) != 32768 or len(approved) != 32768:
    raise SystemExit("0.7B and its approved 0.7A fallback must both be 32K F4 ROMs")


def symbol(name: str) -> int:
    match = re.search(rf"^{re.escape(name)}\s+([0-9a-fA-F]{{4}})\b", symbols, re.M)
    if not match:
        raise SystemExit(f"missing 0.7B symbol: {name}")
    return int(match.group(1), 16)


landing = bytes((0xAD, 0xFB, 0xFF, 0x4C, 0x06, 0xF0))
vectors = bytes((0x00, 0xF0, 0x00, 0xF0, 0x00, 0xF0))
for bank in range(8):
    base = bank * 4096
    if rom[base : base + 6] != landing:
        raise SystemExit(f"bank {bank} has an invalid reset landing pad")
    if rom[base + 0xFFA : base + 0x1000] != vectors:
        raise SystemExit(f"bank {bank} has invalid reset vectors")

# Banks 1-2 remain pristine chapter capacity. Banks 3-6 own Stages 5-2.
for bank in range(1, 3):
    body = rom[bank * 4096 + 6 : bank * 4096 + 0xFFA]
    if any(value != 0xFF for value in body):
        raise SystemExit(f"reserved future-content bank {bank} is not empty")
for bank, stage in ((6, 2), (5, 3), (4, 4), (3, 5)):
    if all(value == 0xFF for value in rom[bank * 4096 + 6 : (bank + 1) * 4096 - 6]):
        raise SystemExit(f"Stage {stage} display bank is empty")

# F4 gates switch only outside visible scanlines and land at explicit JMPs.
checks = {
    7 * 4096 + 0xBD0: bytes((0xAD, 0xF7, 0xFF)),
    3 * 4096 + 0xBD3: bytes((0x4C, 0x00, 0xF1)),
    3 * 4096 + 0xBD8: bytes((0xAD, 0xFB, 0xFF)),
    7 * 4096 + 0xBDB: bytes((0x4C, symbol("Frame") & 0xFF, symbol("Frame") >> 8)),
    7 * 4096 + 0xBB0: bytes((0xAD, 0xF8, 0xFF)),
    4 * 4096 + 0xBB3: bytes((0x4C, 0x00, 0xF1)),
    4 * 4096 + 0xBB8: bytes((0xAD, 0xFB, 0xFF)),
    7 * 4096 + 0xBBB: bytes((0x4C, symbol("Frame") & 0xFF, symbol("Frame") >> 8)),
    7 * 4096 + 0xBC0: bytes((0xAD, 0xF9, 0xFF)),
    5 * 4096 + 0xBC3: bytes((0x4C, 0x00, 0xF1)),
    5 * 4096 + 0xBC8: bytes((0xAD, 0xFB, 0xFF)),
    7 * 4096 + 0xBCB: bytes((0x4C, symbol("Frame") & 0xFF, symbol("Frame") >> 8)),
    7 * 4096 + 0xBE0: bytes((0xAD, 0xFA, 0xFF)),
    6 * 4096 + 0xBE3: bytes((0x4C, 0x00, 0xF1)),
    6 * 4096 + 0xBF0: bytes((0xAD, 0xFB, 0xFF)),
    7 * 4096 + 0xBF3: bytes((0x4C, symbol("Frame") & 0xFF, symbol("Frame") >> 8)),
}
for offset, expected in checks.items():
    if rom[offset : offset + len(expected)] != expected:
        raise SystemExit(f"bank gate mismatch at ROM offset ${offset:04X}")

# Stage 1's raster-authored display pages are byte-for-byte the approved 0.7A
# pages. Stage 2 uses the same virtual page contract in Bank 6.
for page in range(0x600, 0xC00, 0x100):
    new_start = 7 * 4096 + page
    old_start = 7 * 4096 + page
    if rom[new_start : new_start + 176] != approved[old_start : old_start + 176]:
        raise SystemExit(f"approved Stage 1 display page F{page >> 8:X}00 drifted")

for stage in (2, 3, 4, 5):
    for suffix, expected in (
        ("RoomStart", 0xF100),
        ("WorldGraphics", 0xF600),
        ("ServiceCode", 0xF700),
        ("TerrainColor", 0xF800),
        ("TerrainLeftPF1", 0xF900),
        ("TerrainRightPF1", 0xFA00),
        ("TerrainPF2", 0xFB00),
    ):
        name = f"Stage{stage}{suffix}"
        if symbol(name) != expected:
            raise SystemExit(f"{name} moved from its fixed virtual address ${expected:04X}")

# SelectPose runs in fixed Bank 7 and stores the canonical SuitUp virtual
# address. Each switched renderer bank must expose the same art at that exact
# address or Major Tom will be read several rows out of phase.
canonical_suit = symbol("SuitUp")
canonical_start = 7 * 4096 + canonical_suit - 0xF000
canonical_art = rom[canonical_start : canonical_start + 42]
for bank, stage in ((6, 2), (5, 3), (4, 4), (3, 5)):
    stage_address = symbol(f"Stage{stage}SuitUp")
    if stage_address != canonical_suit:
        raise SystemExit(
            f"Stage {stage} suit begins at ${stage_address:04X}; "
            f"shared pose pointer requires ${canonical_suit:04X}"
        )
    stage_start = bank * 4096 + stage_address - 0xF000
    if rom[stage_start : stage_start + 42] != canonical_art:
        raise SystemExit(f"Stage {stage} Major Tom art differs from Bank 7")

if symbol("optionalFineMotion") > 0xFF:
    raise SystemExit("0.7B persistent state exceeds the VCS's 128-byte RAM")

print(
    "Thursday's Child 0.7B F4 verification passed: eight reset-safe banks, "
    "two reserved banks, isolated Stage 2-5 renderers, safe gates, approved "
    "Stage 1 display pages, canonical Major Tom art in every stage bank, and "
    "RAM within $80-$FF"
)
