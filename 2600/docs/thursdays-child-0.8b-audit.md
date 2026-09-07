# Thursday's Child 0.8B — Chapter One Music Audit

## Scope

0.8B adds the Chapter One production music template without changing the
approved 0.8A sound effects, picture, physics, HUD, objects, terrain, or stage
transition. Stage 1 and Stage 2 intentionally share this chapter theme.

## Composition

- Approximately 34 seconds before repetition: 8 phrases × 8 positions ×
  32 frames per position at 60 Hz.
- Deliberate A minor → F major → C major → G major progression.
- Each chord receives an initial motif and a rhythmically varied answer.
- No chromatic ornamentation is used; every divider belongs to the selected
  chord vocabulary to avoid the random or off-key quality of earlier drafts.
- Lead dividers are restricted to 6–14. The abrasive 4–5 upper-register notes
  from the first 0.8B draft have been removed.
- Channel 0 alone carries the complete performance using the rounded `AUDC=12`
  divided-pure timbre. Main notes, silence, lower-octave ghosts, and longer
  rests occur sequentially; music voices never overlap.
- Each ghost follows its main note at the literal lower octave, computed by
  the verifier as `ghost=(main×2)+1`.
- The lead peaks at TIA volume 2. The shorter echo peaks at volume 1.

## Lifecycle and effects

- Music advances continuously during ordinary play.
- Channel 1 is reserved exclusively for gameplay effects. When an effect owns
  it, Channel 0 music is fully ducked, keeping every cue intelligible.
- The score resumes at the current musical position after a short effect.
- Music stops when the extraction gate is entered.
- Stage completion uses a separate low A-minor rise-and-return phrase at a
  maximum TIA volume of 4; it never enters the general volume-9 effect path.
- Stage 2 resets the phrase and frame clocks, restarting the Chapter One theme.
- Later chapters can select separate 64-position table pairs without changing
  the renderer or sound-effect engine.

## Memory and timing

- Music consumes no additional RAM byte. Phrase 0–7 occupies unused upper bits
  of `requiredCount`; its low two bits remain the required-object count 0–3.
- The packed sound-effect state remains at `$E8`.
- `$F5–$FF` remain reserved for the 6502 call stack.
- All audio code and data remain in non-visible Bank 0.
- The fixed `$FFD3` physics call and Bank 7 `$FFD9` return are unchanged.

## Verification

`make verify-thursday` passes the F4 map, both assembled-ROM raster traces,
motion, object safety, all six effects, the 64-position monophonic score, exact
sequential-octave relationship, authored rests, envelope bounds, strict channel
ownership, ducking, completion silence, packed-RAM safety, and fixed-bank return
checks. Both room kernels retain 74-cycle longest visible paths and the NTSC
frame remains 262 scanlines.

## Build identity

- Source SHA-256: `39c5e3bf20a89f086d0625554b35bf0804bddf24a21fb77b2ab78dbdc62249fb`
- ROM SHA-256: `563d0f308fd130e5a7dd5c9da4fca32ab100f3459e850fa1e098f7c59fab933d`
