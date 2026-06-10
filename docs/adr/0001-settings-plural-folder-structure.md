# Settings feature uses plural folder names matching existing conventions

CLAUDE.md describes an idealized Clean Architecture layout with singular
`presentation/{screen,section,widget,sheet,dialog,helper}` folders and a single
`api.dart`/`di.dart` barrel pair. The `auth`, `finance`, and `notifications`
features already use **plural** folder names
(`presentation/{screens,sections,widgets,sheets,dialogs,helpers,state,controllers}`,
`domain/{entities,repositories,controllers}`, `data/{repositories,datasources,models}`)
and barrels named `<feature>.dart` / `<feature>_di.dart`.

When re-scaffolding the `settings` feature (Candidate 3 of the architecture
review), we matched the plural convention already used elsewhere instead of
introducing the singular layout from CLAUDE.md. Consistency across features
matters more than matching the idealized template, and changing the other
features to singular folders would be a much larger, unrelated migration.
