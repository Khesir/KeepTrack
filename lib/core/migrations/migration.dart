/// Base class for database migrations (legacy — no longer used with NestJS backend).
abstract class Migration {
  String get version;
  String get description;
  Future<void> up(dynamic client);
  Future<void> down(dynamic client) async {
    throw UnimplementedError('Rollback not implemented for $version');
  }

  @override
  String toString() => '$version: $description';
}

class MigrationResult {
  final String version;
  final bool success;
  final String? error;
  final DateTime appliedAt;

  MigrationResult({
    required this.version,
    required this.success,
    this.error,
    required this.appliedAt,
  });
}
