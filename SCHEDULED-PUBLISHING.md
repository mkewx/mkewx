# Scheduled Publishing (optional)

## Why you need this
GitHub Pages builds when you push commits.
It does NOT rebuild automatically on a calendar schedule.

So if you upload a future-dated post and set `future: false`:
- the post stays hidden until a build happens AFTER its date.

## Two easy options

### Option 1: Manual “tiny rebuild” commit
On the publish day, make any small commit:
- edit a file (even whitespace) and push
That triggers a rebuild.

### Option 2: GitHub Actions scheduled rebuild (recommended if you want automation)
This package includes an example workflow in:

`optional/scheduled-rebuild.yml`

To enable it:
1) Create a folder: `.github/workflows/`
2) Move `optional/scheduled-rebuild.yml` into `.github/workflows/`
3) Commit + push

That workflow makes an empty commit on a schedule (daily) to trigger Pages to rebuild.
You can edit the cron time inside the file.

Note: GitHub Actions schedules use UTC.
