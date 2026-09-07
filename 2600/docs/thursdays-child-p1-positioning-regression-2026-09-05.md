# Thursday's Child — P1 positioning regression record

Status: resolved and director-approved on 2026-09-05.

## Symptoms

- The green optional salvage appeared to move substantially right while FIRE
  was held during satellite orbit, then returned on release.
- Major Tom could collect it while apparently still outside its visible body.
- The behavior occurred in all five Chapter One stages.

## Two distinct faults and corrections

First, the multi-stage generic P1 positioner reused Major Tom's P0 timing bias.
P1 performed five additional CPU setup cycles before RESP1; on the VCS those
cycles equal fifteen horizontal color clocks. The rendered sprite therefore
sat fifteen pixels right of its authored 8x14 collision rectangle. A dedicated
P1 bias fixed the apparent oversized collection radius.

Second, correcting static alignment did not stop orbit-only movement. The
working correction reloads the adjusted P1 coordinate and HMP1 fine-motion
byte from immutable Bank 7 tables after physics on every frame, immediately
before the visible renderer consumes them. Director playtest confirmed stable
placement through FIRE-up, press, held orbit and release in every stage.

## Permanent safeguards

- Derive and test P1 timing independently from P0.
- Verify assembled P1 position against the logical collision coordinate for
  every stage.
- Refresh stationary cross-bank render state after physics, not merely at stage
  initialization.
- Preserve the timing-neutral three-byte refresh call/padding exchange that
  keeps the Stage 1 room kernel at its approved ROM-page phase.
- Run all raster traces and a human held-FIRE orbit test after any relevant
  renderer, HUD, bank, RAM or physics change.

## Approved ROM checkpoint

`outputs/thursdays-child-p1-post-physics-refresh-test-2026-09-05/`

- Direct gameplay SHA-256: `909cfad033dc520bb7448ecc0ca8bae4bad71d3abe7e5c5b51355e2e0bb78a82`
- Integrated SHA-256: `a678f88470a781e4d3468775bc280a7b5125ae453c2861170a3ffb4a57297c05`
