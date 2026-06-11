---
name: review
description: >
  Review accumulated changes since a fixed point along two axes — Standards
  (does the code follow this repo's documented coding standards?) and Spec
  (does the code match issues/prd.md and the originating issue files?). Runs
  both reviews in parallel sub-agents and reports them side by side. Use when
  the user wants a holistic check after accumulating several issues, before
  running /qa on a batch, or at a milestone boundary. Always user-triggered —
  never automatic.
---

# Review

Two-axis review of the diff between `HEAD` and a fixed point the user supplies:

- **Standards** — does the code conform to this repo's documented coding standards?
- **Spec** — does the code faithfully implement what `issues/prd.md` and the originating issue files asked for?

Both axes run as **parallel sub-agents** so they don't pollute each other's
context, then this skill aggregates their findings.

---

## When to run this

This skill is optional and user-triggered. Reach for it when:

- Several issues have moved to `qa/` or `done/` and you want a holistic check
  before the final QA pass
- You've been working on a feature long enough that drift from the PRD is
  plausible
- Something feels off across multiple issues and you want a clean diff-vs-PRD
  check
- You're at a milestone boundary and want a final "does this still match what
  we planned?" sanity check

Do not run this automatically on every issue — that's `/qa`'s job.

---

## Process

### 1. Pin the fixed point

Whatever the user said is the fixed point — a commit SHA, branch name, tag,
`main`, `HEAD~5`, etc. If they didn't specify one, ask:
"Review against what — a branch, a commit, or `main`?"

Don't proceed until you have it.

Capture the diff once: `git diff <fixed-point>...HEAD` (three-dot, comparison
against the merge-base). Also note commits via
`git log <fixed-point>..HEAD --oneline`.

### 2. Load the spec

Read both:

- `issues/prd.md` — the original problem statement, solution, user stories,
  implementation decisions, and testing decisions
- All issue files touched by the commits in this diff — scan commit messages
  for issue numbers (e.g. `#003`, `003`, `closes 003`) and read the
  corresponding files from whichever `issues/` folder they're in

If `issues/prd.md` does not exist, note it in the report and have the Spec
sub-agent work from issue files only. If no issue files can be identified,
ask the user which issues this work covers.

### 3. Load the standards sources

Check for anything in the repo that documents how code should be written:

- `CLAUDE.md`, `AGENTS.md`
- `CONTRIBUTING.md`
- `CONTEXT.md` or per-context `CONTEXT.md` files (domain language is a standard)
- `docs/adr/` — architectural decisions are standards
- `.editorconfig`, linting configs (`eslint.config.*`, `ruff.toml`, `biome.json`, etc.), `tsconfig.json` — note these but don't re-check what tooling already enforces
- Any `STYLE.md`, `STANDARDS.md`, or `STYLEGUIDE.md` at the root or under `docs/`

Collect the list. The Standards sub-agent will read them.

### 4. Spawn both sub-agents in parallel

**Standards sub-agent prompt — include:**

- The full diff command and commit list
- The list of standards-source files found in step 3
- The brief: "Read the standards docs. Then read the diff. Report — per file or hunk where relevant — every place the diff violates a documented standard. Cite the standard and the rule. Distinguish hard violations from judgment calls. Use the project's domain language throughout. Skip anything tooling already enforces. Under 400 words."

**Spec sub-agent prompt — include:**

- The diff command and commit list
- The contents of `issues/prd.md` and the relevant issue files
- The brief: "Read the PRD and issue files. Then read the diff. Report: (a) requirements the PRD or issues asked for that are missing or partial; (b) behavior in the diff that wasn't asked for — scope creep; (c) requirements that look implemented but where the implementation looks wrong. Reference the PRD section or issue number for each finding. Use the project's domain language throughout. Under 400 words."

### 5. Aggregate and report

Present the two reports under `## Standards` and `## Spec` headings, verbatim
or lightly cleaned. Do **not** merge or rerank findings — the two axes are
deliberately separate so the user can see them independently.

End with:
- A one-line summary: total findings per axis and the worst single issue if any
- A recommendation: ready for `/qa`, or address findings first

---

## Why two axes

A change can pass one axis and fail the other:

- Code that follows every standard but drifts from the PRD → **Standards pass, Spec fail**
- Code that implements everything asked but breaks project conventions → **Spec pass, Standards fail**

Reporting them separately stops one axis from masking the other. Per-issue
`/qa` catches issues in isolation — this catches drift that's only visible
at the feature level.