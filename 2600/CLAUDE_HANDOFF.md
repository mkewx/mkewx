# Thursday's Child — development handoff

Read this document before changing any source.

## Project and creative intent

**Thursday's Child** is an original Atari 2600/VCS gravity-navigation game,
displayed under the title **FLOATING IN A MOST PECULIAR WAY**. Major Tom moves
continuously; the player does not steer him directly. Ground Control selects
NASA satellites and holds FIRE to capture Major Tom into an orbit, then
releases FIRE to launch him tangentially. Each zone ends after all three pieces
of Space Junk are cleared and the extraction exit is reached. An optional Space
Relic awards points and prestige.

Player-facing terminology is **chapter**, **zone**, **Space Junk**, **Space
Relic**, **satellite**, **NASA**, **Ground Control**, and **Major Tom**. Do not
call zones "stages" in visible text. The story premise is that Ground Control
is directing every movement while Major Tom cleans space cargo; NASA opens the
exit after all Junk is cleared.

The planned campaign is six chapters of five zones: 30 zones total. Each
chapter introduces one movement complication and gradually more involved
topography. Chapter 1 teaches ordinary satellite navigation. Chapter 2 teaches
2x elastic rebound.

## What is proven and should be treated as immutable

The following are user-playtested checkpoints, not suggestions:

1. `binaries/approved/thursdays-child-chapter-one.bin`
   - Credits, title, Chapter 1 terminal sequence, five playable zones,
     post-zone manifest, score, music, effects, gravity and collision.
2. `binaries/approved/thursdays-child-title-proof-1.0.bin`
   - Approved title-screen typography, gradients, Major Tom art and motion.
3. `binaries/approved/thursdays-child-chapter-terminal-1.0-approved.bin`
   - Approved green NASA terminal format and terminal music.
4. `binaries/approved/thursdays-child-zone2-2-mechanics-approved.bin`
   - User-approved Zone 2-2 mechanics checkpoint. This is the most important
     behavioral baseline for Chapter 2.

The corresponding Zone 2-2 source is in
`code/approved-checkpoints/zone-2-2/thursdays-child.asm`. Never replace its
physics, satellite capture, orbit/release, P1 positioning, full-sprite elastic
collision, or renderer timing with experimental code unless a byte-level and
Stella regression proves equivalence.

Chapter 1's approved integration source and its own verification script are in
`code/approved-checkpoints/chapter-one/`.

## Current source versus approved source

`code/current/src/thursdays-child.asm` is the latest development source. It
contains the authored Zone 2-3 data and verification hooks, but its direct
Chapter 2 lab boot presently has a known crash. Do **not** mistake successful
per-bank analysis for a playable ROM.

The current experimental binary is deliberately isolated under
`binaries/experimental/`. It is evidence, not an approved build.

## Newly isolated root cause of the current crash

The Chapter 2 lab Reset code in Bank 7 does this when a lab define is active:

```asm
lda #1                 ; or #2
sta currentStage
jsr LoadCurrentStage
```

`LoadCurrentStage` lives in **Bank 0**, while Reset is executing with **Bank 7**
mapped. A plain JSR does not switch an F4 cartridge bank. The approved Zone 2-2
ROM happened to assemble `LoadCurrentStage` at virtual `$F18F`; jumping to that
address in Bank 7 accidentally traversed survivable Bank 7 bytes. Later Bank 0
growth moved the symbol to `$F1C7`. The same erroneous cross-bank JSR then ran
Bank 7's room-kernel bytes as code and reached `$F1CD`, the operand `$52` of the
valid `BEQ` at `$F1CC`; `$52` is a 6502 JAM/KIL opcode when entered as an opcode.
Stella correctly stopped with **Fatal error: invalid instruction**.

This is why:

- the preserved approved Zone 2-2 ROM still runs;
- newly rebuilt Zone 2-2 and Zone 2-3 stop at `$F1CD`;
- isolated renderer, terrain, orbit and raster tests still pass.

The next repair should introduce an explicit, conventional Bank 7 → Bank 0
stage-load call gate with a matching return landing, or perform equivalent lab
initialization in Bank 7. Do not rely on coincident virtual addresses. Reuse
the project's existing fixed-address bank-gate pattern (for example the room
and physics gates) and verify physical bytes on both sides of the hotspot.

## Safe next task

1. Start from the approved Zone 2-2 source checkpoint.
2. Add a proper banked `LoadCurrentStage` call mechanism without changing
   physics or visible kernels.
3. Build Zone 2-2 and prove it behaves like the approved binary in Stella.
4. Only then port the Zone 2-3 descriptor, terrain tables, service schedule,
   object page, and analyzer from `code/current/`.
5. Run the complete checks once, then conduct one focused Stella playtest.

Avoid rewriting the engine or repeatedly patching symptom locations.

## Known issues — confirmed, deferred by Jason, not urgent

Found during Jason's playtest of the stack-corruption-fixed Chapter One
build on 2026-09-07. Real, confirmed, but explicitly not to be worked on
until asked.

1. **Post-stage manifest screens did not appear** between stages during
   play, even though the approved-checkpoint description says Chapter One
   includes a "post-zone manifest" after every stage. Needs investigation
   into whether this regressed, was never wired into this specific build,
   or is gated behind a condition that didn't trigger.
2. **Score did not accumulate** across stages during play. Needs
   investigation into whether score state is being reset somewhere it
   shouldn't be (a natural place to check first, given the session's other
   finding: `GameplayResume` only clears `scoreTens`, not `scoreOnes`, and
   general RAM-carryover discipline between stages/screens has already
   proven to be a real source of bugs this project).

## Orbit-direction: fixed at the source, 2026-09-07

`BeginCapture`'s `.chooseEntry` direction logic no longer picks
clockwise/counterclockwise from Major Tom's static X position relative to
the beacon. It now uses the sign of the angular-momentum cross product
`L = relX*velY - relY*velX` (relX/relY = Tom's center relative to the
beacon center; velX/velY = his live free-flight velocity at the instant of
capture; screen Y increases downward, so positive L is clockwise here). On
the one degenerate case (`L == 0`, velocity pointing straight at/away from
the beacon), it falls back to the original static rule, since angular
momentum can't pick a side there.

Applied identically, byte-for-byte, to all three places that had their own
copy of this logic: `code/current/src/thursdays-child.asm` (so every future
zone inherits it, including Zone 2-3), `code/approved-checkpoints/chapter-one/thursdays-child-chapter-one.asm`,
and `code/approved-checkpoints/zone-2-2/thursdays-child.asm`. Nothing else
in any of the three files changed.

A signed 8x8->16 multiply (`Multiply8x8Signed`) was added to support this,
reusing the existing `temp`/`temp2`/`delta`/`bestDistance`/`bestBeacon`
scratch bytes rather than growing RAM usage — except for one new byte,
`dirAccumHi`, added at the very end of each file's RAM block (after
`optionalFineMotion`/`hudHundredsPtr`) to avoid disturbing every other
symbol's address. The dev-source audio verifier's stack-safety check
(`hudHundredsPtr` must end at or before $F4) caught a real mistake on the
first attempt — placing new bytes earlier in the block pushed that symbol
past the limit — before it ever reached a build.

Verification: `make verify-thursday` passes 100% clean on the dev source.
Zone 2-2's shared verify-script suite (raster x5, objects, stages, audio,
motion) also passes 100% clean. Chapter One's own dedicated integration
verifier passes; a few of the shared dev-suite scripts report failures
against Chapter One specifically, but those were confirmed, by rebuilding
the untouched original source and running the identical checks, to be
pre-existing mismatches between that integrated file and the newer shared
scripts — not something this change introduced. Real headless Stella runs
confirm no regression: Chapter One played cleanly through credits -> title
-> terminal (3x fire) -> gameplay -> three stage transitions with correct
scoring and zero bounce-backs; Zone 2-2 (built with `-DCHAPTER2_ZONE2_LAB=1`)
showed its actual orange elastic terrain, sustained a capture/orbit cycle
across 20 fire presses, with no crash.

Still to do: a human playtest of the actual gravity-spin *feel* across
diagonal approaches (especially Zone 2-3, the zone that originally
surfaced this as "backwards") — the math is derived and verified, but
only play can confirm it matches Jason's creative intent.

## Zone 2-3 authored design (candidate)

The requested Zone 2-3 design is intentionally more aggressive while retaining
one recoverable cavity:

- three medium center platforms, X=64..95;
- upper elastic platform Y=64..71;
- middle ordinary orange platform Y=80..87;
- lower elastic platform Y=104..111;
- animated rainbow flow on both elastic platforms and the floor;
- three newly arranged satellites at visible upper-center, right-middle and
  lower-center positions;
- no satellite or complete orbit ring intersects terrain;
- Space Junk and Relic are distributed rather than concentrated;
- no initial unattended Junk collection;
- no closed pocket in which Major Tom can become permanently trapped.

The candidate coordinates and generated P1 service page are already in
`code/current/src/thursdays-child.asm` and
`code/current/src/thursdays-child-stage3-zone2-3-objects.inc`.

`tools/analyze_chapter_two_zone3.py` currently verifies:

- renderer geometry equals collision geometry;
- all legal 8x14 astronaut placements form one connected recovery component;
- all 64 near/mid/far points around all three satellites are terrain-clear;
- mission objects do not overlap terrain;
- the opening trajectory does not collect Junk unattended for 1,200 frames.

These are valuable invariants, but the lab boot must be repaired and human
playtesting must still approve the zone.

## Hard technical rules learned during development

- NTSC frame: 3 VSYNC + 37 VBLANK + 192 visible + 30 overscan = 262 lines.
- Visible picture: 16 HUD lines + 176 room lines.
- F4 ROM: 32 KiB, eight 4 KiB banks. Same virtual addresses across banks are
  not the same physical code.
- Preserve the canonical 8x14 Major Tom sprite and approved motion.
- Satellite coordinates are visible art coordinates; beacon coordinates are
  their exact centers. Orbit must use the current zone's beacon-table triplet.
- Never store persistent state in upper RIOT RAM that aliases the 6502 stack.
- The Space Relic/P1 position must be refreshed from immutable data after
  physics; held FIRE must never shift it.
- Drawn terrain and software collision must be generated or audited as the
  same geometry. Decorative, non-colliding terrain is forbidden.
- Test complete sprite rectangles, not only Major Tom's center point.
- An orbit path cannot use free-flight rollback to escape terrain; every
  complete orbit family must be prevalidated as a protected corridor.
- Every legal free-flight region must remain connected to useful satellite
  capture space. No pockets, traps or one-way ledges.
- Required objects must be accessible and must not be collected automatically
  on the initial trajectory.
- Satellite, Junk, Relic and exit placement must vary by zone. Do not regress
  to the old right-side concentration or repeated S-shaped satellite layout.
- Elastic collision doubles the incoming vertical rebound, is capped safely,
  and uses a minimum useful magnitude. Rainbow animation changes color only;
  geometry and collision never move.
- All mid-scanline color/PF/P1 writes are cycle-sensitive. Never insert code
  before a known cycle-73 WSYNC or move work into a visible kernel casually.
- Run Stella after structural banking changes. Static analyzers cannot detect
  a cross-bank JSR unless explicitly taught to do so.

## Build and verification

The assembler is DASM. From `code/current/`, where `Makefile` and `src/` live:

```sh
make verify-thursday
make verify-chapter-two-zone1
make verify-chapter-two-zone2
make verify-chapter-two-zone3
```

The Makefile expects the verification scripts in a sibling `tools/` directory
in the original project layout. In this handoff, copy or symlink the root
`tools/` folder beside `code/current/`, or run from a reconstructed workspace.
Do not declare success from assembly alone.

## Product and presentation decisions

- HUD is black with clean, legible white numerals and gold status symbols.
- HUD separator color should contrast with each chapter's terrain palette.
- Chapter 1 uses violet/amethyst terrain; Chapter 2 uses orange terrain and a
  yellow HUD separator.
- Elastic surfaces use a clearly distinct animated rainbow gradient.
- Chapter lead-ins are faux green-screen NASA terminals with bold block text,
  six usable text rows, and an animated `MORE...` / `FIRE!` prompt band.
- Post-zone screen is a pale paper-like NASA manifest: animated red NASA zone
  heading, black status/score text, RELIC YES in moving green, RELIC NO static
  and subdued, and a dark-blue animated TRANSPORT bar.
- No password system is planned.
- Scoring: 40 points per Junk, 100 per Relic, saturating safely at 9990. A
  perfect planned 30-zone campaign totals 9240.
- Zone music is currently shared. Title and terminal have separate approved
  music. The manifest uses a roughly 96 BPM kick/snare disco pattern.

## Files to consult first

1. This document.
2. `docs/thursdays-child-chapter-two-proof.md`
3. `docs/thursdays-child-p1-positioning-regression-2026-09-05.md`
4. `docs/thursdays-child-production-map.md`
5. `docs/thursdays-child-chapter-plan.md`
6. `graphics/GRAPHICS_AND_LAYOUT.md`
7. Approved Zone 2-2 source and binary.

Ask Jason before changing creative direction. Preserve checkpoints before each
new zone. The goal is a polished commercial-quality physical Atari 2600 game,
not merely a technically running prototype.
