# Account/accountId model is fully removed; savings buckets are canonical

The `Account`/`accountId` model (entities, repositories, datasources, and all
references in the Flutter app) was already superseded by the named-savings-
buckets model from an earlier migration (see
`memory/project_savings_migration.md`), but dead code referencing the old
model remained throughout `features/finance`.

As Candidate 1 of the architecture review, this dead code was removed
entirely from the frontend (the backend's NestJS side of this same cleanup is
tracked separately in the backend repo's ADRs). Savings buckets are the only
model for tracking savings going forward — new savings-related UI should
extend the buckets model under `features/finance` and must not reintroduce
`Account`/`accountId` types, fields, repositories, or datasources.
