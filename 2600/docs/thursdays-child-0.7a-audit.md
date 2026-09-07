# Thursday's Child 0.7A audit

Status: **director approved**.

Phase 0.7A migrates the approved 8 KB F8 production build to a 32 KB F4
cartridge without changing gameplay or presentation.

## Locked baseline

- Approved 0.6A source SHA-256:
  `3e96f7719148cee0c6846e33ab940e2875f00d52c72307e9541aafa5f3634b8c`
- Approved 0.6A ROM SHA-256:
  `f3da1398d0868a26306952b1e795987e20e135e7804695c8723983d08fac2f4b`

## F4 map

- Bank 0: approved physics, gravity, collision, and mission state.
- Banks 1-6: reserved stage/chapter capacity.
- Bank 7: approved reset, frame, HUD, room renderer, art, and Stage 1 data.
- Every bank has the same reset-safe landing pad and vectors.

The two active 4 KB banks are byte-identical to the approved F8 banks except
for four required hotspot operand bytes: F8 Bank 1 selection becomes F4 Bank 7
selection, and F8 Bank 0 calls become F4 Bank 0 calls.

## Automated gates

- Exact 32 KB size and all eight reset pads/vectors.
- Banks 1-6 remain unused in this architecture-only phase.
- Byte comparison against the approved physics and display banks.
- Exact visible-kernel cycle tracing.
- Three-tier orbit cadence and capture-edge verification.
- Four-object, satellite, extraction, spawn, terrain-footprint, and horizontal
  coordinate verification.

## Director acceptance

The director confirmed in Stella that the F4 build works perfectly and is
visually and mechanically indistinguishable from the approved F8 baseline.
