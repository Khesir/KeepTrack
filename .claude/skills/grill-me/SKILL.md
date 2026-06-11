---
name: grill-me
description: >
  Load this skill when the user presents a new idea, feature, or change.
  Reads the codebase through the lens of that idea, restates understanding,
  then interviews the user relentlessly — one question at a time — until all
  design decisions are resolved. Use when the user describes an idea or mentions
  "grill me". When done, run /to-prd to synthesize into a PRD.
---

The user has presented an idea, feature, or change they want to build.

## Phase 1 — Understand

Read the codebase through the lens of this specific idea only. Do not audit the whole project.

Then present a short structured response:

**What I understand**
One short paragraph restating the idea in your own words.

**How it fits the project**
What already exists that is relevant — what the idea builds on, extends, or changes.

**One flag (only if genuinely relevant)**
A single constraint, pattern, or dependency in the codebase that directly affects this idea. Skip entirely if nothing is genuinely relevant.

Then stop and wait for the user to confirm or correct your understanding before moving to Phase 2.

---

## Phase 2 — Grill

Once the user confirms, interview them relentlessly about every aspect of the plan.

- Ask questions one at a time
- Walk down each branch of the design tree, resolving dependencies between decisions one by one
- For each question, provide your own recommended answer
- If a question can be answered by exploring the codebase, explore it instead of asking

Keep going until all decisions are resolved and nothing is ambiguous.

---

## What NOT to do

- Ask one question at a time — never batch them
- Stop before producing an implementation plan — that comes in /to-prd
- Only flag code issues that directly touch this idea — ignore everything else
- Only recommend libraries or tools the user explicitly asked about

---

## After Phase 2

Tell the user: "I think we've resolved everything. Run /to-prd when you're ready to write the PRD."
Then stop.