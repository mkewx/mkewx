# Thursday's Child

Atari 2600 game project. Lives in this repo as an isolated subfolder — excluded from the
Jekyll build (`_config.yml`), so nothing here touches the live mkewx.com site.

**Start with `CLAUDE_HANDOFF.md`** — it has the current project state, what's approved
vs. experimental, and the active bug.

## Layout

- `code/current/` — latest development source (may not build/run correctly).
- `code/approved-checkpoints/` — known-good, user-playtested source. Treat as immutable
  unless a regression test proves an experimental change is byte-for-byte equivalent.
- `code/experimental/` — preserved candidates, explicitly not approved.
- `binaries/approved/` — user-playtested ROM builds.
- `binaries/experimental/` — latest builds that may be broken; evidence, not releases.
- `docs/` — design docs, audits, regression notes.
- `graphics/` — TIA asset/layout notes and reference captures.
- `tools/` — verification/analysis scripts (Python) used by the Makefile's `make verify-*`.
- `build/` — gitignored. Scratch output from our own assemble/emulate/verify runs.
