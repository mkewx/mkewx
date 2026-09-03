# [Working Title]

Atari 2600 game project. Lives in this repo as an isolated subfolder — excluded from the
Jekyll build (`_config.yml`), so nothing here touches the live mkewx.com site.

## Layout

- `src/` — assembly (or batari Basic) source. The actual game.
- `docs/` — design docs: what the game is supposed to be, current known issues,
  decisions made and why.
- `reference/` — art/style inspiration (small images, palettes, links). Not game assets.
- `build/` — gitignored. Assembled `.bin`/`.lst`/`.sym` output, regenerated from `src/`.

ROMs aren't committed as source — they're a build artifact of whatever's in `src/`.
