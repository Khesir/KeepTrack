# CategoryDetailSheet name is reused across two unrelated sheets

While splitting `budget_simple_sheets.dart` (Candidate 2 of the architecture
review), a `CategoryDetailSheet` widget was extracted to
`presentation/sheets/budget_category_detail_sheet.dart`. A different,
unrelated `CategoryDetailSheet` already exists in
`presentation/sheets/category_detail_sheet.dart` with a different shape and
purpose.

Both already coexisted under the same class name in different files before
this refactor, used in non-overlapping import contexts, so the name was kept
as-is rather than renaming one of them as part of an unrelated split.

Do not merge these two classes or assume they are interchangeable based on
their shared name. If one of them is renamed in the future to remove the
ambiguity, update its importers and this ADR.
