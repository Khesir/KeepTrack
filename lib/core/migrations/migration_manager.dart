/// Legacy migration manager — no longer used with NestJS backend.
/// Schema is managed by the NestJS backend via Mongoose.
class MigrationManager {
  MigrationManager(dynamic client);

  Future<void> runMigrations() async {
    // No-op: NestJS backend manages schema
  }
}
