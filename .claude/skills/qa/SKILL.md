---
name: qa
description: >
  Runs automated QA on all issues in issues/qa/ and generates a visual QA
  checklist for everything that requires human eyes. Does not move issues to
  done/ — that is the user's job after visual review via /qa-approve and
  /qa-reject.
---

# QA

Runs automated QA on all issues in `issues/qa/` and generates a visual QA
checklist for everything that requires human eyes.

## Before starting

Scan `issues/qa/` — if empty, stop and tell the user there is nothing to QA.

Read every issue file in `issues/qa/` before doing anything.

Also check for `CONTEXT.md` (or `UBIQUITOUS_LANGUAGE.md` if it exists). Load
the domain language — all findings and report descriptions must use the
project's domain terms, not internal module names or implementation details.

---

## Phase 1 — Automated QA (per issue)

For each issue in `issues/qa/`, run the following in order. Do not skip any
step. Report results per issue.

### Step 1 — Build check

Run the project build. If it fails, stop automated QA for that issue
immediately and flag it.

### Step 2 — Test suite

Run all tests. Report: passed, failed, skipped. If any tests fail, flag the
issue.

Then verify test quality against the following — flag any violation:

**Tests required check**
Read the issue's `Tests required` field. If it says `Yes`, verify that tests
were actually written for the behaviors described there — not just that the
suite passes. A passing suite with no new tests for this issue's behavior is
a failure.

**Test quality check**
Read the tests written for this issue. Flag any that show these bad patterns:
- Mocking internal collaborators (only system boundaries should be mocked —
  external APIs, third-party services, time, randomness)
- Testing private methods or internal functions directly
- Asserting on call counts or execution order rather than observable behavior
- Test name describes HOW not WHAT (e.g. "calls paymentService.process"
  instead of "user can checkout with valid cart")
- Bypassing the public interface to verify via database queries, internal
  state, or side effects

Good tests use public interfaces only, describe behavior not implementation,
and would survive an internal refactor without changing.

**Bug regression check**
If the issue contains a `## Bug` section (returned from QA rejection), verify
that a failing test reproducing that bug was written before the fix. If no
such test exists, flag it — the bug can regress silently.

### Step 3 — Lint check

First, discover what linter is configured by checking the project root for:

| File | Linter | Command |
|------|--------|---------|
| `package.json` scripts or `.eslintrc*` | ESLint | `npm run lint` or `npx eslint .` |
| `pyproject.toml`, `ruff.toml`, `.flake8` | Ruff / Flake8 | `ruff check .` or `flake8` |
| `Cargo.toml` | Clippy | `cargo clippy` |
| `.golangci.yml` or `golangci-lint` in PATH | golangci-lint | `golangci-lint run` |
| `Makefile` with a `lint` target | Project-defined | `make lint` |
| `.clang-tidy` or `CMakeLists.txt` | clang-tidy | `clang-tidy` |

If no linter configuration is found, skip this step and note in the report:
"No linter configured — skipped." Do not invent or assume a linter.

If a linter is found, run it. Report any new errors or warnings introduced by
this issue's changes. Ignore pre-existing lint issues that were there before
this issue.

### Step 4 — Code review

Read the implementation files touched by this issue. Check for:

- Follows existing patterns in the codebase
- No shortcuts or hacks that defer problems
- No scope creep — only what the issue required was changed
- No dead code, commented-out blocks, or console.logs left behind
- Naming is clear and consistent with the rest of the codebase
- No obvious performance or security concerns

**When reporting findings, describe behaviors not code.** Do not reference
specific file paths, line numbers, or function names — these go stale. Describe
what the system does or fails to do from a user or domain perspective.

Report findings honestly. Flag anything that needs attention.

### Step 5 — Acceptance criteria check

Read the issue's acceptance criteria. For each criterion, verify whether it is
provably met by the code and tests.

Mark each one: ✅ verified by code / 👁 needs visual check / ❌ not met

### Step 6 — Assess scope of failures

Before moving on, decide whether failures in this issue represent a **single
rejection** or need to be **flagged as multiple independent problems**.

Flag as multiple when:
- The failures span independent areas that could be fixed in parallel
- There are clearly separable concerns with different root behaviors
- One failure does not depend on another being fixed first

Keep as a single rejection when:
- All failures stem from the same root behavior
- Fixing one would likely resolve the others

Note blocking relationships honestly — if one problem can't be verified until
another is fixed, say so explicitly in the report.

---

## Phase 2 — Visual QA checklist (per issue)

For every acceptance criterion marked 👁 needs visual check, and for any
UI-related description in the issue, generate a specific checklist item.

Be specific — not "check the UI looks right" but exactly what to look at,
where to find it, and what it should look like or do. Use domain language
throughout — not component names or file names.

Use this template per issue:

<visual-qa-template>

## Visual QA — [NNN] [Issue Title]

| # | What to check | Where | Expected |
|---|--------------|-------|----------|
| 1 | [Specific behavior or interaction] | [Where in the product] | [Exactly what you should see or happen] |
| 2 | [Specific behavior or interaction] | [Where in the product] | [Exactly what you should see or happen] |

**Edge cases to manually test:**
- [ ] [Specific edge case]
- [ ] [Specific edge case]

</visual-qa-template>

---

## Phase 3 — QA Report

After running automated QA on all issues, produce a single report:

<qa-report-template>

# QA Report

_Date: [date]_

---

## Automated QA Results

| Issue | Title | Build | Tests Pass | Test Quality | Lint | Code Review | Result |
|-------|-------|-------|------------|--------------|------|-------------|--------|
| [001](qa/001-name.md) | [Title] | ✅ / ❌ | ✅ / ❌ | ✅ / ⚠️ / ❌ | ✅ / ❌ | ✅ / ⚠️ | Pass / Fail |

---

## Issues with automated failures

List any issues that failed automated QA. For each, describe:

- What failed — in plain behavioral language, no file paths or line numbers
- Whether this is one problem or multiple independent problems
- Blocking relationships — if one problem must be fixed before another can be verified, say so

These need to be fixed before visual review. Do not include them in the visual
QA checklist below.

---

## Visual QA Checklist

[Insert visual QA tables here — one per issue that passed automated QA]

---

## How to sign off

For each issue you visually verify:
- Approved → run `/qa-approve [issue number]`
- Something is wrong → run `/qa-reject [issue number] [what you saw]`

</qa-report-template>

Write the report to `issues/qa-report.md`. Tell the user the report is ready
and where it is. Then stop — visual QA and sign-off is the user's job.

---

## What NOT to do

- Do not move any files — that is /qa-approve and /qa-reject's job
- Do not fix anything you find — flag it, report it, stop
- Do not mark issues as done
- Do not skip the code review step even if tests pass
- Do not reference file paths, line numbers, or function names in findings — describe behaviors only