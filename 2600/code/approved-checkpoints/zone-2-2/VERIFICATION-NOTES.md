# Zone 2-2 checkpoint — verification notes (2026-09-07)

## What's confirmed

`thursdays-child-zone2-2-mechanics-approved.bin` was run directly (not rebuilt) in
Stella under headless emulation for 6+ seconds. No crash, no fatal-instruction error.
Captured frame shows coherent gameplay: three satellite sprites, terrain, a mission
object. **This binary is good and remains the ground truth for Zone 2-2 behavior.**

## What's NOT confirmed: source parity

Rebuilding `thursdays-child.asm` from this folder (using the `stage2-5-objects.inc`
now copied in alongside it, taken from `code/current/src/` on 2026-09-07) does
**not** reproduce the shipped `.bin` byte-for-byte. 3,203 of 32,768 bytes differ,
confined to banks 0, 6, and 7:

- **Bank 6** — explained: `stage2-objects.inc` (Chapter 1 stage-2 data) had already
  drifted from whatever version built the approved binary. Banks 3/4/5 (stage 5/4/3
  data) matched exactly, so this was isolated to stage 2 only.
- **Banks 0 and 7** — NOT explained by any include (bank 7 has no includes; bank 0's
  relevant constants are inline in the same file). Hex comparison shows internal
  JSR call targets shifted by a consistent +23 bytes in the approved binary versus
  a fresh rebuild, which is the signature of a small code difference earlier in the
  bank. Toolchain version was ruled out as a cause: the same DASM reproduced the
  Chapter 1 checkpoint's shipped `.bin` byte-for-byte from its own (fully
  self-contained) source. Conclusion: **this saved `thursdays-child.asm` is not
  proven to be the exact source that built the shipped Zone 2-2 binary** — it's
  close, but not it.

## Practical implication

Until/unless the exact original source turns up, don't use "does a rebuild diff
match the approved .bin" as a correctness check for Zone 2-2. Use behavioral
verification instead (run both in the emulator, compare gameplay/frames) — which is
how this was actually verified above.

The `stage2-5-objects.inc` files now sitting in this folder are frozen copies of
`code/current/src/`'s versions as of 2026-09-07, so future edits to `code/current/`
won't silently move this checkpoint's own rebuild further from where it already is.
