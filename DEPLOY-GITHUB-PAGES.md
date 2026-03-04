# Deploy to GitHub Pages (fresh repo) — Step by step

## A) The “no command line” way (recommended for beginners)

1) **Create the repo**
- Go to GitHub → New repository
- Name it something like `mkewx`
- Choose **Public** (simpler for Pages)
- Do NOT initialize with a README (we already have one in this package)
- Create repository

2) **Upload these files**
- Open your new repo
- Click **Add file → Upload files**
- Drag **everything inside this package folder** into the upload area  
  (Important: upload the contents, not the parent folder itself)
- Commit the changes

3) **Turn on GitHub Pages**
- Repo → **Settings → Pages**
- Under **Build and deployment**
  - Source: **Deploy from a branch**
  - Branch: **main**
  - Folder: **/(root)**
- Save

4) **Wait for the build**
- GitHub will show a Pages URL like:
  `https://YOURNAME.github.io/mkewx/`

5) **Test**
- Visit the Pages URL
- Try: `LISTWX`, `READ 1`, `RADAR`, `RADAR REFRESH`

---

## B) Custom domain (MKEWX.com)

1) In **Settings → Pages**, add your custom domain:
- `mkewx.com`

2) In your domain registrar DNS:
- Follow the exact records GitHub shows you in Pages settings (A/AAAA or CNAME)

3) Once DNS is correct:
- Enable **Enforce HTTPS**

---

## Important note about “future posts”
Jekyll will **hide future-dated posts** when `future: false` (this package sets that).
But GitHub Pages only rebuilds when you push a commit.

If you want future-dated posts to “go live automatically” without you logging in,
you have two choices:
- push a tiny “rebuild” commit on the day you want them to appear, OR
- use GitHub Actions to trigger rebuilds on a schedule.

See: `SCHEDULED-PUBLISHING.md` (optional).
