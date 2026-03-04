# Writing Dispatches (Stories) — the MKEWX workflow

Your dispatches live in `_posts/` as Markdown files.

## 1) File naming
Jekyll uses this format:

`YYYY-MM-DD-title-slug.md`

Example:
`2026-02-20-lake-effect-confidential.md`

## 2) Front matter (required)
Every dispatch starts with YAML front matter:

```yaml
---
layout: post
title: Lake Effect Confidential
date: 2026-02-20 06:10:00 -0600
style: Noir Script
---
```

- `layout: post` makes it render in the terminal look
- `style:` is your “story flavor” label (NOIR SCRIPT / FAIRYTALE / etc.)
- `date:` controls ordering and (optionally) future scheduling

## 3) Excerpts (what shows on the homepage list)
This package uses:

`excerpt_separator: "<!--more-->"`

So write a short hook paragraph, then add:

`<!--more-->`

Everything before that becomes the homepage preview.

## 4) “Scheduling” reality check on GitHub Pages
If you future-date a post and keep `future: false`, it won’t show until:
- GitHub Pages rebuilds AFTER the post date

GitHub Pages doesn’t rebuild on its own.
See `SCHEDULED-PUBLISHING.md` for easy automation options.
