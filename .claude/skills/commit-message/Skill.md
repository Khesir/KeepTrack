# commit-message

Reads the current changes and recently completed issues, then writes a clean
commit message as raw text for the user to copy into GitHub Desktop.

No git commands. No automation. Raw text only.

---

## Step 1 — Read the context

Read `issues/kanban.md` to see what was just completed.
Read any issue files that recently moved to `done/` — check their Log sections
to understand what was implemented.

If there are no recently completed issues, read the changed files directly
and infer what was done from the code.

---

## Step 2 — Write the commit message

Follow the Conventional Commits format:

```
type(scope): short summary in imperative mood

- What was changed and why (one line per meaningful change)
- Another change if relevant
- Keep each line under 72 characters
```

**Types:**
- `feat` — new feature
- `fix` — bug fix
- `refactor` — code change that neither fixes a bug nor adds a feature
- `test` — adding or updating tests
- `chore` — build, config, or tooling changes
- `docs` — documentation only

**Rules:**
- Summary line: max 50 characters, no period at the end
- Imperative mood: "add feature" not "added feature"
- Body lines: max 72 characters each
- If multiple types apply, use the most significant one
- Do not mention file names in the summary — describe what changed, not where
- Do not pad with filler like "various improvements"

---

## Step 3 — Output

Print the commit message as a plain text block the user can copy.
Nothing else around it — no explanation, no "here is your commit message".
Just the raw text.

If there are multiple logical groups of changes that should be separate commits,
write them as separate blocks and label each one clearly:

```
--- Commit 1 ---
[message]

--- Commit 2 ---
[message]
```

Then stop.