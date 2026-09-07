# Thursday's Child 0.7B — two-stage production playtest

Status: assembled, structurally verified, cycle-traced in both display banks,
and visually inspected in Stella 7.0. Director playtest pending.

Revision note: the first technically working Stage 2 was rejected as a weak
level design. The current revision replaces its clustered satellite column
with a left-right-left route, alternates objective targets across the chamber,
adds substantial ceiling/floor formations and deep middle shelves, and gives
the HUD/ceiling divider a coral gradient distinct from the teal/cobalt terrain.

## What 0.7B adds

- Stage 1 remains the approved amethyst room in fixed Bank 7.
- Securing its three required objects and touching the extraction gate holds
  the completed frame for 48 frames, then begins Stage 2.
- Stage 2 is an independently authored teal/cobalt room in Bank 6. Its terrain
  is asymmetric, is not derived by mirroring Stage 1, and now includes deep
  top, bottom, and middle formations rather than only decorative side walls.
- Stage 2 has independent spawn, satellite, collectible, optional salvage,
  exit, and software-collision coordinates.
- The HUD changes its stage numeral from 1 to 2. Collected-object indicators
  reset for Stage 2 while the score remains persistent.
- Each required object awards 10 points; optional salvage awards 20 points.
  The production HUD now supports the complete two-stage range through 100.

## Raster and bank safety

- Bank switching occurs only after the HUD and before Stage 2's first room
  WSYNC, then after the complete 176-line Stage 2 room and its overscan.
- No hotspot is read during a visible room scanline.
- Stage 1's six raster-authored display pages remain byte-for-byte identical
  to the director-approved 0.7A F4 ROM.
- Both room kernels were traced from assembled machine code. Their longest
  Major Tom path is 74 of 76 CPU cycles.
- All seven Stage 2 P1 service bands meet the PF1 deadline and render at their
  declared X coordinates.
- Every service handler is also checked against the exact authored right-wall
  byte for its scanline, preventing single-line black cuts after terrain edits.
- Five future-content banks remain empty and reset-safe.
- Persistent state remains inside the VCS's `$80-$FF` RAM.

## Geometry audit

- Both spawns clear every collectible.
- All four pickups and all three satellites in both stages have complete
  terrain-safe rectangular footprints.
- Beacon centers remain tied to their visible satellite dishes.
- Major Tom's exact P0 positioning model still maps every legal X coordinate
  to the same rendered color clock.

## Director playtest

1. Confirm Stage 1 is visually and mechanically identical to approved 0.7A.
2. Collect the three required gold objects; optional green salvage may be
   collected or skipped.
3. Confirm the exit appears only after the three required objects.
4. Touch the exit and confirm a short, stable completion hold leads to Stage 2.
5. Confirm the HUD reads Stage 2, its four icons reset, and the score carries.
6. Confirm Stage 2 is teal/cobalt, asymmetric, and visibly different.
7. Test all three Stage 2 satellites, all orbit tiers, tangent releases,
   terrain reversals, moon bounce, and both wall edges.
8. Collect Stage 2's objectives and confirm its exit reveals and completes.
9. Watch both stages for vertical roll, one-pixel frame jumps, black terrain
   cuts, HUD debris, sprite corruption, or collision/render disagreement.
