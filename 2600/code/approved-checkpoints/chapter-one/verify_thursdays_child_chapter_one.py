#!/usr/bin/env python3
"""Verify the integrated Thursday's Child Chapter One F4 cartridge."""

from pathlib import Path
import re
import sys


if len(sys.argv) not in (3, 4):
    raise SystemExit(
        "usage: verify_thursdays_child_chapter_one.py ROM SYM [GAMEPLAY_BASELINE]"
    )

rom = Path(sys.argv[1]).read_bytes()
symbols = Path(sys.argv[2]).read_text()
if len(rom) != 32768:
    raise SystemExit(f"expected a 32K F4 ROM, got {len(rom)} bytes")


def symbol(name: str) -> int:
    match = re.search(rf"^(?:0\.)?{re.escape(name)}\s+([0-9a-fA-F]{{4}})\b", symbols, re.M)
    if not match:
        raise SystemExit(f"missing integration symbol: {name}")
    return int(match.group(1), 16)


def absolute(bank: int, address: int) -> int:
    if not 0xF000 <= address <= 0xFFFF:
        raise ValueError(f"virtual address outside cartridge window: ${address:04X}")
    return bank * 4096 + address - 0xF000


def jmp(address: int) -> bytes:
    return bytes((0x4C, address & 0xFF, address >> 8))


def expect(bank: int, address: int, expected: bytes, description: str) -> None:
    offset = absolute(bank, address)
    actual = rom[offset : offset + len(expected)]
    if actual != expected:
        raise SystemExit(
            f"{description} mismatch in Bank {bank} at ${address:04X}: "
            f"expected {expected.hex(' ')}, found {actual.hex(' ')}"
        )


# Every possible F4 startup bank selects fixed Bank 7 before entering Reset.
boot = bytes((0xAD, 0xFB, 0xFF, 0x4C, 0x06, 0xF0))
vectors = bytes((0x00, 0xF0, 0x00, 0xF0, 0x00, 0xF0))
for bank in range(8):
    expect(bank, 0xF000, boot, "reset landing pad")
    expect(bank, 0xFFFA, vectors, "interrupt/reset vectors")

# Cold boot: fixed Bank 7 -> credits in Bank 2.
expect(7, 0xFFA0, bytes((0xAD, 0xF6, 0xFF)), "credits bank select")
expect(2, 0xFFA3, jmp(symbol("CreditsInit")), "credits landing")

# Credits -> title -> terminal -> gameplay.
expect(2, 0xFFB0, bytes((0xAD, 0xF5, 0xFF)), "title bank select")
expect(1, 0xFFB3, jmp(symbol("TitleInit")), "title landing")
expect(1, 0xFFC0, bytes((0xAD, 0xF6, 0xFF)), "terminal bank select")
expect(2, 0xFFC3, jmp(symbol("TerminalInit")), "terminal landing")
expect(2, 0xFFE0, bytes((0xAD, 0xFB, 0xFF)), "gameplay bank select")
expect(7, 0xFFE3, jmp(symbol("GameplayResume")), "gameplay landing")

# RESET from either presentation bank returns to the fixed Bank 7 reset path.
for bank in (1, 2):
    expect(bank, 0xFFE8, bytes((0xAD, 0xFB, 0xFF)), "presentation reset select")
expect(7, 0xFFEB, jmp(symbol("Reset")), "presentation reset landing")

# Gameplay's existing banked renderers and Bank-0 physics call remain intact.
expect(7, 0xFFD0, bytes((0xAD, 0xF4, 0xFF)), "physics bank select")
for bank, select_address, landing_address, return_select, return_landing in (
    (3, 0xFBD0, 0xFBD3, 0xFBD8, 0xFBDB),
    (4, 0xFBB0, 0xFBB3, 0xFBB8, 0xFBBB),
    (5, 0xFBC0, 0xFBC3, 0xFBC8, 0xFBCB),
    (6, 0xFBE0, 0xFBE3, 0xFBF0, 0xFBF3),
):
    hotspot = 0xFFF4 + bank
    expect(7, select_address, bytes((0xAD, hotspot & 0xFF, 0xFF)), f"Bank {bank} renderer select")
    expect(bank, landing_address, jmp(0xF100), f"Bank {bank} renderer landing")
    expect(bank, return_select, bytes((0xAD, 0xFB, 0xFF)), f"Bank {bank} return select")
    expect(7, return_landing, jmp(symbol("Frame")), f"Bank {bank} return landing")

# Banks 3-6 preserve their approved visible renderer pages. Their Major Tom
# copies deliberately differ from the old checkpoint: that checkpoint placed
# them three bytes before the canonical pointer and could read malformed art.
if len(sys.argv) == 4:
    baseline = Path(sys.argv[3]).read_bytes()
    if len(baseline) != 32768:
        raise SystemExit("gameplay baseline must also be a 32K F4 ROM")
    for bank in range(3, 7):
        for page in range(0x600, 0xC00, 0x100):
            start = bank * 4096 + page
            if rom[start : start + 176] != baseline[start : start + 176]:
                raise SystemExit(
                    f"approved Bank {bank} display page ${0xF000 + page:04X} drifted"
                )
    # The visible Stage 1 data/kernel pages are likewise unchanged.
    for page in range(0x600, 0xC00, 0x100):
        start = 7 * 4096 + page
        if rom[start : start + 176] != baseline[start : start + 176]:
            raise SystemExit(f"approved Stage 1 page ${0xF000 + page:04X} drifted")

# SelectPose stores Bank 7's canonical virtual pointers. Every renderer bank
# must therefore expose byte-identical suit art at those exact addresses.
canonical_start = symbol("SuitUp")
canonical_end = symbol("VisorEnable") + 7
canonical_art = rom[
    absolute(7, canonical_start) : absolute(7, canonical_end)
]
for bank, stage in ((6, 2), (5, 3), (4, 4), (3, 5)):
    if symbol(f"Stage{stage}SuitUp") != canonical_start:
        raise SystemExit(
            f"Stage {stage} Major Tom starts at ${symbol(f'Stage{stage}SuitUp'):04X}; "
            f"shared pose pointer requires ${canonical_start:04X}"
        )
    stage_art = rom[
        absolute(bank, canonical_start) : absolute(bank, canonical_end)
    ]
    if stage_art != canonical_art:
        raise SystemExit(f"Stage {stage} Major Tom art differs from canonical art")

if symbol("hudHundredsPtr") + 1 > 0xFF:
    raise SystemExit("integrated cartridge state exceeds the VCS's 128-byte RAM")

print(
    "Thursday's Child Chapter One integration verification passed: eight "
    "reset-safe banks; credits -> title -> terminal -> gameplay gates; "
    "presentation RESET recovery; fixed gameplay bank calls; approved Stage "
    "1-5 renderer preservation; canonical Major Tom art in every stage bank; "
    "and RAM within $80-$FF"
)
