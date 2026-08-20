# Keep Track — Finance Domain

Zero-based budgeting app. Users plan monthly (or profile-scoped) budgets made of expense/income groups, and separately track Subscriptions, Debts, and Goals.

## Language

**Budget Category**:
A single planned line item inside a Budget group — a target amount tied to a FinanceCategory. Recreated as a brand-new row (new id) every month via "copy from previous month" — never carried forward by reference.
_Avoid_: Category, line item (when precision matters)

**Category Link**:
An optional pointer from a Budget Category to one specific Subscription, Debt, or Goal, marking that line item as tracking a real recurring commitment rather than a free-form spending bucket. Lives on the Budget Category, not on the linked entity — because Budget Categories are recreated every month while Subscriptions/Debts/Goals persist, so the link must be copied forward each month (alongside the copy-from-previous-month logic) rather than the entity holding one single, eventually-stale pointer back.
_Avoid_: storing the pointer on Subscription/Debt/Goal (the dead `Subscription.budgetCategoryId` field is exactly this mistake — to be removed, not reused)

**Linked spend**:
For a Budget Category with a Category Link, "spent" is computed by matching the linked entity's id (`subscriptionId`/`debtId`/`goalId`) on each Transaction — not the category-wide `financeCategoryId` match that plain (unlinked) categories still use. Scoped fix: only linked categories get the precise calculation; unlinked categories keep today's behavior (and today's known double-count risk when a `FinanceCategory` is reused across groups) untouched.

**Link uniqueness**:
An entity (Subscription/Debt/Goal) may be linked to at most one Budget Category within a given month/budget snapshot. The entity picker excludes entities already linked elsewhere in that month, rather than allowing the conflict and warning about it — this also protects the Linked spend calculation from double-counting the same transactions into two categories.

**Add Category entry point**:
`AddCategorySheet` presents two top-level choices — "Category" (today's existing name + planned amount form, unchanged) and "Link" (picks an existing Subscription/Debt/Goal via the entity picker, auto-filling the target amount per Linked spend rules). A Budget Category is one or the other, never both.

**Linked entity status tag**:
A linked Budget Category always reflects the linked entity's *current* status as a visible tag (e.g. "Settled", "Cancelled", "Completed") rather than hiding, graying out, or otherwise shadowing the category — a fully-paid Debt this month still shows, just tagged "Paid"/"Settled". `BudgetCategory` snapshots the entity's name at link time (e.g. `linkedEntityLabel`) so the row still displays correctly even in the rare case the entity is hard-deleted, not just status-changed — in that case it shows the last-known name with no status tag.

**Editing a link**:
Editing a linked Budget Category offers "Change link" (re-opens the entity picker to point at a different Subscription/Debt/Goal) and "Unlink" (drops the link, falls back to a plain category — prompting for a `FinanceCategory` name if it doesn't have one). "Delete" still removes the whole category row, same as today, regardless of link state.

**Linked badge (reverse indicator)**:
On the Subs/Debts/Goals pills, a row whose entity is linked to a Budget Category this month shows a "Linked" badge — so the relationship is discoverable from either direction (from the budget category, and from the entity's own list).

**Debt type vs. budget side**:
A `Debt` with `DebtType.borrowing` (money you owe) links into an **Expense** Budget Category. A `Debt` with `DebtType.lending` — the **Receivable** (money owed to you) — links into an **Income** Budget Category. Subscriptions and Goal contributions always link into Expense categories, even though a Goal contribution's underlying Transaction is recorded as `TransactionType.income` at the wallet-transfer level — the budget-side classification and the transaction-side mechanics are answering different questions and are allowed to disagree.
