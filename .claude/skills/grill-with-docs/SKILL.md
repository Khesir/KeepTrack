---
name: grill-with-docs
description: >
  Load this skill when the user presents a new idea, feature, or change.
  Reads the codebase through the lens of that idea, restates understanding,
  then interviews the user relentlessly — one question at a time — challenging
  against the existing domain model, sharpening terminology, and updating
  CONTEXT.md and ADRs inline as decisions crystallise. Use when the user
  describes an idea or mentions "grill me". When done, run /to-prd.
---

The user has presented an idea, feature, or change they want to build.

## Phase 1 — Understand

Read the codebase through the lens of this specific idea only. Do not audit the whole project. Also look for existing documentation:

**File structure (single context):**
```
/
├── CONTEXT.md
├── docs/
│   └── adr/
└── src/
```

**File structure (multiple contexts):**
```
/
├── CONTEXT-MAP.md
├── docs/
│   └── adr/                          ← system-wide decisions
├── src/
│   ├── ordering/
│   │   ├── CONTEXT.md
│   │   └── docs/adr/
│   └── billing/
│       ├── CONTEXT.md
│       └── docs/adr/
```

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

- Ask questions one at a time, waiting for feedback before continuing
- Walk down each branch of the design tree, resolving dependencies between decisions one by one
- For each question, provide your own recommended answer
- If a question can be answered by exploring the codebase, explore it instead of asking

### Challenge against the glossary

When the user uses a term that conflicts with the existing language in `CONTEXT.md`, call it out immediately. "Your glossary defines 'cancellation' as X, but you seem to mean Y — which is it?"

### Sharpen fuzzy language

When the user uses vague or overloaded terms, propose a precise canonical term. "You're saying 'account' — do you mean the Customer or the User? Those are different things."

### Discuss concrete scenarios

When domain relationships are being discussed, stress-test them with specific scenarios. Invent scenarios that probe edge cases and force the user to be precise about the boundaries between concepts.

### Cross-reference with code

When the user states how something works, check whether the code agrees. If you find a contradiction, surface it: "Your code cancels entire Orders, but you just said partial cancellation is possible — which is right?"

### Update CONTEXT.md inline

When a term is resolved, update `CONTEXT.md` right there. Don't batch these up — capture them as they happen. Use the format in [CONTEXT-FORMAT.md](./CONTEXT-FORMAT.md).

`CONTEXT.md` should be totally devoid of implementation details. It is a glossary and nothing else — not a spec, not a scratch pad, not a repository for implementation decisions.

Create files lazily — only when you have something to write. If no `CONTEXT.md` exists, create one when the first term is resolved. If no `docs/adr/` exists, create it when the first ADR is needed.

### Offer ADRs sparingly

Only offer to create an ADR when all three are true:

1. **Hard to reverse** — the cost of changing your mind later is meaningful
2. **Surprising without context** — a future reader will wonder "why did they do it this way?"
3. **The result of a real trade-off** — there were genuine alternatives and you picked one for specific reasons

If any of the three is missing, skip the ADR. Use the format in [ADR-FORMAT.md](./ADR-FORMAT.md).

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