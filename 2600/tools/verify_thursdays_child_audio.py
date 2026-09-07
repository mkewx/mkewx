#!/usr/bin/env python3
"""Verify Thursday's Child 0.8B audio ownership, score, and return gate."""

from pathlib import Path
import re
import sys


if len(sys.argv) != 4:
    raise SystemExit("usage: verify_thursdays_child_audio.py ROM SYM SOURCE")

rom = Path(sys.argv[1]).read_bytes()
symbols = Path(sys.argv[2]).read_text()
source = Path(sys.argv[3]).read_text()

if len(rom) != 32768:
    raise SystemExit("Thursday's Child audio build must remain a 32K F4 ROM")


def symbol(name: str) -> int:
    match = re.search(rf"^{re.escape(name)}\s+([0-9a-fA-F]{{4}})\b", symbols, re.M)
    if not match:
        raise SystemExit(f"missing audio symbol: {name}")
    return int(match.group(1), 16)


for name in (
    "StartSound",
    "UpdateSound",
    "SoundDuration",
    "SoundControl",
    "CompletionFrequency",
    "soundState",
    "UpdateMusic",
    "MusicLeadEnvelope",
    "MusicEchoEnvelope",
    "MusicMonoNotes",
):
    symbol(name)

if symbol("hudHundredsPtr") + 1 > 0xF4:
    raise SystemExit("persistent state invaded the reserved $F5-$FF stack area")
if symbol("soundState") > 0xF4:
    raise SystemExit("packed audio state is unsafe for nested 6502 calls")

# The fixed Bank-7 call gate enters Bank 0 at $FFD3. Bank 0 must perform one
# physics call and switch back at $FFD6 so execution resumes on Bank 7's RTS
# at $FFD9. A second JSR here would silently land beyond that continuation.
bank0_gate = 0x0FD3
expected_gate = bytes((0x20, symbol("UpdatePhysics") & 0xFF,
                       symbol("UpdatePhysics") >> 8, 0xAD, 0xFB, 0xFF))
if rom[bank0_gate : bank0_gate + 6] != expected_gate:
    raise SystemExit("Bank 0 physics/audio return gate moved or gained work")
if rom[7 * 4096 + 0x0FD9] != 0x60:
    raise SystemExit("Bank 7 physics return landing is no longer RTS at $FFD9")

# Audio implementation and all six event triggers belong to Bank 0. That
# ensures no AUD register update can enter either visible room kernel.
for name in ("StartSound", "UpdateSound", "SoundDuration", "SoundControl"):
    address = symbol(name)
    if not 0xF006 <= address < 0xFFD3:
        raise SystemExit(f"{name} escaped the non-visible Bank 0 engine area")

for effect in (
    "SFX_CAPTURE",
    "SFX_RELEASE",
    "SFX_REQUIRED",
    "SFX_OPTIONAL",
    "SFX_EXIT_READY",
    "SFX_STAGE_COMPLETE",
):
    if not re.search(rf"lda\s+#{effect}\s+jsr\s+StartSound", source):
        raise SystemExit(f"missing gameplay trigger for {effect}")

if not re.search(r"jsr\s+CheckMissionContact\s+jsr\s+UpdateSound\s+rts", source):
    raise SystemExit("audio is not updated in the fixed post-gameplay slot")


def byte_table(name: str) -> list[str]:
    match = re.search(
        rf"^{re.escape(name)}:\s*\n(?P<body>(?:\s+byte\s+[^\n]+\n)+)",
        source,
        re.M,
    )
    if not match:
        raise SystemExit(f"missing music table: {name}")
    return [
        token.strip()
        for line in match.group("body").splitlines()
        for token in re.search(r"\bbyte\s+(.+)", line).group(1).split(",")
    ]


music = byte_table("MusicMonoNotes")
if len(music) != 64:
    raise SystemExit("Chapter One monophonic score must have 64 positions")

for phrase in range(8):
    base = phrase * 8
    for rest_step in (2, 5):
        if music[base + rest_step] != "MUSIC_REST":
            raise SystemExit(f"phrase {phrase} lacks silence at step {rest_step}")
    for main_step, ghost_step in ((0, 1), (3, 4), (6, 7)):
        main_note = int(music[base + main_step])
        ghost_note = int(music[base + ghost_step])
        expected = 2 * main_note + 1
        if ghost_note != expected:
            raise SystemExit(
                f"phrase {phrase} ghost {ghost_note} is not octave {expected}"
            )

lead_dividers = [
    int(music[phrase * 8 + step])
    for phrase in range(8)
    for step in (0, 3, 6)
]
if min(lead_dividers) < 6:
    raise SystemExit("Chapter One lead returned to the distorted upper register")

lead_envelope = [int(value) for value in byte_table("MusicLeadEnvelope")]
echo_envelope = [int(value) for value in byte_table("MusicEchoEnvelope")]
if len(lead_envelope) != 32 or max(lead_envelope) > 2:
    raise SystemExit("lead envelope is not the approved quiet 32-frame shape")
if len(echo_envelope) != 32 or max(echo_envelope) > 1:
    raise SystemExit("echo envelope is not the approved volume-one whisper")

for required in (
    "sta AUDV0\n        lda soundState",
    "lda stageComplete\n        beq UpdateMusic",
    "sta frameCounter\n        sta collectMask",
    "and #$E0",
):
    if required not in source:
        raise SystemExit(f"missing music lifecycle operation: {required!r}")

completion = [int(value) for value in byte_table("CompletionFrequency")]
if completion != [23, 23, 19, 15, 11, 15, 19, 23]:
    raise SystemExit("stage completion is not the approved low-register phrase")
if not re.search(
    r"lda\s+CompletionFrequency,x\s+sta\s+AUDF1.*?cmp\s+#5.*?lda\s+#4.*?sta\s+AUDV1\s+rts",
    source,
    re.S,
):
    raise SystemExit("stage completion does not use its dedicated quiet envelope")

music_routine = re.search(
    r"^UpdateMusic:(?P<body>.*?)^SoundDuration:", source, re.M | re.S
)
if not music_routine:
    raise SystemExit("cannot isolate the Chapter One music routine")
if re.search(r"AUD[CFV]1", music_routine.group("body")):
    raise SystemExit("music writes Channel 1 instead of remaining monophonic")
if not re.search(r"sta\s+AUDC1", source) or not re.search(r"sta\s+AUDF1", source):
    raise SystemExit("sound effects are not isolated on Channel 1")

print(
    "Thursday's Child 0.8B audio verification passed: six distinct effects, "
    "64-position monophonic Chapter One score, exact sequential octave ghosts, "
    "authored silence, quiet envelopes, Channel-1 effects, softened lead "
    "register, quiet completion phrase, "
    "completion silence, safe packed state, and $FFD9 return"
)
