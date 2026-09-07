# Thursday's Child — chapter effects and presentation map

This document locks the production structure for *Floating in a Most Peculiar
Way*. It complements `thursdays-child-chapter-plan.md` and defines the physical
rule taught by each chapter, the five-zone teaching arc, and the non-gameplay
screens surrounding the 42-zone journey.

## Production structure

- **Chapters 1–8:** five zones each (40 zones)
- **Final Approach:** two zones (41–42)
- **Total:** 42 hand-authored, single-screen zones
- **Continuation:** no password or persistent-progress system; a powered session
  begins at Zone 1
- **Records:** best completed-run score and relic total for the current powered
  session; no SaveKey or AtariVox dependency

Every five-zone chapter uses this difficulty grammar:

1. **Teach:** isolate the chapter rule in a generous room.
2. **Develop:** require it once in a clearly readable route.
3. **Complicate:** add meaningful floor, ceiling, or central terrain.
4. **Exploit:** make the apparent hazard useful or necessary.
5. **Master:** test the rule without introducing another unexplained system.

### Score contract

- Each Space Junk pickup awards **40 points**.
- Each Space Relic awards **100 points**.
- A perfect zone is worth **220 points**.
- The 42-zone mathematical maximum is **9,240 points**: 126 Space Junk
  pickups × 40, plus 42 Space Relics × 100.
- The four-digit score stores ten-point units in a bounded 16-bit value and
  saturates at `9990`; it can never roll over to `0000`. The authored campaign
  cannot naturally reach that guard.
- Any future completion, time, difficulty or finale bonus must fit inside the
  unused 750-point bounded headroom or trigger an explicit score-system review.

## Mission vocabulary

- Each zone is a Ground Control-directed cleanup operation. Ground Control
  controls Major Tom's every move through NASA's satellites.
- The three required pickups in each zone are **Space Junk**. Major Tom's
  assignment is to clear that zone of hazardous cargo.
- NASA activates the zone exit/transport only after all required Space Junk
  has been cleared.
- The distinct optional green pickup is a **Space Relic**. Major Tom is an
  adventurer at heart, and NASA helps him secure one in every zone when the
  route permits. A relic is never required for transport; recovering it awards
  additional points and prestige for Major Tom's mission.
- Future instruction-manual copy, HUD legends, briefings and result screens
  must preserve this distinction consistently. Do not call the green optional
  pickup Space Junk or use any other substitute label.
- **Zone** is the sole player-facing term for an individual gameplay area.
  Briefings, HUD text, manifests, records, finale copy, packaging and the
  instruction manual must never call a zone a stage or level. Existing
  `currentStage`-style source symbols are legacy internal engine identifiers,
  not story vocabulary, and need not be renamed unless that can be done safely.
- **Ground Control** is the speaking/controlling authority. NASA supplies the
  satellites, terminal and mission infrastructure.

## Chapter effect map

### Chapter 1 — Violet Drift: Learn the Pull

**Rule:** ordinary moon gravity, rock rebound, three capture radii, approach-
side orbit direction, and tangent release. There is no status modifier.

**Lead-in tease:** `LEARN THE PULL` / `HOLD. SWING. RELEASE.`

| Zone | Purpose | Terrain emphasis |
| --- | --- | --- |
| 1. Open Bowl | Capture, orbit, release, recover | Wide floor and sidewalls |
| 2. Crossing Shelves | Transfer between separated satellites | Asymmetric shelves |
| 3. Broken Shoulders | Choose between two readable routes | Floor and ceiling shoulders |
| 4. First Teeth | Aim through restricted space | Broad stalactites/stalagmites |
| 5. Violet Grotto | Prove the complete core vocabulary | Open S-shaped passage |

### Chapter 2 — Elastic Reach: Spring Rebound

**Rule:** brightly accented elastic terrain produces a stronger but
deterministic rebound. It changes only the velocity component normal to the
surface; it must not create random pinball motion.

**Lead-in tease:** `THE WALLS PUSH BACK` / `A FALL CAN BECOME A FLIGHT.`

| Zone | Purpose |
| --- | --- |
| 6. Soft Launch | A single spring floor demonstrates the higher return. |
| 7. Side Kick | A spring wall redirects Major Tom across the room. |
| 8. Pogo Garden | Spaced spring teeth reward choosing the landing point. |
| 9. Rebound Tunnel | A spring contact is required to clear a ceiling pinch. |
| 10. Elastic Labyrinth | Rock and spring surfaces require deliberate selection. |

### Chapter 3 — Frozen Aurora: Momentum Freeze

**Rule:** contact with icy terrain briefly suppresses horizontal and vertical
momentum. Major Tom visibly enters a short frozen state, then ambient gravity
resumes. The state is timed and deterministic; it never throws him randomly.

**Lead-in tease:** `MOTION CAN SLEEP` / `STILLNESS CHANGES THE ROUTE.`

| Zone | Purpose |
| --- | --- |
| 11. Cold Patch | One safe freeze surface demonstrates the state and cue. |
| 12. Cold Recovery | A reachable satellite teaches recovery after freezing. |
| 13. Icy Teeth | Poor timing freezes Major Tom in an awkward but recoverable place. |
| 14. Stillness Gate | Cancelling momentum becomes the safe route into a gap. |
| 15. Aurora Vault | Freeze and ordinary rock form a planned sequence. |

### Chapter 4 — Heavy Air: Persistent Drag

**Rule:** marked terrain applies a temporary drag state. Each free-flight frame
reduces Major Tom's speed until the state expires; the result is a shorter,
steeper, predictable arc rather than an abrupt stop.

**Lead-in tease:** `THE VOID GROWS HEAVY` / `LONG ARCS FALL SHORT.`

| Zone | Purpose |
| --- | --- |
| 16. First Resistance | An open room makes the shortened arc unmistakable. |
| 17. Short Crossing | The player compensates with a tighter release. |
| 18. Dense Cavern | Repeated drag entry and exit changes route planning. |
| 19. Brake Turn | Drag becomes the tool for reaching a protected Space Relic. |
| 20. Heavy-Air Works | A claustrophobic multi-route room tests controlled braking. |

### Chapter 5 — Contrary Signal: Orbit Reversal

**Rule:** marked signal terrain toggles the direction of the next satellite
orbit. The altered state persists until a capture consumes it. A strong color
and sound cue makes the pending reversal unambiguous.

**Lead-in tease:** `THE SIGNAL LIES` / `THE NEXT PULL TURNS CONTRARY.`

| Zone | Purpose |
| --- | --- |
| 21. Wrong Way Round | One safe field demonstrates the next-orbit toggle. |
| 22. Choice of Hand | Two approaches teach selecting rotation deliberately. |
| 23. Counter-Corkscrew | Offset teeth require the reversed orbit. |
| 24. Back Door | Reversal opens the safer of two routes. |
| 25. Contrary Engine | A dense chamber tests approach side and pending state. |

### Chapter 6 — Inverted Fall: Upward Gravity

**Rule:** inversion terrain temporarily reverses ambient gravity. The ceiling
becomes a recovery surface until the state expires or a clearly marked reset
surface is touched. Every room must support recovery in both states.

**Lead-in tease:** `UP HAS FORGOTTEN YOU` / `THE CEILING IS A FLOOR.`

| Zone | Purpose |
| --- | --- |
| 26. Ceiling Moon | An open room introduces overhead landing and bounce. |
| 27. Two Floors | Safe surfaces above and below teach the transition. |
| 28. Hanging Teeth | Ceiling terrain becomes the useful route. |
| 29. Gravity Chimney | Inversion is required to climb a vertical passage. |
| 30. Inversion Cathedral | Tall chambers test recovery in either state. |

### Chapter 7 — Plasma Confluence: Combined Effects

**Rule:** no new status effect. Two previously mastered effects coexist in
each room. Their terrain colors remain individually recognizable.

**Lead-in tease:** `THE FIELDS CONVERGE` / `WHAT YOU LEARNED NOW INTERACTS.`

| Zone | Purpose |
| --- | --- |
| 31. Spring and Drag | Build speed, then brake it. |
| 32. Freeze and Reverse | Stillness creates time to select the next rotation. |
| 33. Elastic Ceiling | Spring terrain returns under inverted gravity. |
| 34. Confluence Tunnels | Two routes use different familiar pairings. |
| 35. Plasma Crucible | A demanding, fully signposted combination test. |

### Chapter 8 — Homeward Signal: Mastery

**Rule:** the complete vocabulary is available, but each zone selects only the
effects its geometry needs. Difficulty comes from authored routes and recovery,
not unpredictable stacking.

**Lead-in tease:** `THE SIGNAL IS HOME` / `USE EVERYTHING. BRING HIM THROUGH.`

| Zone | Purpose |
| --- | --- |
| 36. Long Way Home | A safe route and a difficult Space Relic shortcut. |
| 37. Needle Thread | Careful tangents pass alternating rock teeth. |
| 38. Signal Maze | Sight lines communicate a discoverable satellite order. |
| 39. No Quiet Ground | Recovery surfaces are scarce but never absent. |
| 40. Homeward Vault | The deepest authored cave tests complete fluency. |

### Final Approach

**Rule:** resolve the journey rather than introduce another mechanic.

**Lead-in tease:** `SIGNAL LOCKED` / `GROUND CONTROL IS WAITING.`

| Zone | Purpose |
| --- | --- |
| 41. Re-entry | A rigorous but readable integration zone with rescue in sight. |
| 42. Ground Control | A hopeful final flight ending at the rescue craft. |

## Screen flow

### 0. Publisher presentation

- Fire-gated black screen before the attract/title screen
- Centered white production-proven block typography
- Credits Jason Lee and the eventual publisher, ending with `PRESENT...`
- Final wrapping is deferred until the publisher name is known

### 1. Attract/title screen

- Large three-line title: `FLOATING / IN A MOST / PECULIAR WAY`
- Prominent, production Major Tom silhouette
- Bold static or gently sequenced title gradient; title code is isolated from
  the gameplay kernel and may therefore be more visually ambitious
- Two-voice title theme
- `PRESS FIRE`
- Inactivity may cycle to the Records screen and back

### 2. Mission menu

Three choices, navigated vertically and confirmed with Fire:

- `BEGIN MISSION`
- `RECORDS`
- `OPTIONS`

Options provides independent `MUSIC ON/OFF` and `SOUND ON/OFF`. These settings
last for the powered session.

### 3. Records screen

- Best completed-run score during the current powered session
- Best Space Relic total during the current powered session
- No claim of permanent storage
- If no run has finished, display a clean placeholder rather than zero-filled
  visual clutter

### 4. Chapter lead-in

Shown before Zone 1 and whenever a new chapter begins.

- Presented as a faux NASA computer terminal with a chapter-specific dark
  phosphor gradient and high-contrast block lettering.
- Up to three Fire-advanced pages; the bottom command band reads `MORE...`
  until the final page, where it reads `FIRE!`.
- Six text rows are available per page.
- Copy should target no more than 10 characters per row, including spaces.
  Eleven may fit when narrow letters or punctuation permit it, but the actual
  enforced limit is 37 of the 40 playfield columns, leaving safe margins.
- Letter spacing is one playfield column; word spacing is three columns.
- The command-band gradient flows slowly while all lettering remains static.
- An original two-voice, percussion-free minor synth cue plays at 120 BPM.
- Chapter One explains the basic interaction explicitly. Later chapters use
  the same terminal format to identify and tease their new physical effect.

The approved Chapter One wording and renderer are maintained by
`tools/generate_terminal_briefing.py` and
`src/thursdays-child-terminal-lab.asm`.

### 5. Zone lead-in

Shown before every zone and kept deliberately brief:

- `3-4` (chapter-zone identifier)
- `STILLNESS GATE`
- Optional one-line location/status communication, never an instruction dump
- The zone's exact terrain and HUD-divider palette variation
- Fire launches immediately; automatic launch follows after a short pause

### 6. Gameplay

- Existing restrained HUD, chapter-aware divider, zone identifier, required
  Space Junk indicators, optional Space Relic indicator, and score
- No starfield: black negative space remains the production choice
- A zone ends only after all Space Junk is cleared and Major Tom enters
  the activated extraction point

### 7. Zone-clear card

- Music stops on extraction
- Short, lower-register success phrase
- A one-page NASA manifest rather than another instructional slate
- Static paper-like background built from white and gray gradient accents
- Centered red color-cycling `NASA C-S` header, where C-S is the completed
  chapter and zone number
- Left-aligned dark-blue/blue report text naming `MAJOR TOM`, confirming that
  required Space Junk was cleared, and reporting Space Relic recovery
- The approved compact objective wording is `JUNK: GONE`
- Space Relic status uses the canonical compact field `RELIC: YES` or
  `RELIC: NO`; both fit the approved ten-character line width exactly or better
  and avoid relying on a cryptic symbol
- One `SCORE 0000` field reports the cumulative powered-session score; no
  separate zone-points field is required
- Bottom transition prompt uses animated color while its letterforms remain
  stationary and clean
- Fire advances to the next Zone Lead-in, or to a Chapter Debrief after every
  fifth zone
- The manifest is related to the NASA terminal through typography and system
  voice, but its light paper/report treatment makes results immediately
  distinct from the dark-green instructional briefing

### 8. Chapter debrief/transition

- One short Ground Control/Major Tom exchange
- Chapter Space Relic subtotal
- `SIGNAL STABLE`
- `NEXT: HEAVY AIR` (or the appropriate destination)
- The outgoing palette gives way to the incoming chapter family
- Fire proceeds to the next Chapter Lead-in

### 9. Session breaks

Chapter briefings and zone manifests remain fire-gated and therefore provide
intentional rest points between zones. No password interface or additional
pause/status screen is currently planned. Turning off or resetting the console
begins a new run at Zone 1.

### 10. Finale

- Major Tom reaches a recognizable rescue craft
- Ground Control confirms successful rendezvous
- A warmer, more melodic psychedelic finale theme replaces gameplay ambience
- Final score and Space Relic total appear after the rescue tableau
- Full-relic completion adds an extra visual flourish and one additional line
  of dialogue, but the primary ending is never withheld
- The final message remains hopeful and slightly ambiguous: rescue is secured,
  but home itself is not shown
- Credits follow, then the Records screen, then the title loop

## Presentation constraints

- Gameplay raster stability and collision accuracy always outrank decoration.
- Each chapter has one coherent palette family; each zone varies that family.
- Modifier terrain uses a stable accent language that remains recognizable when
  chapter palettes change.
- Chapter and menu kernels are separate from gameplay and may use larger text,
  richer gradients, and dedicated animation without endangering physics timing.
- No password, zone-select or persistent-progress system is in scope.
- The rejected dynamic starfield does not return to the production kernel.
