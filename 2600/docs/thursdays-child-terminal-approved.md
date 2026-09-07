# Thursday's Child — approved pre-chapter terminal template

## Status

Approved as the production presentation template for every pre-chapter screen.
The current standalone implementation introduces Chapter One.

## Visual contract

- Faux NASA computer-terminal presentation.
- Full-screen dark green phosphor gradient for Chapter One.
- Large yellow block lettering generated as fixed asymmetric-playfield art.
- One playfield column between letters and three between words.
- Six text rows per page.
- Nominal maximum: 10 characters per row, including spaces.
- Conditional maximum: 11 characters when narrow glyphs or punctuation keep
  the rendered line within 37 playfield columns.
- A generator error rejects copy wider than the safe raster area.
- `MORE...` appears in the bottom band on intermediate pages; `FIRE!` appears
  on the final page.
- Only the bottom gradient flows. Main text and background geometry stay fixed.
- No character portrait or decorative sprite is used.

## Audio contract

- Original two-voice minor-key synth cue at approximately 120 BPM.
- No percussion.
- Upper arpeggio and lower pulse use restrained TIA volume.
- Every note contains a short silent tail to prevent continuous buzzing.
- Music continues across briefing pages.

## Chapter One copy

Page 1:

```text
NASA
CONTROL TO
MAJOR TOM:
WE WILL USE
SATELLITES
FOR ORBIT.
```

Page 2:

```text
PLAYER:
PRESS FIRE
TO ENABLE
SATELLITES
FROM NASA
TERMINAL
```

Page 3:

```text
CHAPTER
ONE: LEARN
HOW MAJOR
TOM MOVES.
SPACE GETS
TRICKIER...
```

## Canonical files

- Renderer: `src/thursdays-child-terminal-lab.asm`
- Generated artwork: `src/thursdays-child-terminal-lab.inc`
- Text/art generator: `tools/generate_terminal_briefing.py`
- Build targets: `make terminal-lab` and `make verify-terminal-lab`
- Approved ROM snapshot: `outputs/thursdays-child-chapter-terminal-1.0-approved.bin`

The actual attract/title screen is intentionally not defined by this template.
