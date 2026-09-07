# Thursday's Child 0.9B audit

- Chapter One now contains five ordered playable room descriptors.
- Stage progression is 1 → 2 → 3 → 4 → 5 → completed-build hold.
- Stages 1–5 render from Banks 7, 6, 5, 4 and 3 respectively.
- Banks 1 and 2 remain reserved.
- Stages 3–5 have dedicated scanline-stable kernels and terrain pages.
- All five rooms use independent terrain IDs, palette IDs, spawns and object
  metadata; Stages 3 and 4 also use independently timed P1 horizontal strobes.
- Chapter One palettes form a related violet/indigo/mauve family rather than
  unrelated chapter colors.
- Every room retains normal-rock rebound and the Chapter One music.
- The geometry verifier checks complete astronaut, satellite, collectible,
  optional-item and exit footprints against every terrain band.
- The raster verifier cycle-traces every room independently. Longest visible
  paths remain at or below 74 CPU cycles before WSYNC.
- Stage 1's approved display pages and exact room-kernel phase remain intact.
- Stars are deferred to a separate regression-controlled visual proof.
