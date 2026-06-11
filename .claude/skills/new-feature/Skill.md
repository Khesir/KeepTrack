---
name: new-feature
description: >
  Archives the current issues/ folder and creates a fresh empty structure
  ready for a new feature cycle. Run this before starting work on a new idea.
  Everything stays local — no external services.
---

# New Feature

Archives the current `issues/` folder and creates a fresh empty structure
ready for a new feature cycle.

---

## Step 1 — Check current state

Scan `issues/` — if it is already empty or does not exist, skip to Step 3.

Check if there are any issues still in `backlog/`, `ready/`, or `in-progress/`.
If yes, warn the user:

"There are unfinished issues in [folders]. Are you sure you want to archive
and start fresh? Respond 'yes' to continue or 'no' to cancel."

Wait for their response. Do not proceed without confirmation.
If they say no, stop completely.

---

## Step 2 — Archive current issues/

Read `issues/prd.md` if it exists — extract the feature name from the PRD title.
Use it to name the archive folder: `YYYY-MM-DD-feature-name` (lowercase, hyphenated).
If no PRD exists, use `YYYY-MM-DD-unnamed`.

Create `issues/archive/` if it does not exist.

Move the entire contents of `issues/` (except the `archive/` folder itself) into:
`issues/archive/YYYY-MM-DD-feature-name/`

This includes:
- `prd.md`
- `kanban.md`
- `qa-report.md` (if exists)
- `backlog/`
- `ready/`
- `in-progress/`
- `qa/`
- `done/`

Do not move or touch `issues/archive/` itself.

---

## Step 3 — Create fresh structure

Create the following empty folders:

```
issues/
  backlog/
  ready/
  in-progress/
  qa/
  done/
```

Do not create `kanban.md` or `prd.md` — those get created by `/to-prd` and
`/to-issues`.

---

## Step 4 — Report and stop

Tell the user:
- What was archived and where: `issues/archive/YYYY-MM-DD-feature-name/`
- Fresh `issues/` structure is ready
- Next step: run `/grill-with-docs` if you want to challenge the idea against your domain model and keep `CONTEXT.md` up to date, or `/grill-me` if you just want to stress-test the plan quickly

Then stop.