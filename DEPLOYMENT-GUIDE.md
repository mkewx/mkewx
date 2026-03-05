# MKE WX DEPLOYMENT GUIDE
## Step-by-Step: From ZIP to Live Website

---

## STEP 1: EXTRACT THE ZIP

Download and extract `mkewx-deploy.zip`. You'll see these files:

```
mkewx-deploy/
├── _config.yml          ← Site settings
├── _layouts/
│   ├── default.html     ← Main page (all the magic)
│   └── post.html        ← Individual post pages
├── _posts/
│   └── 2025-01-15-the-polar-vortex-chronicles.md  ← Sample post
├── index.html           ← Home page (just tells Jekyll to use default layout)
├── Gemfile              ← Ruby dependencies (GitHub Pages uses this)
├── CNAME                ← Your custom domain
├── .gitignore           ← Files Git should ignore
└── DEPLOYMENT-GUIDE.md  ← This file
```

---

## STEP 2: UPLOAD TO GITHUB

### If you already have a repository for mkewx:

1. Go to your repository on github.com
2. Delete ALL existing files (or do this locally via Git)
3. Click "Add file" → "Upload files"
4. Drag ALL the files from the extracted ZIP into the upload area
   - IMPORTANT: Upload the files INSIDE the folder, not the folder itself
   - You need `_config.yml`, `index.html`, `Gemfile`, `CNAME`, `.gitignore` at the ROOT level
   - The `_layouts/` and `_posts/` folders should be at the root too
5. Scroll down and click "Commit changes"

### If you need to create a new repository:

1. Go to github.com and click the "+" → "New repository"
2. Name it whatever you want (e.g., `mkewx`)
3. Make it Public
4. Do NOT add a README, .gitignore, or license (we have our own)
5. Click "Create repository"
6. Click "uploading an existing file"
7. Drag all the extracted files in
8. Click "Commit changes"

---

## STEP 3: ENABLE GITHUB PAGES

1. In your repository, click **Settings** (gear icon, top menu)
2. In the left sidebar, click **Pages**
3. Under "Source", select **Deploy from a branch**
4. Under "Branch", select **main** (or master) and **/ (root)**
5. Click **Save**
6. Wait 2-3 minutes for the first build

Your site will be live at: `https://yourusername.github.io/mkewx/`
(or at `https://mkewx.com` once the domain is configured)

---

## STEP 4: CUSTOM DOMAIN (mkewx.com)

### In GitHub:
- The CNAME file is already included and contains `mkewx.com`
- In Settings → Pages, type `mkewx.com` in the Custom Domain field
- Check "Enforce HTTPS" once it becomes available

### In GoDaddy (your domain registrar):
1. Go to your GoDaddy account → DNS Management for mkewx.com
2. Delete any existing A records
3. Add these 4 A records pointing to GitHub's servers:

| Type | Name | Value |
|------|------|-------|
| A | @ | 185.199.108.153 |
| A | @ | 185.199.109.153 |
| A | @ | 185.199.110.153 |
| A | @ | 185.199.111.153 |

4. Add (or update) a CNAME record:

| Type | Name | Value |
|------|------|-------|
| CNAME | www | yourusername.github.io |

(Replace `yourusername` with your actual GitHub username)

5. Save changes
6. DNS can take up to 24 hours to propagate (usually faster)

---

## STEP 5: VERIFY IT'S WORKING

1. Visit `https://mkewx.com` in your browser
2. You should see:
   - Boot sequence with amber text
   - Your posts listed below the welcome message
   - Live weather data from NWS
   - Working radar with amber sweep
   - Interactive terminal

If you see a 404 or blank page, wait 5 minutes and try again. First builds take a moment.

---

## HOW TO WRITE NEW POSTS

### The File Name Format (CRITICAL):
```
YYYY-MM-DD-your-title-in-lowercase.md
```

Examples:
- `2026-03-05-march-madness-milwaukee-style.md`
- `2026-03-06-the-bronze-fonz-issue-3.md`

The date in the filename determines when it appears on the site.

### The Post Content Format:

Every post MUST start with front matter (the stuff between the `---` lines):

```markdown
---
layout: post
title: "Your Creative Title Here"
date: 2026-03-05 06:00:00 -0600
category: weather
---

Your story text goes here. Write in plain text with Markdown formatting.

**Bold text** shows up in bright amber with glow.

*Italic text* shows up in bright amber italic.

Regular text shows in standard amber.

Separate paragraphs with a blank line between them.
```

### Category Options:
- `category: weather` — Shows "TODAY'S WEATHER" badge. Use for daily forecasts.
- `category: general` — Shows "MKE WX" badge. Use for non-forecast content (Bronze Fonz comics, Milwaukee stories, etc.)

### Formatting Tips:
- **Bold** = `**text**` (use for key weather data: temps, wind, etc.)
- *Italic* = `*text*` (use for closing lines, mood text)
- Regular paragraph = just text with blank lines between paragraphs
- No HTML needed — Markdown handles everything
- Keep posts 300-500 words
- Always include actual weather data woven into the narrative

### Example Post:

```markdown
---
layout: post
title: "Lake Effect Roulette: Place Your Bets"
date: 2026-03-05 06:00:00 -0600
category: weather
---

The dealer shuffled the clouds like a deck of cards over Lake Michigan, ready to lay down whatever hand the atmosphere dealt Milwaukee today.

**High of 34°F with a low of 22°F.** The lake was running the show, pushing bands of snow showers across the metro with the randomness of a slot machine. One block gets dusted, the next gets nothing. That's lake effect for you.

Wind out of the northeast at **15 mph, gusting to 25.** Enough to make your eyes water on the walk from the parking garage to your office.

*Keep an umbrella handy, Milwaukee. The lake is feeling generous today, and not in a good way.*
```

---

## DAILY WORKFLOW (15 minutes each morning)

1. Check weather.gov for Milwaukee's forecast
2. Pick a creative theme for today's story
3. Create a new `.md` file in the `_posts/` folder using the naming format above
4. Write your forecast story (300-500 words)
5. Commit and push to GitHub
6. GitHub Pages rebuilds automatically (takes ~2 minutes)
7. Your new post appears on mkewx.com

### Quick Way to Add Posts via GitHub.com:
1. Go to your repository
2. Click into the `_posts/` folder
3. Click "Add file" → "Create new file"
4. Name it with the correct date format
5. Paste your post content (with front matter)
6. Click "Commit new file"
7. Done! Site rebuilds automatically.

---

## TROUBLESHOOTING

**Site shows blank/404:**
- Wait 5 minutes for GitHub Pages to build
- Check Settings → Pages to confirm it's enabled
- Make sure `index.html` is at the root of your repository

**Posts not showing up:**
- Check the filename format: `YYYY-MM-DD-title.md`
- Make sure the date in the filename and front matter aren't in the future
- Verify front matter has `layout: post` and a valid `category`

**Weather data not loading:**
- NWS API occasionally has brief outages. Wait and refresh.
- The site shows "Data temporarily unavailable" during outages

**Radar not loading:**
- RainViewer API needs an internet connection
- If tiles fail to load, click REFRESH DATA

**Custom domain not working:**
- DNS changes take up to 24 hours
- Verify your GoDaddy A records match the IPs above
- Make sure CNAME file exists in your repository root

---

## WHAT'S IN THIS BUILD

- NWS API for weather (free, no API key, no exposed secrets)
- RainViewer API for radar (free, no API key, CORS-friendly)
- Multi-tile radar with proper geographic alignment
- Pixel-level amber conversion for radar data
- Circular radar display with sweep animation
- NWS alerts with typing ticker animation
- Moon phase calculator (mathematical, always accurate)
- Interactive terminal with Milwaukee-themed commands
- Boot sequence with randomized messages
- Audio feedback (beeps on commands and story clicks)
- Responsive design (works on mobile and desktop)
- Jekyll pagination (4 posts per page)
- Automatic RSS feed generation
- Sunrise/sunset times from sunrise-sunset.org API

Built with Opus. Made with ♥ for the 414.
