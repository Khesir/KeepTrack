# DataSettingsCardSection does not gate Sync/Restore behind Plus

`DataSettingsSection` (the desktop dialog variant) hides cloud Sync/Restore
controls unless `authController.isEffectivelyPlus` is true.
`DataSettingsCardSection` (the mobile/full-page variant), extracted during the
Candidate 3 settings refactor, does **not** apply this gate — it shows
Sync/Restore to all signed-in users.

This mirrors the pre-refactor behavior of the original `setting_page.dart`
implementation, so the refactor preserved existing (inconsistent) behavior
rather than silently changing what mobile users can access. If/when Plus
gating becomes a real product decision, both sections should be updated
together to apply the same rule.
