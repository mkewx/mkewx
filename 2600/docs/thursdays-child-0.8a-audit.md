# Thursday's Child 0.8A — Sound-Effects Audit

## Scope

0.8A adds gameplay sound effects only. Music remains absent. The approved
0.7B picture, HUD, two rooms, terrain, physics, object positions, and stage
transition are unchanged.

## Event vocabulary

- Capture: short rising lock-on tone.
- Tangent release: restrained descending noise sweep.
- Required collectible: quick crystalline alternating chirp.
- Optional salvage: warmer, higher two-note reward.
- Extraction activation: longer rising confirmation.
- Stage completion: deliberate four-cell phrase.

The third required pickup starts the extraction-activation cue instead of
layering two simultaneous sounds. A later event may replace an earlier cue;
this keeps the single audio channel intelligible.

## Timing and memory contract

- `StartSound`, `UpdateSound`, and all audio data live in engine Bank 0.
- `UpdateSound` runs after physics, collection, and exit contact processing,
  before the fixed bank return and before any visible scanline.
- No visible room kernel writes an audio register.
- Audio state uses one packed byte below `$F5`; bits 7–5 hold the effect and
  bits 4–0 hold its remaining frames. `$F5–$FF` remain reserved for the 6502
  call stack, including nested subroutine calls.
- The fixed Bank 0 gate is still `JSR UpdatePhysics` at `$FFD3`, followed by
  the Bank 7 hotspot read at `$FFD6`; execution resumes at Bank 7's `$FFD9`
  `RTS`. The verifier explicitly rejects any drift in this contract.

## Verification

`make verify-thursday` passes:

- 32K F4 map and reset landings;
- approved Stage 1 display-page identity;
- Stage 1 and Stage 2 assembled-ROM raster traces;
- orbit smoothness and capture range;
- both stages' objects, spawns, and terrain-safe footprints;
- all six sound triggers, Bank-0-only audio ownership, RAM bounds, and exact
  cross-bank return bytes.

Longest visible paths remain 74 cycles in both room kernels. The NTSC frame
remains 262 scanlines.

## Build identity

- Source SHA-256: `ff59e02c27386ddde63046cb9ab7c1313186942aac2e05ccc665e80e542beac6`
- ROM SHA-256: `79cfaf075175605288438fefe75839e8dbc9950ab40f967987f27e7d8a214630`
