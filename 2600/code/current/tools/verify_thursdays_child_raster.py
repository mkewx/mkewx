#!/usr/bin/env python3
"""Cycle-trace Thursday's Child's visible kernel from the assembled ROM."""

from pathlib import Path
import re
import sys

rom = Path(sys.argv[1]).read_bytes()
sym_text = Path(sys.argv[2]).read_text()
starfield_lab = bool(re.search(r"^STARFIELD_LAB\s+0001\b", sym_text, re.M))
stage_arg = sys.argv[3] if len(sys.argv) > 3 else "stage1"
chapter2_zone1 = stage_arg == "chapter2-zone1"
chapter2_zone2 = stage_arg == "chapter2-zone2"
chapter2_zone3 = stage_arg == "chapter2-zone3"
stage_number = (1 if chapter2_zone1 else 2 if chapter2_zone2 else 3
                if chapter2_zone3 else int(stage_arg.removeprefix("stage")))
if stage_number not in (1, 2, 3, 4, 5):
    raise SystemExit(f"unsupported room selection: {stage_arg}")
if len(rom) not in (8192, 32768):
    raise SystemExit(f"expected an 8K F8 or 32K F4 ROM, got {len(rom)} bytes")


def symbol(name: str) -> int:
    match = re.search(
        rf"^(?:0\.)?{re.escape(name)}\s+([0-9a-fA-F]{{4}})\b", sym_text, re.M
    )
    if not match:
        raise SystemExit(f"missing timing symbol: {name}")
    return int(match.group(1), 16)


memory = bytearray(65536)
engine_bank = 1 if len(rom) == 8192 else {1: 7, 2: 6, 3: 5, 4: 4, 5: 3}[stage_number]
engine_base = engine_bank * 4096
memory[0xF000:0x10000] = rom[engine_base : engine_base + 4096]

TIA_NAMES = {
    0x02: "WSYNC",
    0x06: "COLUP0",
    0x07: "COLUP1",
    0x08: "COLUPF",
    0x0E: "PF1",
    0x0F: "PF2",
    0x11: "RESP1",
    0x1C: "GRP1",
    0x1D: "ENAM0",
    0x1E: "ENAM1",
}


class Trace6502:
    def __init__(self, pc: int, x: int):
        self.pc = pc
        self.a = 0
        self.x = x
        self.y = 0
        self.c = 0
        self.z = 0
        self.n = 0
        self.cycles = 0
        self.events = []
        self.mem = bytearray(memory)

    def flags(self, value: int):
        self.z = int((value & 0xFF) == 0)
        self.n = (value >> 7) & 1

    def byte(self):
        value = self.mem[self.pc]
        self.pc = (self.pc + 1) & 0xFFFF
        return value

    def word(self):
        lo = self.byte()
        return lo | (self.byte() << 8)

    def branch(self, take: bool):
        offset = self.byte()
        self.cycles += 2
        if not take:
            return
        old = self.pc
        if offset & 0x80:
            offset -= 256
        self.pc = (self.pc + offset) & 0xFFFF
        self.cycles += 1 + int((old & 0xFF00) != (self.pc & 0xFF00))

    def store(self, address: int, value: int, pc: int):
        self.mem[address] = value & 0xFF
        if address in TIA_NAMES:
            self.events.append((TIA_NAMES[address], self.cycles, pc))

    def run_to_wsync(self):
        for _ in range(300):
            pc = self.pc
            op = self.byte()
            if op == 0xA9:  # LDA #imm
                self.a = self.byte(); self.flags(self.a); self.cycles += 2
            elif op == 0xA5:  # LDA zp
                self.a = self.mem[self.byte()]; self.flags(self.a); self.cycles += 3
            elif op == 0xB5:  # LDA zp,Y
                address = (self.byte() + self.y) & 0xFF
                self.a = self.mem[address]; self.flags(self.a); self.cycles += 4
            elif op == 0xBD:  # LDA abs,X
                base = self.word(); address = (base + self.x) & 0xFFFF
                self.a = self.mem[address]; self.flags(self.a)
                self.cycles += 4 + int((base & 0xFF) + self.x > 0xFF)
            elif op == 0xB9:  # LDA abs,Y
                base = self.word(); address = (base + self.y) & 0xFFFF
                self.a = self.mem[address]; self.flags(self.a)
                self.cycles += 4 + int((base & 0xFF) + self.y > 0xFF)
            elif op == 0xB1:  # LDA (zp),Y
                zp = self.byte()
                base = self.mem[zp] | (self.mem[(zp + 1) & 0xFF] << 8)
                address = (base + self.y) & 0xFFFF
                self.a = self.mem[address]; self.flags(self.a)
                self.cycles += 5 + int((base & 0xFF) + self.y > 0xFF)
            elif op == 0xA4:  # LDY zp
                self.y = self.mem[self.byte()]; self.flags(self.y); self.cycles += 3
            elif op == 0xA2:  # LDX #imm
                self.x = self.byte(); self.flags(self.x); self.cycles += 2
            elif op == 0x85:  # STA zp
                address = self.byte(); self.cycles += 3
                self.store(address, self.a, pc)
                if address == 0x02:
                    return
            elif op == 0x8A:  # TXA
                self.a = self.x; self.flags(self.a); self.cycles += 2
            elif op == 0xA8:  # TAY
                self.y = self.a; self.flags(self.y); self.cycles += 2
            elif op == 0xE8:  # INX
                self.x = (self.x + 1) & 0xFF; self.flags(self.x); self.cycles += 2
            elif op == 0xCA:  # DEX
                self.x = (self.x - 1) & 0xFF; self.flags(self.x); self.cycles += 2
            elif op == 0xE0:  # CPX #imm
                value = self.byte(); result = (self.x - value) & 0x1FF
                self.c = int(self.x >= value); self.flags(result & 0xFF); self.cycles += 2
            elif op == 0xE4:  # CPX zp
                value = self.mem[self.byte()]; result = (self.x - value) & 0x1FF
                self.c = int(self.x >= value); self.flags(result & 0xFF); self.cycles += 3
            elif op == 0xC9:  # CMP #imm
                value = self.byte(); result = (self.a - value) & 0x1FF
                self.c = int(self.a >= value); self.flags(result & 0xFF); self.cycles += 2
            elif op == 0x25:  # AND zp
                self.a &= self.mem[self.byte()]; self.flags(self.a); self.cycles += 3
            elif op == 0x45:  # EOR zp
                self.a ^= self.mem[self.byte()]; self.flags(self.a); self.cycles += 3
            elif op == 0x29:  # AND #imm
                self.a &= self.byte(); self.flags(self.a); self.cycles += 2
            elif op == 0x24:  # BIT zp
                value = self.mem[self.byte()]
                self.z = int((self.a & value) == 0)
                self.n = (value >> 7) & 1
                self.cycles += 3
            elif op == 0x39:  # AND abs,Y
                base = self.word(); address = (base + self.y) & 0xFFFF
                self.a &= self.mem[address]; self.flags(self.a)
                self.cycles += 4 + int((base & 0xFF) + self.y > 0xFF)
            elif op == 0x38:  # SEC
                self.c = 1; self.cycles += 2
            elif op == 0x18:  # CLC
                self.c = 0; self.cycles += 2
            elif op == 0x65:  # ADC zp
                value = self.mem[self.byte()]
                total = self.a + value + self.c
                self.c = int(total > 0xFF); self.a = total & 0xFF
                self.flags(self.a); self.cycles += 3
            elif op == 0x69:  # ADC #imm
                value = self.byte()
                total = self.a + value + self.c
                self.c = int(total > 0xFF); self.a = total & 0xFF
                self.flags(self.a); self.cycles += 2
            elif op == 0x86:  # STX zp
                address = self.byte(); self.cycles += 3
                self.store(address, self.x, pc)
            elif op == 0xE5:  # SBC zp
                value = self.mem[self.byte()]
                total = self.a - value - (1 - self.c)
                self.c = int(total >= 0); self.a = total & 0xFF
                self.flags(self.a); self.cycles += 3
            elif op == 0x4A:  # LSR A
                self.c = self.a & 1; self.a >>= 1; self.flags(self.a); self.cycles += 2
            elif op == 0xEA:  # NOP
                self.cycles += 2
            elif op == 0x4C:  # JMP abs
                self.pc = self.word(); self.cycles += 3
            elif op == 0xF0:
                self.branch(bool(self.z))
            elif op == 0xD0:
                self.branch(not self.z)
            elif op == 0x90:
                self.branch(not self.c)
            elif op == 0xB0:
                self.branch(bool(self.c))
            elif op == 0x30:
                self.branch(bool(self.n))
            else:
                raise SystemExit(f"unsupported opcode ${op:02X} at ${pc:04X}")
        raise SystemExit("kernel trace did not reach WSYNC")


def after_first_wsync(label: str) -> int:
    pc = symbol(label)
    for _ in range(40):
        if memory[pc] == 0x85 and memory[pc + 1] == 0x02:
            return pc + 2
        pc += 1
    raise SystemExit(f"could not locate WSYNC at {label}")


def setup_trace(pc: int, x: int) -> Trace6502:
    trace = Trace6502(pc, x)
    trace.mem[symbol("visorEnable")] = 0
    trace.mem[symbol("currentP1Color")] = symbol("OPTIONAL_COLOR") & 0xFF
    trace.mem[symbol("currentP1Mask")] = 0xFF
    for name in ("collectDraw0", "collectDraw1", "collectDraw2", "collectDraw3"):
        trace.mem[symbol(name)] = 0xFF
    trace.mem[symbol("dishColorA")] = symbol("DISH_DIM_COLOR") & 0xFF
    trace.mem[symbol("dishColorB")] = symbol("DISH_DIM_COLOR") & 0xFF
    trace.mem[symbol("dishColorC")] = symbol("DISH_DIM_COLOR") & 0xFF
    trace.mem[symbol("requiredP1Color")] = symbol("REQUIRED_COLOR") & 0xFF
    trace.mem[symbol("optionalP1Color")] = symbol("OPTIONAL_COLOR") & 0xFF
    trace.mem[symbol("exitDraw")] = 0xFF
    trace.mem[symbol("exitP1Color")] = 0x8C
    return trace


prefix = "" if stage_number == 1 else f"Stage{stage_number}"
odd_start = after_first_wsync(f"{prefix}EvenReady" if prefix else "RoomEvenReady")
service_rows = {
    1: [23, 45, 65, 93, 115, 139, 159],
    2: [23, 47, 67, 91, 111, 135, 155],
    3: [25, 49, 67, 91, 109, 133, 153],
    4: [27, 49, 67, 95, 113, 137, 157],
    5: [23, 45, 63, 99, 117, 141, 157],
}[stage_number]
if chapter2_zone3:
    service_rows = [21, 43, 73, 97, 119, 145, 161]
expected_positions = (
    [108, 108, 66, 75, 75, 84, 111]
    if chapter2_zone1
    else [75, 84, 90, 63, 75, 102, 87]
    if chapter2_zone2
    else [75, 81, 117, 102, 75, 81, 99]
    if chapter2_zone3
    else [
        "DISH_A_LEFT", "COLLECT_0_LEFT", "DISH_B_LEFT",
        "COLLECT_1_LEFT", "DISH_C_LEFT", "COLLECT_2_LEFT", "EXIT_LEFT",
    ]
    if stage_number == 1
    else [
        f"STAGE{stage_number}_DISH_A_LEFT", f"STAGE{stage_number}_COLLECT_0_LEFT",
        f"STAGE{stage_number}_DISH_B_LEFT", f"STAGE{stage_number}_COLLECT_1_LEFT",
        f"STAGE{stage_number}_DISH_C_LEFT", f"STAGE{stage_number}_COLLECT_2_LEFT",
        f"STAGE{stage_number}_EXIT_LEFT",
    ]
)

ordinary = setup_trace(odd_start, 0)
ordinary.run_to_wsync()
ordinary_events = {name: cycle for name, cycle, _ in ordinary.events}
ordinary_grp1 = [cycle for name, cycle, _ in ordinary.events if name == "GRP1"]
if ordinary.cycles > 75:
    raise SystemExit(f"ordinary odd line overruns at cycle {ordinary.cycles}")
if ordinary_events.get("COLUP1") != 18 or "ENAM1" in ordinary_events:
    raise SystemExit(f"pre-staged object/color writes drifted: {ordinary.events}")
pf1_cycles = [cycle for name, cycle, _ in ordinary.events if name == "PF1"]
if pf1_cycles[0:1] != [25] or len(pf1_cycles) != 2 or pf1_cycles[1] > 59:
    raise SystemExit(f"ordinary PF1 deadlines drifted: {pf1_cycles}")
if ordinary_grp1 != [12]:
    raise SystemExit(f"ordinary P1/delay-latch write drifted: {ordinary_grp1}")

service_summaries = []
position_errors = []
for row, expected_position in zip(service_rows, expected_positions):
    trace = setup_trace(odd_start, row - 1)
    trace.run_to_wsync()
    if trace.cycles > 75:
        raise SystemExit(f"service row {row} overruns at cycle {trace.cycles}")
    pf1 = [cycle for name, cycle, _ in trace.events if name == "PF1"]
    if len(pf1) != 2 or pf1[0] != 25 or pf1[1] > 59:
        raise SystemExit(f"service row {row} misses PF1 deadline: {pf1}")
    right_table = symbol(f"{prefix}TerrainRightPF1" if prefix else "TerrainRightPF1")
    expected_right_pf1 = memory[right_table + row]
    if trace.mem[0x0E] != expected_right_pf1:
        raise SystemExit(
            f"service row {row} restores PF1=${trace.mem[0x0E]:02X}; "
            f"terrain requires ${expected_right_pf1:02X}"
        )
    resp = [cycle for name, cycle, _ in trace.events if name == "RESP1"]
    if len(resp) != 1:
        raise SystemExit(f"service row {row} has {len(resp)} RESP1 writes")
    grp1 = [cycle for name, cycle, _ in trace.events if name == "GRP1"]
    if grp1 != [12]:
        raise SystemExit(
            f"service row {row} does not pre-stage exactly one blank P1 row"
        )
    visible_x = 3 * resp[0] - 63
    expected_x = (
        expected_position
        if isinstance(expected_position, int)
        else symbol(expected_position)
    )
    if visible_x != expected_x:
        position_errors.append(
            f"{expected_position} expects {expected_x}, assembled RESP1 timing gives {visible_x}"
        )
    service_summaries.append((row, trace.cycles, pf1[1], grp1[0], visible_x))

if position_errors:
    raise SystemExit("; ".join(position_errors))

# The odd kernel intentionally retains PF2 from its preceding even line.
pf2 = symbol(f"{prefix}TerrainPF2" if prefix else "TerrainPF2")
for row in range(1, 176, 2):
    if memory[pf2 + row] != memory[pf2 + row - 1]:
        raise SystemExit(f"TerrainPF2 is not paired at room line {row}")

# Trace the longest astronaut draw route beginning at the instruction after
# the preceding odd line's WSYNC. All odd paths jump through RoomOddNext.
even_start = after_first_wsync(f"{prefix}StarOddControl" if prefix else "StarOddControl")
even = setup_trace(even_start, 1)
even.mem[symbol("renderTomY")] = 2
suit = symbol(f"{prefix}SuitUp" if prefix else "SuitUp")
even.mem[symbol("suitPtr")] = suit & 0xFF
even.mem[symbol("suitPtr") + 1] = suit >> 8
even.run_to_wsync()
if even.cycles > 75:
    raise SystemExit(f"astronaut draw line overruns at cycle {even.cycles}")

# Exercise the separate no-astronaut path on a live star row. Missile 0 must
# be enabled without pushing the kernel past the scanline boundary.
star = setup_trace(even_start, 15)  # OddNext increments into star row 16.
star.mem[symbol("renderTomY")] = 200
star.mem[symbol("visorEnable")] = 0x0E if starfield_lab else 0
star.mem[0x1D] = 2 if starfield_lab else 0  # preceding odd row pre-stages M0
star.run_to_wsync()
if star.cycles > 75:
    raise SystemExit(f"star/no-astronaut line overruns at cycle {star.cycles}")
star_events = [event for event in star.events if event[0] == "ENAM0"]
expected_event_count = 2 if starfield_lab else 2
if len(star_events) != expected_event_count or star.mem[0x1D] != 0:
    raise SystemExit(f"star row does not finish with Missile 0 disabled: {star_events}")
if starfield_lab and star_events[0][1] >= star_events[1][1]:
    raise SystemExit(f"star enable/disable ordering drifted: {star_events}")

star_table = symbol(f"{prefix}StarEnable" if prefix else "StarEnable")
if star_table != 0xFC00:
    raise SystemExit(f"Stage {stage_number} star table moved from $FC00")
expected_stars = {16, 32, 52, 74, 88, 104, 124, 134, 150, 168} if starfield_lab else set()
for row in range(176):
    expected = 2 if row in expected_stars else 0
    if memory[star_table + row] != expected:
        raise SystemExit(f"Stage {stage_number} star data drifted on row {row}")

control_table = symbol(f"{prefix}StarControl" if prefix else "StarControl")
if control_table != 0xFD00:
    raise SystemExit(f"Stage {stage_number} star-control table moved from $FD00")
expected_controls = {}
if chapter2_zone2:
    for row, code in zip(
        (71, 73, 75, 77, 79, 81, 83, 85, 87),
        (8, 2, 4, 6, 7, 5, 3, 1, 0x80),
    ):
        expected_controls[row] = code
elif chapter2_zone3:
    for base in (63, 103):
        for row, code in zip(
            range(base, base + 9),
            (8, 0, 2, 0, 4, 0, 6, 0, 0x80),
        ):
            expected_controls[row] = code
elif starfield_lab:
    for row, code in zip(
        (15, 31, 51, 73, 87, 103, 123, 133, 149, 167),
        (0x10, 0x11, 0x12, 0x13, 0x11, 0x10, 0x13, 0x12, 0x10, 0x12),
    ):
        expected_controls[row] = code
        expected_controls[row + 2] = 0x80
for row in range(176):
    if memory[control_table + row] != expected_controls.get(row, 0):
        raise SystemExit(f"Stage {stage_number} star control drifted on row {row}")

if chapter2_zone2:
    shelf = setup_trace(odd_start, 70)  # INX enters first marker row 71.
    shelf.mem[symbol("stageOffset")] = 3
    shelf.run_to_wsync()
    shelf_boundary = shelf.cycles
    shelf.run_to_wsync()
    shelf_writes = [cycle for name, cycle, _ in shelf.events if name == "COLUPF"]
    shelf_pf1 = [cycle for name, cycle, _ in shelf.events
                 if name == "PF1" and cycle > shelf_boundary]
    flow_table = symbol("Stage2ElasticFlowColors")
    if (shelf_boundary > 75 or shelf.cycles - shelf_boundary > 75
            or len(shelf_writes) != 1 or shelf_writes[0] - shelf_boundary != 3
            or not shelf_pf1 or shelf_pf1[0] - shelf_boundary != 25
            or shelf.mem[0x08] != memory[flow_table + 3]):
        raise SystemExit(
            f"elastic shelf color misses its pre-stage slot: "
            f"{shelf.cycles}c, writes={shelf_writes}, COLUPF=${shelf.mem[0x08]:02X}"
        )
    restore = setup_trace(odd_start, 86)  # INX enters restore row 87.
    restore.run_to_wsync()
    restore_boundary = restore.cycles
    restore.run_to_wsync()
    restore_writes = [cycle for name, cycle, _ in restore.events if name == "COLUPF"]
    if (restore_boundary > 75 or restore.cycles - restore_boundary > 75
            or len(restore_writes) != 1 or restore_writes[0] - restore_boundary != 3
            or restore.mem[0x08] != 0x3A):
        raise SystemExit(
            f"elastic shelf restore misses its pre-stage slot: "
            f"{restore.cycles}c, writes={restore_writes}, COLUPF=${restore.mem[0x08]:02X}"
        )

if chapter2_zone3:
    platform = setup_trace(odd_start, 62)  # INX enters first marker row 63.
    platform.mem[symbol("stageOffset")] = 3
    platform.run_to_wsync()
    platform_boundary = platform.cycles
    platform.run_to_wsync()
    platform_writes = [cycle for name, cycle, _ in platform.events if name == "COLUPF"]
    platform_pf1 = [cycle for name, cycle, _ in platform.events
                    if name == "PF1" and cycle > platform_boundary]
    flow_table = symbol("Stage3ElasticFlowColors")
    if (platform_boundary > 75 or platform.cycles - platform_boundary > 75
            or len(platform_writes) != 1
            or platform_writes[0] - platform_boundary != 3
            or not platform_pf1 or platform_pf1[0] - platform_boundary != 25
            or platform.mem[0x08] != memory[flow_table + 3]):
        raise SystemExit(
            f"Zone 2-3 elastic platform color misses its pre-stage slot: "
            f"{platform.cycles}c, writes={platform_writes}, "
            f"COLUPF=${platform.mem[0x08]:02X}"
        )
    restore = setup_trace(odd_start, 70)  # INX enters restore row 71.
    restore.run_to_wsync()
    restore_boundary = restore.cycles
    restore.run_to_wsync()
    restore_writes = [cycle for name, cycle, _ in restore.events if name == "COLUPF"]
    if (restore_boundary > 75 or restore.cycles - restore_boundary > 75
            or len(restore_writes) != 1
            or restore_writes[0] - restore_boundary != 3
            or restore.mem[0x08] != 0x34):
        raise SystemExit(
            f"Zone 2-3 platform restore misses its pre-stage slot: "
            f"{restore.cycles}c, writes={restore_writes}, "
            f"COLUPF=${restore.mem[0x08]:02X}"
        )

if starfield_lab:
    marker = setup_trace(odd_start, 14)  # INX enters marker row 15.
    marker.mem[symbol("bestBeacon")] = 0
    marker.run_to_wsync()
    marker_pf1 = [cycle for name, cycle, _ in marker.events if name == "PF1"]
    if (
        marker.cycles > 75
        or marker.mem[symbol("visorEnable")] != 0x02
        or marker.mem[0x1D] != 0x02
        or len(marker_pf1) != 2
        or marker_pf1[1] > 59
    ):
        raise SystemExit(
            f"star marker timing/state drifted: {marker.cycles}c, PF1={marker_pf1}"
        )
    restore = setup_trace(odd_start, 16)  # INX enters restore row 17.
    restore.run_to_wsync()
    if restore.cycles > 75 or restore.mem[symbol("visorEnable")] != 0:
        raise SystemExit(
            f"star restore marker overruns or leaves a live phase: {restore.cycles}c"
        )

sprite_prefix = prefix
for name in tuple(
    f"{sprite_prefix}{base}"
    for base in ("SuitUp", "SuitUpRight", "SuitRight", "SuitDownRight", "SuitDown")
):
    start = symbol(name)
    if (start & 0xFF) + 6 > 0xFF:
        raise SystemExit(f"{name} can page-cross during a seven-row read")
for name in (
    (f"{prefix}WorldGraphics", f"{prefix}ServiceCode")
    if prefix else ("WorldGraphics", "ServiceCode")
):
    if symbol(name) & 0xFF:
        raise SystemExit(f"{name} must begin on a page boundary")

summary = ", ".join(
    f"y{row}: {cycles}c/PF1@{right}/GRP1@{grp1}/x{x}"
    for row, cycles, right, grp1, x in service_summaries
)
room_name = (
    "Chapter 2 Zone 1" if chapter2_zone1 else
    "Chapter 2 Zone 2" if chapter2_zone2 else
    "Chapter 2 Zone 3" if chapter2_zone3 else
    f"Stage {stage_number}"
)
print(
    f"Thursday's Child {room_name} raster verification passed: assembled-ROM cycle trace; "
    f"ordinary={ordinary.cycles}c, astronaut={even.cycles}c, star={star.cycles}c; {summary}"
)
