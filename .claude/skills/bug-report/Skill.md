---
name: bug-report
description: >
  The user has described something that went wrong. Explores the codebase,
  validates the bug, suggests reproduction steps, gets user confirmation, then
  writes the bug report and places it in issues/ready/. Use when the user
  describes a bug or something broken. Everything stays local — no external
  services.
---

# Bug Report

The user has described something that went wrong during QA or use.
Your job is to explore the codebase, validate the bug, suggest reproduction
steps, get user confirmation, then write the bug report and place it in
`issues/ready/`.

Bugs have no blockers by definition — they go straight to `ready/`.
Do not write the bug file until the user approves.
Do not fix anything. Do not suggest fixes.

---

## Before starting

Check for `CONTEXT.md` (or `UBIQUITOUS_LANGUAGE.md` if it exists). Load the
domain language — all findings and the bug report itself must use the project's
domain terms, not internal module names or implementation details.

---

## Phase 1 — Set up folders

Ensure these exist, create any that are missing:

```
issues/
  backlog/
  ready/
  in-progress/
  qa/
  done/
```

---

## Phase 2 — Explore and validate

Read the user's description carefully. Then read the relevant parts of the
codebase — trace the code path related to what they described.

Look for:
- Where the failure likely originates
- What the code is actually doing vs what it should do
- Any obvious related code that could be involved

Report back using domain language — describe behaviors, not code. Do not
reference specific file paths, line numbers, or function names in your
findings. Describe what the system does or fails to do from a user or domain
perspective.

Include your confidence level: certain / likely / uncertain.

If you cannot find anything relevant, say so honestly. Do not guess.

---

## Phase 3 — Reproduction steps

Based on what you found, propose clear reproduction steps using domain
language.

<reproduction-steps>

1. [Exact action in domain terms]
2. [Exact action in domain terms]
3. [What you observe]
4. [What you expected instead]

</reproduction-steps>

Ask the user: "Does this match what you experienced? Can you reproduce it with
these steps?"

Wait for their response. Do not proceed until they confirm.

---

## Phase 4 — User approval

Once the user confirms the reproduction steps, ask:
"Should I create the bug report?"

Wait for explicit approval. Do not create the file without it.

---

## Phase 5 — Write the bug report

Find the next available number by scanning all files across all `issues/`
folders. Place the file in `issues/ready/`.

Name the file: `NNN-short-description.md`

Use this template:

<bug-template>

# [NNN] [Short Bug Title]

**Type:** AFK
**Priority:** P1 / P2 / P3
**Blocked by:** None

---

## Description

What is broken, described as a behavior failure from the user's perspective.
Use domain language — no file paths, function names, or implementation details.

---

## Steps to reproduce

1. [Exact action in domain terms]
2. [Exact action in domain terms]
3. [Observed result]

**Expected:** [What should have happened]
**Actual:** [What happened instead]

---

## Acceptance criteria

- [ ] Bug no longer reproduces following the steps above
- [ ] Existing tests still pass
- [ ] A test exists that would have caught this bug

---

## Tests required

Yes — write a failing test that reproduces the bug before writing any fix.

---

## Notes

Any additional context, edge cases, or related areas to watch.

---

## Log

_Updated as work progresses._

</bug-template>

---

## Phase 6 — Update the Kanban board

Add the bug to `issues/kanban.md` under the Ready column.
Update the _Last updated_ date.

Tell the user:
- Bug file created at `issues/ready/NNN-short-description.md`
- Added to the Kanban board under Ready
- Run /implement-issues to pick it up

Then stop.