#!/usr/bin/env python3
"""Verify the 32 KiB F4 shell and its per-bank reset landing pads."""
from pathlib import Path
import sys

rom = Path(sys.argv[1]).read_bytes()
if len(rom) != 32768:
    raise SystemExit(f"expected 32768-byte F4 ROM, got {len(rom)}")

landing = bytes((0xAD, 0xFB, 0xFF, 0x4C, 0x06, 0xF0))
vectors = bytes((0x00, 0xF0, 0x00, 0xF0, 0x00, 0xF0))
for bank in range(8):
    base = bank * 4096
    if rom[base:base + 6] != landing:
        raise SystemExit(f"bank {bank} has an invalid F4 reset landing pad")
    if rom[base + 0xFFA:base + 0x1000] != vectors:
        raise SystemExit(f"bank {bank} has invalid reset vectors")

if rom.count(0xFF) == len(rom):
    raise SystemExit("ROM appears empty")

print("F4 ROM verification passed: 32768 bytes, eight reset-safe banks")
