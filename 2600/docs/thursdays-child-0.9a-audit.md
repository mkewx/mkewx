# Thursday's Child 0.9A — Production Stage-Data Audit

## Outcome

The two approved rooms are now instances of one production stage contract.
0.9A intentionally adds no new stage or visual feature; it removes Stage-2-
specific progression and establishes the data and verification path required
before producing the remainder of Chapter One.

## Stage descriptor fields

Each stage supplies indexed data for:

- spawn X/Y;
- initial signed 8.8 X and Y velocity;
- beacon-triplet offset;
- terrain identity;
- palette identity;
- material/physics behavior identity;
- chapter music identity;
- room-renderer bank;
- next-stage link;
- all three visible satellite X/Y positions;
- all three required collectible X/Y positions;
- optional salvage X/Y;
- extraction gate X/Y.

The descriptor uses parallel byte arrays rather than large records. This is a
deliberate 6502 optimization: any field is selected with a single stage index
and `LDA table,X`, with no record multiplication or pointer RAM.

## Runtime changes

- `UpdateGame` reads `StageNextByStage`; it contains no Stage-2-specific test.
- `AdvanceStage` selects the next descriptor.
- `LoadCurrentStage` initializes stage-local state, spawn, velocity, beacon
  offset, HUD rebuild request, objectives, and music clocks from indexed data.
- Score is intentionally not reset by the loader.
- Collectible and extraction collision checks now read both X and Y from stage
  data instead of sharing hard-coded vertical constants.
- Terrain collision selects its authored inset family through `StageTerrainId`.
- Stage 1's reset seed remains in fixed Bank 7 for reset safety, but the build
  audit requires it to match descriptor row zero exactly.

## Current renderer contract

The present two raster kernels still use their proven, fixed P1 service slots:
satellite tops at 29/77/123, required items at 49/97/145, optional salvage at
9, and extraction at 161. The descriptor stores those values explicitly and
the verifier rejects any mismatch. Future room banks may introduce different
service schedules, but their physics coordinates and renderer pages must pass
the same agreement check.

## Production validation

`verify_thursdays_child_stages.py` rejects:

- missing, looping, unordered, or out-of-range stage links;
- invalid room-bank, terrain, palette, behavior, or music assignments;
- reset/descriptor disagreement;
- malformed beacon offsets or dishes not centered on their gravity points;
- spawns, satellites, or collectibles entering authored terrain;
- spawn/collectible overlap;
- objects leaving the 160×176 room;
- physics Y coordinates that disagree with the renderer service schedule;
- a loader that ignores a required descriptor field or reintroduces a
  Stage-2-specific constant.

The existing F4 map, both assembled-ROM raster traces, motion checks, object
checks, audio checks, packed-RAM limit, and fixed `$FFD9` bank return also pass.
Both rooms retain their 74-cycle longest visible paths and 262-line NTSC frame.

## Build identity

- Source SHA-256: `074f4eb26268e9504d5ebefa1a1259318afa75996eb8886676d260bec07ef6bf`
- ROM SHA-256: `5595ac120095b8952aa69abede30f04e026a346cf451684987ef3a5dbb155371`
