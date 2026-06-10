# Backup/restore logic centralized in SettingsDataController

Backup/restore (local export, cloud sync, password-based encryption, wipe,
reset) was previously implemented three times: once in `settings_dialog.dart`'s
`_DataPaneState`, once in `setting_page.dart`'s `_SettingsPageState`, and once
in a standalone `data/services/backup_actions.dart`. The three copies had
drifted slightly and any bug fix had to be applied in three places.

All of this logic now lives in a single
`domain/controllers/settings_data_controller.dart` (`SettingsDataController`),
backed by `BackupService`/`BackupEncryptionService` (`data/repositories/`) and
`BackupSyncStatus` (`data/datasources/`). Both the dialog UI
(`DataSettingsSection`) and the full-page UI (`DataSettingsCardSection`) are
thin presentation wrappers that call the same controller. New backup/restore
behavior should be added to `SettingsDataController` only — the two UI
sections should stay presentation-only.
