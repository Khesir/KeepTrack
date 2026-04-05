enum SyncStatus {
  /// Record is in sync with server
  synced,

  /// Locally created, not yet pushed to server
  pendingCreate,

  /// Locally modified, not yet pushed to server
  pendingUpdate,

  /// Locally deleted, not yet confirmed by server
  pendingDelete,
}

extension SyncStatusX on SyncStatus {
  bool get isDirty => this != SyncStatus.synced;
  String get value => name;

  static SyncStatus fromString(String? v) => SyncStatus.values.firstWhere(
        (e) => e.name == v,
        orElse: () => SyncStatus.synced,
      );
}
