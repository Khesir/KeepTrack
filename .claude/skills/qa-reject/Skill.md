# qa-reject

Called when the user finds something wrong during visual QA.
Appends the bug details to the issue file itself and moves it back to ready/.
No new file is created — the issue carries its own bug.

Usage: /qa-reject [issue number] [what you saw]
Example: /qa-reject 003 drawer animation is jumpy on mobile

---

## Steps

1. Find the file matching the issue number in `issues/qa/`
   If it does not exist there, stop and tell the user.

2. Append a Bug section to the issue file:

<bug_section_template>

## Bug

**Reported:** [date]
**Found during:** Visual QA
**Description:** [what the user described]

### What to fix
_To be investigated during implementation._

### Acceptance Criteria
- [ ] Bug no longer reproduces
- [ ] Original acceptance criteria still met
- [ ] A test exists that would have caught this

</bug_section_template>

3. Append to the issue file's Log section:
   `QA rejected on [date]. Bug appended — [what the user described].`

4. Physically move the file from `issues/qa/` back to `issues/ready/`

5. Update `issues/kanban.md`:
   - Move the issue from QA back to Ready
   - Update _Last updated_ date

6. Tell the user:
   - Issue NNN moved back to ready/ with bug details appended
   - Run /implement-issues to pick it up

Then stop.