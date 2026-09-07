# Thursday's Child — Chapter One stack-corruption regression record

Status: root-caused and fixed 2026-09-07, verified extensively via emulation.
**Not yet human-playtested** — treat as a strong candidate, not a re-approved
checkpoint, until Jason confirms it in actual play.

## Symptoms

- Playing through the approved Chapter One checkpoint normally — FIRE on
  credits, FIRE on title, FIRE three times on the terminal briefing — never
  reached gameplay. It bounced back to the credits screen instead, every
  time, on every input method and every emulator tried (Stella, JavaTari,
  Stellerator alike).
- The failure looked identical regardless of which key/controller was used
  or how it was pressed, which is what eventually ruled out an input or
  emulator-specific explanation.

## Root cause

`TerminalToGameplayGate`'s third-fire jump (`jmp $FFE0`) fires from inside
`TerminalReadFire`, itself reached via `jsr TerminalReadFire` from
`TerminalFrame`. A `jmp` does not execute the matching `rts`, so the return
address that `jsr` pushed is never popped — it is permanently orphaned on
the 6502 hardware stack. `GameplayResume` never reset the stack pointer
before jumping into `Frame`, so that stale entry rode along into gameplay.

Gameplay ran correctly for a short while, because its own `jsr`/`rts` pairs
stayed balanced above the phantom entry. Once gameplay's own call depth
unwound back down to that exact stack level, an `rts` that should have
returned into gameplay instead popped the stale terminal-era address,
sending execution into unmapped memory. From there the CPU executed ROM
data misread as instructions until it hit a stray zero byte (`BRK`), and
every bank's identical interrupt vector redirects `BRK` back through
`Reset` into credits — deterministically, which is why it was 100%
reproducible regardless of timing or input method.

Confirmed directly, not inferred: built Stella 6.7.1 from source (the exact
version installed and tested against), instrumented the real CPU core to
log program-counter history, and captured the actual `rts` (inside
`RoomDrawTom`, bank 0) popping a corrupted return address that landed the
CPU at `$A417` — well outside any valid ROM address — followed by the
`BRK`-through-`Reset` chain exactly as described above.

## Fix

`GameplayResume` now resets the stack pointer (`ldx #$FF` / `txs`) before
touching anything else — the same defensive reset `Reset` itself performs.
This discards any stale stack entries regardless of their source, rather
than patching the terminal's `jmp` specifically.

## Verification performed

- `verify_thursdays_child_chapter_one.py` passes against the rebuilt ROM.
- Instrumented-Stella replay of the full credits -> title -> terminal (x3
  fire) -> gameplay sequence: reaches `GameplayResume` and runs cleanly for
  ~24 real seconds (1,963+ `CallPhysics` frame cycles) with zero bounces
  back to credits. The bounce-detector added specifically to catch this
  class of failure never fired.
- Visual confirmation: genuine Stage 1 gameplay on screen (three satellite
  dishes, a Junk piece) 20 seconds into the run.

## Still needed before this is approved again

- Jason's own hands-on playtest of the full presentation -> gameplay flow.
- Confirmation that Stages 1-5 all still play/feel as approved (this fix
  only touches the one-time gameplay-entry stack reset, not per-stage
  logic, but only a human playtest can confirm feel).

## Rebuilt ROM

`binaries/approved/thursdays-child-chapter-one.bin` and
`code/approved-checkpoints/chapter-one/thursdays-child-chapter-one.bin`
were both regenerated from the fixed source and are byte-identical to each
other. Direct gameplay SHA-256:
`abe0037043270c307822596045d56ab27671877370b82de1f641c45e3fd902c2`
