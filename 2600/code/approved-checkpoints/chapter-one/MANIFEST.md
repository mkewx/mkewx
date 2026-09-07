# Thursday's Child — Chapter One Integrated Checkpoint

Preserved September 4, 2026.

## Playable ROM

- `thursdays-child-chapter-one.bin`
- Size: 32,768 bytes (Atari 2600 F4 bankswitching)
- SHA-256: `2da0e5eb9941a7f754f6bd84284717a19bacdc3c1777e991679fb77cff0cf71f`

## Included flow

1. Approved power-on credits
2. Approved animated title screen and title music
3. Approved three-page NASA terminal Chapter One briefing and music
4. Five playable Chapter One stages with music and sound effects
5. Stage 5's existing completed/extracted hold

The post-chapter destination is deliberately not invented in this checkpoint;
the Chapter Complete/finale presentation is the next creative decision.

## Preservation contents

The checkpoint includes the complete integrated assembly source, adapted bank
renderers, generated playfield data, DASM listing and symbol map, and the custom
integration verifier used by `make verify-chapter-one`. `Makefile.integration`
preserves the workspace build recipe at the time of the checkpoint.

The separately approved credits, title, terminal, and gameplay baselines remain
preserved in `../chapter-one-integration-baseline-2026-09-04/`.

## Verification

`make verify-chapter-one` passes all of the following:

- all eight cold-reset landing pads and vectors;
- credits -> title -> terminal -> gameplay bank-switch gates;
- RESET recovery from presentation banks;
- fixed gameplay bank-call gates;
- assembled-ROM raster cycle traces for Stages 1–5;
- motion, object placement, audio, and stage progression checks;
- preservation of all approved Stage 1–5 visible display pages;
- canonical Major Tom sprite addresses and byte-identical art in every stage
  bank (correcting the three-byte Stage 2–5 pointer mismatch found during the
  first continuous integration playthrough);
- Atari 2600 128-byte RAM limit.
