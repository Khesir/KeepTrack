---
name: to-issues
description: >
  Break a plan, spec, or PRD into independently-grabbable local issue files
  using tracer-bullet vertical slices. Maintains issues/kanban.md as the
  overview board. Use when user wants to convert a plan into issues, create
  implementation tickets, or break down work. Everything stays local — no
  external services.
---

# To Issues

Break a plan into independently-grabbable local issue files using vertical slices (tracer bullets).

## Process

### 1. Gather context

Read `issues/prd.md` in full. If it does not exist, stop and tell the user to run /to-prd first.

If the user passes a specific file or reference as an argument, read that instead.

### 2. Explore the codebase (optional)

If you have not already explored the codebase, do so to understand the current state of the code. Issue titles and descriptions should use the project's domain glossary vocabulary, and respect ADRs in the area you're touching.

### 3. Draft vertical slices

Break the plan into **tracer bullet** issues. Each issue is a thin vertical slice that cuts through ALL integration layers end-to-end — NOT a horizontal slice of one layer.

Slices may be **HITL** or **AFK**:
- **HITL** — requires human interaction (architectural decision, design review, etc.)
- **AFK** — can be implemented and merged without human interaction

Prefer AFK over HITL where possible.

<vertical-slice-rules>
- Each slice delivers a narrow but COMPLETE path through every layer (schema, API, UI, tests)
- A completed slice is demoable or verifiable on its own
- Prefer many thin slices over few thick ones
</vertical-slice-rules>

### 4. Quiz the user

Present the proposed breakdown as a numbered list. For each slice, show:

- **Title**: short descriptive name
- **Type**: HITL / AFK
- **Priority**: P1 (nothing works without it) / P2 (after P1) / P3 (anytime, lower impact)
- **Blocked by**: which other slices must complete first (if any)
- **User stories covered**: which user stories this addresses (if the PRD has them)

Ask the user:

- Does the granularity feel right? (too coarse / too fine)
- Are the dependency relationships correct?
- Should any slices be merged or split further?
- Are the correct slices marked as HITL and AFK?

Iterate until the user approves the breakdown.

### 5. Set up the folder structure

Create any of these that do not already exist:

```
issues/
  backlog/
  ready/
  in-progress/
  qa/
  done/
```

Find the highest existing issue number across all folders to continue numbering correctly. If no issues exist yet, start from 001.

### 6. Write the issue files

Place each file in the correct starting folder:
- No blockers → `issues/ready/`
- Has blockers → `issues/backlog/`

Name each file: `NNN-short-name.md` (zero-padded number, lowercase hyphenated name).

Publish issues in dependency order (blockers first) so you can reference real issue numbers in the "Blocked by" field.

Use this template:

<issue-template>

# [NNN] [Issue Title]

**Type:** HITL / AFK
**Priority:** P1 / P2 / P3
**Blocked by:** None / [list issue numbers e.g. 001, 002]
**User stories covered:** [list from PRD, or omit if none]

---

## What to build

A concise description of this vertical slice. Describe the end-to-end behavior, not layer-by-layer implementation.

Avoid specific file paths or code snippets — they go stale fast. Exception: if a prototype produced a snippet that encodes a decision more precisely than prose can (state machine, reducer, schema, type shape), inline it here and note briefly that it came from a prototype. Trim to the decision-rich parts — not a working demo, just the important bits.

---

## Acceptance criteria

- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

---

## Tests required

Yes / No — [what to test if yes, taken from PRD testing decisions]

---

## Notes

Anything relevant from the PRD: constraints, patterns to follow, decisions already made.

---

## Log

_Updated as work progresses._

</issue-template>

### 7. Write the Kanban board

Write `issues/kanban.md` by scanning the actual folder contents. Always reflect what is physically in each folder — never hardcode.

<kanban-template>

# Kanban Board

_Last updated: [date]_

---

## Backlog
Issues with unresolved blockers.

| Issue | Title | Type | Priority | Blocked by |
|-------|-------|------|----------|------------|
| [001](backlog/001-name.md) | [Title] | AFK | P1 | 002 |

---

## Ready
No blockers. Ready to be picked up.

| Issue | Title | Type | Priority |
|-------|-------|------|----------|
| [002](ready/002-name.md) | [Title] | AFK | P1 |

---

## In Progress
Currently being implemented.

| Issue | Title | Type | Priority |
|-------|-------|------|----------|

---

## QA
Implementation done. Tests pass. Waiting for review.

| Issue | Title | Type | Priority |
|-------|-------|------|----------|

---

## Done
Approved and complete.

| Issue | Title | Type | Priority |
|-------|-------|------|----------|

</kanban-template>

### 8. Report and stop

Tell the user:
- How many issues were created
- Which ones are in `ready/` (can start now)
- Which ones are in `backlog/` (blocked)
- Where the Kanban board is

Then stop. Do not begin implementation.