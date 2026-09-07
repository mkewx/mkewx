#!/usr/bin/env python3
"""Verify Thursday's Child's bounded four-digit production score."""

from pathlib import Path
import re
import sys


if len(sys.argv) != 4:
    raise SystemExit("usage: verify_thursdays_child_score.py ROM SYM SOURCE")

rom = Path(sys.argv[1]).read_bytes()
symbols_text = Path(sys.argv[2]).read_text()
source_text = Path(sys.argv[3]).read_text()
if len(rom) != 32768:
    raise SystemExit(f"expected a 32K F4 ROM, got {len(rom)} bytes")


def symbol(name: str) -> int:
    match = re.search(
        rf"^(?:0\.)?{re.escape(name)}\s+([0-9a-fA-F]{{4}})\b",
        symbols_text,
        re.M,
    )
    if not match:
        raise SystemExit(f"missing score symbol: {name}")
    return int(match.group(1), 16)


def constant(name: str) -> int:
    match = re.search(rf"^{re.escape(name)}\s*=\s*([^;\s]+)", source_text, re.M)
    if not match:
        raise SystemExit(f"missing score constant: {name}")
    value = match.group(1)
    if value.startswith("$"):
        return int(value[1:], 16)
    return int(value)


JUNK = constant("SCORE_JUNK_TENS")
RELIC = constant("SCORE_RELIC_TENS")
MAXIMUM = (constant("SCORE_MAX_TENS_HI") << 8) | constant("SCORE_MAX_TENS_LO")
CAMPAIGN_ZONES = 42
perfect_score = CAMPAIGN_ZONES * (3 * JUNK + RELIC) * 10
if (JUNK, RELIC, MAXIMUM, perfect_score) != (4, 10, 999, 9240):
    raise SystemExit(
        "production score contract drifted: "
        f"junk={JUNK * 10}, relic={RELIC * 10}, cap={MAXIMUM * 10}, "
        f"perfect={perfect_score}"
    )
if source_text.count("lda #SCORE_JUNK_TENS") != 3:
    raise SystemExit("each of the three Space Junk paths must award 40 points")
if source_text.count("lda #SCORE_RELIC_TENS") != 1:
    raise SystemExit("the Space Relic path must award 100 points exactly once")


class Tiny6502:
    """Small executable verifier for only the instructions used by score code."""

    def __init__(self, bank: int, pc: int):
        self.mem = bytearray(65536)
        self.mem[0xF000:0x10000] = rom[bank * 4096:(bank + 1) * 4096]
        self.pc = pc
        self.a = self.x = self.y = 0
        self.c = self.z = self.n = 0
        self.calls: list[int] = []

    def flags(self, value: int) -> None:
        value &= 0xFF
        self.z = int(value == 0)
        self.n = (value >> 7) & 1

    def byte(self) -> int:
        value = self.mem[self.pc]
        self.pc = (self.pc + 1) & 0xFFFF
        return value

    def word(self) -> int:
        return self.byte() | (self.byte() << 8)

    def branch(self, take: bool) -> None:
        offset = self.byte()
        if take:
            if offset & 0x80:
                offset -= 256
            self.pc = (self.pc + offset) & 0xFFFF

    def run(self) -> None:
        for _ in range(10000):
            op = self.byte()
            if op == 0x18:  # CLC
                self.c = 0
            elif op == 0x38:  # SEC
                self.c = 1
            elif op == 0x60:  # RTS
                if not self.calls:
                    return
                self.pc = self.calls.pop()
            elif op == 0x20:  # JSR abs
                target = self.word()
                self.calls.append(self.pc)
                self.pc = target
            elif op == 0xA9:  # LDA #imm
                self.a = self.byte(); self.flags(self.a)
            elif op == 0xA5:  # LDA zp
                self.a = self.mem[self.byte()]; self.flags(self.a)
            elif op == 0xB1:  # LDA (zp),Y
                zp = self.byte()
                base = self.mem[zp] | (self.mem[(zp + 1) & 0xFF] << 8)
                self.a = self.mem[(base + self.y) & 0xFFFF]; self.flags(self.a)
            elif op == 0xBD:  # LDA abs,X
                self.a = self.mem[(self.word() + self.x) & 0xFFFF]; self.flags(self.a)
            elif op == 0x85:  # STA zp
                self.mem[self.byte()] = self.a
            elif op == 0x95:  # STA zp,X
                self.mem[(self.byte() + self.x) & 0xFF] = self.a
            elif op == 0x99:  # STA abs,Y
                self.mem[(self.word() + self.y) & 0xFFFF] = self.a
            elif op == 0xA2:  # LDX #imm
                self.x = self.byte(); self.flags(self.x)
            elif op == 0xA6:  # LDX zp
                self.x = self.mem[self.byte()]; self.flags(self.x)
            elif op == 0xA0:  # LDY #imm
                self.y = self.byte(); self.flags(self.y)
            elif op == 0x69:  # ADC #imm
                total = self.a + self.byte() + self.c
                self.c = int(total > 0xFF); self.a = total & 0xFF; self.flags(self.a)
            elif op == 0x65:  # ADC zp
                total = self.a + self.mem[self.byte()] + self.c
                self.c = int(total > 0xFF); self.a = total & 0xFF; self.flags(self.a)
            elif op == 0xE9:  # SBC #imm
                total = self.a - self.byte() - (1 - self.c)
                self.c = int(total >= 0); self.a = total & 0xFF; self.flags(self.a)
            elif op == 0xC9:  # CMP #imm
                value = self.byte()
                self.c = int(self.a >= value); self.flags((self.a - value) & 0xFF)
            elif op == 0xE0:  # CPX #imm
                value = self.byte()
                self.c = int(self.x >= value); self.flags((self.x - value) & 0xFF)
            elif op == 0xE8:  # INX
                self.x = (self.x + 1) & 0xFF; self.flags(self.x)
            elif op == 0xCA:  # DEX
                self.x = (self.x - 1) & 0xFF; self.flags(self.x)
            elif op == 0x88:  # DEY
                self.y = (self.y - 1) & 0xFF; self.flags(self.y)
            elif op == 0x90:  # BCC
                self.branch(not self.c)
            elif op == 0xD0:  # BNE
                self.branch(not self.z)
            elif op == 0xF0:  # BEQ
                self.branch(bool(self.z))
            elif op == 0x10:  # BPL
                self.branch(not self.n)
            else:
                raise SystemExit(f"unsupported score-verifier opcode ${op:02X}")
        raise SystemExit("score routine did not return")


score_lo = symbol("scoreTens")
score_hi = symbol("scoreTensHi")


def assembled_add(start: int, award: int) -> int:
    cpu = Tiny6502(0, symbol("AddScoreTens"))
    cpu.mem[score_lo] = start & 0xFF
    cpu.mem[score_hi] = start >> 8
    cpu.a = award
    cpu.run()
    return cpu.mem[score_lo] | (cpu.mem[score_hi] << 8)


for start, award, expected in (
    (0, JUNK, 4), (4, RELIC, 14), (252, JUNK, 256),
    (255, RELIC, 265), (920, JUNK, 924), (990, RELIC, 999), (999, JUNK, 999),
):
    actual = assembled_add(start, award)
    if actual != expected:
        raise SystemExit(
            f"assembled score addition failed: {start}+{award}={actual}, expected {expected}"
        )


digit_table = symbol("HudScoreDigitLow")
digit_addresses = [symbol(f"HudDigit{digit}") for digit in range(10)]
bank7 = 7
bank7_image = rom[bank7 * 4096:(bank7 + 1) * 4096]


def rom7(address: int, length: int) -> bytes:
    return bank7_image[address - 0xF000:address - 0xF000 + length]


table_values = list(rom7(digit_table, 10))
if table_values != [address & 0xFF for address in digit_addresses]:
    raise SystemExit("HUD score digit pointer table is not contiguous 0 through 9")

for units in (0, 4, 10, 22, 99, 100, 110, 255, 256, 924, 999):
    cpu = Tiny6502(bank7, symbol("UpdateHudPointers"))
    cpu.mem[symbol("currentStage")] = 0
    cpu.mem[score_lo] = units & 0xFF
    cpu.mem[score_hi] = units >> 8
    cpu.run()
    expected_digits = (units // 100, (units // 10) % 10, units % 10)
    pointers = (
        cpu.mem[symbol("hudStagePtr")] | (cpu.mem[symbol("hudStagePtr") + 1] << 8),
        cpu.mem[symbol("hudHundredsPtr")] | (cpu.mem[symbol("hudHundredsPtr") + 1] << 8),
        cpu.mem[symbol("hudScorePtr")] | (cpu.mem[symbol("hudScorePtr") + 1] << 8),
    )
    expected_pointers = tuple(digit_addresses[digit] for digit in expected_digits)
    if pointers != expected_pointers:
        raise SystemExit(
            f"HUD conversion failed for {units * 10:04}: {pointers} != {expected_pointers}"
        )
    hundreds = bytes(
        cpu.mem[symbol("hudHundredsGlyph") + row] for row in range(8)
    )
    if hundreds != rom7(digit_addresses[expected_digits[1]], 8):
        raise SystemExit(f"HUD hundreds glyph copy failed for {units * 10:04}")

# InitHudBuffers runs on every zone transition. Its unused icon row must remain
# true score storage rather than being cleared during that setup pass.
cpu = Tiny6502(bank7, symbol("InitHudBuffers"))
cpu.mem[symbol("currentStage")] = 0
cpu.mem[score_lo] = 924 & 0xFF
cpu.mem[score_hi] = 924 >> 8
cpu.run()
if (cpu.mem[score_lo] | (cpu.mem[score_hi] << 8)) != 924:
    raise SystemExit("zone HUD initialization destroyed the persistent score high byte")


def trace_numeric_scanline() -> int:
    """Cycle the assembled HUD loop between two consecutive WSYNC writes."""
    cpu = Tiny6502(bank7, symbol("0.numericRow"))
    cpu.mem[symbol("temp")] = 7
    for pointer_name in ("hudStagePtr", "hudScorePtr"):
        pointer = symbol(pointer_name)
        cpu.mem[pointer] = digit_addresses[9] & 0xFF
        cpu.mem[pointer + 1] = digit_addresses[9] >> 8
    cycles = 0
    saw_wsync = False
    for _ in range(100):
        old_pc = cpu.pc
        op = cpu.byte()
        if op == 0xA4:  # LDY zp
            cpu.y = cpu.mem[cpu.byte()]; cpu.flags(cpu.y); cycles += 3
        elif op == 0xB9:  # LDA abs,Y
            base = cpu.word(); cpu.a = cpu.mem[(base + cpu.y) & 0xFFFF]
            cpu.flags(cpu.a); cycles += 4 + int((base & 0xFF) + cpu.y > 0xFF)
        elif op == 0xB1:  # LDA (zp),Y
            zp = cpu.byte(); base = cpu.mem[zp] | (cpu.mem[(zp + 1) & 0xFF] << 8)
            cpu.a = cpu.mem[(base + cpu.y) & 0xFFFF]
            cpu.flags(cpu.a); cycles += 5 + int((base & 0xFF) + cpu.y > 0xFF)
        elif op == 0x85:  # STA zp
            address = cpu.byte(); cpu.mem[address] = cpu.a; cycles += 3
            if address == 0x02:
                if saw_wsync:
                    return cycles
                saw_wsync = True
                cycles = 0
        elif op == 0xAA:  # TAX
            cpu.x = cpu.a; cpu.flags(cpu.x); cycles += 2
        elif op == 0xDD:  # CMP abs,X
            base = cpu.word(); value = cpu.mem[(base + cpu.x) & 0xFFFF]
            cpu.c = int(cpu.a >= value); cpu.flags((cpu.a - value) & 0xFF)
            cycles += 4 + int((base & 0xFF) + cpu.x > 0xFF)
        elif op == 0x84:  # STY zp
            cpu.mem[cpu.byte()] = cpu.y; cycles += 3
        elif op == 0x86:  # STX zp
            cpu.mem[cpu.byte()] = cpu.x; cycles += 3
        elif op == 0xC6:  # DEC zp
            address = cpu.byte(); cpu.mem[address] = (cpu.mem[address] - 1) & 0xFF
            cpu.flags(cpu.mem[address]); cycles += 5
        elif op == 0xD0:  # BNE
            offset = cpu.byte(); cycles += 2
            if not cpu.z:
                if offset & 0x80:
                    offset -= 256
                target = (cpu.pc + offset) & 0xFFFF
                cycles += 1 + int((cpu.pc & 0xFF00) != (target & 0xFF00))
                cpu.pc = target
        else:
            raise SystemExit(
                f"unsupported HUD-cycle opcode ${op:02X} at ${old_pc:04X}"
            )
    raise SystemExit("HUD numeric loop did not reach two WSYNC writes")


hud_cycles = trace_numeric_scanline()
if hud_cycles > 76:
    raise SystemExit(f"four-digit HUD numeric row overruns at cycle {hud_cycles}")

print(
    "Thursday's Child score verification passed: 40-point Space Junk, "
    "100-point Space Relic, 9240 perfect campaign, assembled 9990 saturation, "
    f"four correct HUD digits, {hud_cycles}-cycle numeric rows, and score "
    "persistence across zone HUD setup"
)
