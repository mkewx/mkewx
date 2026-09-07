# Thursday's Child — Chapter Two proof

## Approved design inputs

- Player-facing areas remain **zones**.
- The pre-chapter presentation retains the approved green NASA terminal,
  animated bottom prompt, and two-voice 120 BPM terminal cue.
- Chapter Two ordinary terrain is orange.
- The HUD/playfield divider is yellow and deliberately does not match the
  ordinary terrain.
- Elastic terrain uses a rainbow ramp and a distinct horizontal-band shape.
- The universal gameplay cue remains the **Zone Score**.

## Terminal copy

Page 1:

    NASA
    CONTROL TO
    MAJOR TOM:
    RAINBOW
    GROUND IS
    ELASTIC.

Page 2:

    CONTACT
    DOUBLES
    BOUNCE.
    USE FIRE
    TO REACH
    SATELLITES

Page 3:

    CHAPTER
    TWO:
    LEARN THE
    REBOUND.
    SPACE GETS
    TIGHTER...

Pages 1–2 use `MORE...`; page 3 uses `FIRE!`.

## Zone 2-1 proof contract

- The final eight scanlines form a full-width elastic floor. Orange terrain
  terminates above it, so orange and rainbow terrain never require independent
  colors on the same scanline.
- Bottom contact doubles the incoming downward 8.8 velocity and negates it.
- A minimum magnitude of 0.5 pixel/frame prevents an imperceptible weak bounce.
- Existing fall-speed saturation bounds the strongest result at 1.75
  pixels/frame upward; the calculation cannot wrap.
- Side and ceiling rock retain the normal Chapter One collision response.
- Satellite orbit/capture/release physics and the Zone Score are unchanged.
- The three satellites no longer occupy the right-hand lane. Their visible X
  coordinates are 108, 66, and 75: upper-right, middle-left, then lower-center.
- Required Space Junk is separately distributed at X 108, 75, and 84 rather
  than repeating one right-side column.
- Two normal orange shelves intrude from opposite sides of the chamber. Their
  playfield pixels and software-collision depths are verified as exact pairs,
  so they are real trajectory obstacles rather than decoration.
- The launch seed begins low-left and avoids every Junk object for the first
  3,000 untouched frames (50 NTSC seconds), giving the player time to engage
  the satellite mechanic instead of receiving immediate automatic pickups.
- The Space Relic is in the upper-left, deliberately separated from the route.
- The enabled exit is embedded in the lower-right terrain rather than centered.
  This establishes that each future zone owns an independently authored exit
  location as well as independently authored satellite positions.
- The elastic-floor colors advance once every eight frames. The geometry and
  collision surface remain fixed while the rainbow appears to flow.
- Every animated floor-color write occurs during horizontal blank, preventing
  the mid-scanline fragments seen in the discarded prototype.
- The isolated proof does not advance into an unrelated Chapter One zone after
  extraction.

## Regression guarantees

- Chapter Two additions are compile-time isolated behind
  `CHAPTER2_ZONE1_LAB`.
- The standard Chapter One build passes its complete raster, motion, object,
  audio, stage, and score verification suite after the addition.
- Stationary Space Relic positioning still refreshes from immutable data after
  physics; held FIRE cannot move it.

## Zone 2-2 recoverability contract

- Beacon table indices are calculated from `currentStage * 3 + satellite` at
  every lookup. They are never retained in upper RIOT RAM, which is mirrored by
  the 6502 stack and can be overwritten by nested calls. This prevents later
  zones from orbiting invisible Chapter One anchor coordinates.

- The discarded long center platforms are prohibited: each divided the room
  into a pocket from which satellite-only control could not reliably recover
  Major Tom.
- Zone 2-2 uses deeper asymmetric side-attached orange teeth around one
  continuous cavity. Two side-only bands at Y=72–87 use opposing rainbow ramps
  whose color phase advances every eight frames. Shelf colors are calculated
  during spare time on the preceding odd scanline, held across `WSYNC`, and
  committed during horizontal blank, leaving the approved
  playfield-write timing and the ordinary orange terrain untouched. Elastic contact is tested
  against Major Tom's complete 8-by-14 candidate rectangle (not a center point),
  so even a one-scanline edge strike receives the capped 2× rebound. The
  animated elastic floor remains intact.
  Center islands remain prohibited because they can obstruct orbit envelopes
  or create unrecoverable pockets.
- Major Tom launches naturally from `(68,146)` with velocity `(-$0060,+$0060)`.
  The normal Chapter One input and free-flight rules remain intact; there is no
  special FIRE gate. The authored trajectory avoids every Space Junk footprint
  for at least 1,200 frames (about 20 seconds) without player input.
- Verification enumerates every legal 8-by-14 Major Tom position and rejects
  the build unless all positions form one connected component containing the
  spawn and reachable capture space for all three satellites.
- Every side-wall PF1 pattern is decoded back into its visible color-clock
  depth and compared with the software collision inset. This permanently guards
  against the 4–8-pixel pass-through error found during the Zone 2-2 audit.
- The PF2 audit permits only the ceiling and elastic floor in this zone.
  Additionally, all 64 points of every near, middle and far orbit around all
  three satellites, plus all 64 rendered far-orbit midpoints, are checked
  against terrain before the ROM can pass. Captured orbit motion never enters
  the free-flight terrain rollback path; verified satellite rings are protected
  corridors and therefore cannot pin Major Tom beside an installation.

## Proof ROMs

- `thursdays-child-chapter-two-terminal.bin`
  SHA-256: `0199e82d98e872dadcc0b7873a593c2953148c0f20a9348bbf8d53fd2546c66a`
- `thursdays-child-chapter-two-zone1.bin`
  SHA-256: `c6d6d446c3d1db5a6f6954af91cacabf43376d42a1c710a15e644be207510663`

The two Zone 2-1 Stella captures preserve different animation phases of the
same ROM. Their unchanged geometry and differing floor colors document that
the effect is palette flow rather than playfield movement.
