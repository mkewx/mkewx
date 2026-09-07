# Graphics and layout reference

The game does not use conventional external bitmap assets. Its artwork is
encoded as 6502 data tables and Atari TIA playfield/player/missile graphics.
Therefore, the authoritative graphics information is in the source includes,
not in PNG files.

## Authoritative assets

- Major Tom: `code/current/src/thursdays-child.asm`, canonical seven logical
  rows doubled to an 8x14 sprite in every room bank.
- Mission objects and satellites:
  `code/current/src/thursdays-child-stage*-objects.inc`.
- Zone 2-3 candidate object schedule:
  `thursdays-child-stage3-zone2-3-objects.inc`.
- Title artwork and block lettering:
  `thursdays-child-title-bank.inc` and `thursdays-child-title-lab.inc`.
- Terminal lettering and pages:
  `thursdays-child-terminal-bank.inc`, `thursdays-child-terminal-lab.inc`, and
  `thursdays-child-chapter-two-terminal.inc`.
- Credits: `thursdays-child-credits-bank.inc` and
  `thursdays-child-credits-compact.inc`.
- Post-zone manifest: `thursdays-child-zone-manifest-lab.inc`.
- Terrain: the `TerrainColor`, `TerrainLeftPF1`, `TerrainRightPF1`, and
  `TerrainPF2` page-aligned tables in `thursdays-child.asm`.

## Approved visual language

- Black space remains the negative-space playfield.
- Chapter terrain is sculpted from scanline color gradients rather than flat
  blocks. Left and right silhouettes may differ.
- Major Tom is the simple approved white astronaut with black visor opening.
  Do not substitute a ship or redesign him between screens and gameplay.
- Satellites are blue crescent/dish forms; Space Junk is gold; the Space Relic
  is an animated green star-like object; extraction is a gate.
- Terrain, objects and HUD must never share colors so closely that silhouettes
  disappear.
- Gradient animation must change palette values only and must not introduce
  jagged playfield writes, horizontal fragments, or moving collision geometry.

## Reference captures

`reference-captures/` includes approved Chapter 2 terminal/Zone 2-1 views and
the post-zone manifest proof. They are visual references, not source assets.

## Zone 2-3 candidate geometry

- Playfield coordinate system used by collision analyzer: X=16..135,
  Y=8..167 for the free cavity after outer terrain.
- Major Tom footprint: 8x14.
- Center platforms: X=64..95.
- Top elastic: Y=64..71.
- Middle normal: Y=80..87.
- Bottom elastic: Y=104..111.
- Candidate spawn: (48,40).
- Candidate satellites (visible top-left): (75,27), (117,81), (75,131).
- Candidate beacon centers: (79,34), (121,88), (79,138).
- Candidate Relic: (24,11).
- Candidate Junk: (81,49), (102,99), (81,147).
- Candidate exit: (99,163).

These coordinates passed static geometry and orbit-clearance analysis but have
not yet received successful human playtesting because the lab boot banking bug
must be repaired first.
