# Thursday's Child — production chapter and terrain map

This plan supersedes the early design brief's provisional 14 × 3 structure.
The commercial target remains 42 zones: eight five-zone chapters followed
by a two-zone Final Approach.

Each chapter teaches one physical consequence. Its five zones then follow the
same learning arc: introduction, development, topographic complication,
deliberate exploitation, and mastery. A zone may combine familiar ideas, but
it must not quietly introduce a second unexplained rule.

## Zone map

### Chapter 1 — Violet Drift: ordinary rock and the core vocabulary

1. **Open Bowl:** generous airspace; teach moon bounce, capture and release.
2. **Crossing Shelves:** asymmetric walls and longer transfers between dishes.
3. **Broken Shoulders:** floor and ceiling shelves create two readable routes.
4. **First Teeth:** broad stalactites and stalagmites introduce narrow aiming.
5. **Violet Grotto:** an S-shaped passage tests the complete normal-physics set.

### Chapter 2 — Elastic Reach: spring terrain and amplified rebound

6. **Soft Launch:** one conspicuous spring floor teaches the stronger rebound.
7. **Side Kick:** a spring wall turns horizontal contact into a useful transfer.
8. **Pogo Garden:** spaced stalagmites reward selecting the correct landing.
9. **Rebound Tunnel:** a spring surface must be used to clear a ceiling pinch.
10. **Elastic Labyrinth:** mixed rock and spring surfaces test intentional use.

### Chapter 3 — Frozen Aurora: contact suppresses momentum briefly

11. **Cold Patch:** one isolated freeze surface demonstrates the status cue.
12. **Cold Recovery:** freezing occurs near a deliberately reachable dish.
13. **Icy Teeth:** ceiling and floor projections punish careless release timing.
14. **Stillness Gate:** losing speed is the safe way into a narrow passage.
15. **Aurora Vault:** freeze and ordinary rock form a route-planning challenge.

### Chapter 4 — Heavy Air: drag shortens arcs while contact persists

16. **First Resistance:** a wide drag region makes the shortened arc obvious.
17. **Short Crossing:** a dish beyond the region teaches compensating release.
18. **Dense Cavern:** alternating terrain forces repeated drag entry and exit.
19. **Brake Turn:** drag becomes a tool for reaching a protected collectible.
20. **Heavy-Air Works:** a claustrophobic multi-route room tests arc control.

### Chapter 5 — Contrary Signal: marked fields reverse the next orbit

21. **Wrong Way Round:** one marked field safely demonstrates reversal.
22. **Choice of Hand:** two approaches teach selecting rotation deliberately.
23. **Counter-Corkscrew:** offset teeth require reversing at the correct dish.
24. **Back Door:** reversal opens the safer of two tunnel routes.
25. **Contrary Engine:** a dense chamber tests approach side and field state.

### Chapter 6 — Inverted Fall: ambient pull temporarily points upward

26. **Ceiling Moon:** an open room introduces landing and bouncing overhead.
27. **Two Floors:** safe regions above and below teach the state transition.
28. **Hanging Teeth:** stalactites become the navigable surface, not decoration.
29. **Gravity Chimney:** inversion is required to climb a vertical passage.
30. **Inversion Cathedral:** tall chambers test recovery in either gravity state.

### Chapter 7 — Plasma Confluence: paired, previously learned effects

31. **Spring and Drag:** amplified rebound followed by controlled braking.
32. **Freeze and Reverse:** stillness creates time to choose the next rotation.
33. **Elastic Ceiling:** spring terrain is revisited under inverted gravity.
34. **Confluence Tunnels:** two routes use different familiar effect pairings.
35. **Plasma Crucible:** a demanding but fully signposted combination test.

### Chapter 8 — Homeward Signal: complete-system mastery

36. **Long Way Home:** a broad room offers a safe route and a scoring shortcut.
37. **Needle Thread:** careful tangents pass through alternating rock teeth.
38. **Signal Maze:** dish order is discovered through terrain and sight lines.
39. **No Quiet Ground:** recovery surfaces are scarce but never absent.
40. **Homeward Vault:** the deepest authored cave uses the full vocabulary.

### Final Approach

41. **Re-entry:** a rigorous integration zone with a clear visual destination.
42. **Ground Control:** a hopeful final flight that resolves into the finale.

Names and exact layouts remain subject to playtesting. The effect sequence is
the production baseline; changing it requires a deliberate design review.

## Terrain and fairness rules

- Terrain may be asymmetric and may occupy the floor, ceiling, walls or center.
- Every required collectible and extraction route must be reachable from the
  authored spawn without relying on an emulator-specific collision.
- A trapped state must always have a deterministic escape, recovery bounce or
  reachable dish. No decorative pocket may capture Major Tom indefinitely.
- For satellite-only control, geometric walkability is not enough. Automated
  zone audits must reject disconnected legal-position components and must prove
  that the spawn component intersects the capture field of every installation.
- A chamber-spanning interior platform is forbidden unless both resulting
  regions have independently verified satellite recovery routes. Side-attached
  shelves are the default way to add early complexity without creating a trap.
- The broadest orbit is tested against every nearby terrain footprint.
- Satellite table indices are always derived from `currentStage * 3 + local
  satellite`; never cache a zone offset in upper RIOT RAM because the 6502
  stack mirrors and overwrites that region.
- Authored satellite rings are protected corridors. Free-flight terrain
  collision must never roll back captured orbit motion; every ring endpoint
  and interpolated midpoint is validated before a zone is accepted.
- Claustrophobia comes from meaningful passages, not from reducing the entire
  room to cramped empty play.
- Every zone receives an automated footprint audit plus human completion in
  Stella before it can be called production-ready.
- Visible terrain bytes and software collision geometry must be mechanically
  compared for every authored band and interior island. A visually solid pixel
  with no matching collision—or invisible collision with no matching pixel—is
  a build failure.
- Satellite placement is route design, not decoration. Each zone must author
  its satellite geometry around that room's terrain, objectives, intended
  transfers and recovery opportunities; shifting a repeated silhouette is not
  sufficient.
- Chapter One's five introductory arrangements are approved. Later chapters
  must avoid a recurring right-side bias and use genuinely asymmetric vertical
  and horizontal relationships, deliberate gaps, and terrain-dependent paths.
- Zone 3's distant Space Relic is a positive reference: it initially
  appears unreachable, but the correct capture angle and gravitational release
  provide enough upward authority to reach it. Later optional routes may use
  this kind of discoverable gravitational solution, provided human playtesting
  confirms a fair margin for error.
- Claustrophobic rooms must coordinate satellites with stalactites,
  stalagmites, tunnels and central obstacles. A default launch may threaten
  terrain, but at least one readable satellite transfer must prevent an
  unavoidable collision and every failure state must remain recoverable.

## Object-positioning regression rule

The 2026-09-05 optional-object regression established a permanent rendering
rule. The generic P1 positioner initially reused P0's timing bias even though
P1 performed five additional setup cycles, displacing the sprite fifteen color
clocks from its logical collision rectangle. Correcting that bias restored
visual/collision alignment. A second orbit-only movement remained until the
two cached P1 positioning bytes were refreshed from immutable Bank 7 ROM after
physics and immediately before visible rendering.

- P0 and P1 must always have independently derived cycle formulas.
- Stationary P1 coordinates that cross the physics boundary are refreshed from
  immutable ROM immediately before rendering; zone-load initialization alone
  is not sufficient.
- Automated checks must compare rendered P1 X against the authored collision X
  for every zone and verify the post-physics refresh path and ROM tables.
- Any future change to P1 setup, HUD restoration, HMOVE, RESP1, HMP1, NUSIZ1,
  bank calls or RAM allocation requires held-FIRE orbit testing in Stella.
- A build is not approved merely because free-flight placement looks correct;
  FIRE-up, FIRE-press, sustained orbit and release are separate acceptance
  states.

## Palette rule

Every chapter owns one recognizable hue family. Its five rooms vary the blend,
luminance curve and HUD-divider colors without looking like unrelated worlds.
The next chapter then makes a decisive family change. Chapter One uses violet,
indigo, mauve and blue-violet treatments. Special-effect terrain must have one
consistent, unmistakable accent within its chapter.

## Starfield rule

The 0.9C starfield laboratory was rejected after visual playtesting. Reusing a
TIA object produced conspicuous dashes with constrained placement, while a
dense, independently positioned and terrain-aware field would place the stable
gameplay kernel at unnecessary risk. Production gameplay retains clean black
negative space. Visual resources are reserved for satellites, collectibles,
exits, terrain, chapter effects and Major Tom.
