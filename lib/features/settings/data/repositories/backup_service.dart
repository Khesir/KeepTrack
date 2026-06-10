import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:keep_track/core/cache/local_cache.dart';
import 'package:keep_track/features/settings/data/datasources/backup_remote_datasource.dart';
import 'backup_encryption_service.dart';

export 'backup_encryption_service.dart';
export '../datasources/backup_remote_datasource.dart';

class BackupService {
  final LocalCache _cache;
  final BackupEncryptionService _encryption;
  final BackupRemoteDatasource _remote;

  static const _boxes = [
    'transactions',
    'budgets',
    'budget_categories',
    'month_plans',
    'goals',
    'debts',
    'planned_payments',
    'wallets',
    'savings_buckets',
    'subscriptions',
    'transaction_plans',
    'finance_categories',
    'budget_profiles',
  ];

  BackupService({
    required LocalCache cache,
    required BackupEncryptionService encryption,
    required BackupRemoteDatasource remote,
  })  : _cache = cache,
        _encryption = encryption,
        _remote = remote;

  Future<Map<String, dynamic>> _collectData() async {
    final boxes = <String, dynamic>{};
    for (final box in _boxes) {
      boxes[box] = await _cache.getAll(box);
    }
    return {
      'exportedAt': DateTime.now().toIso8601String(),
      'boxes': boxes,
    };
  }

  Future<void> _restoreData(String payload) async {
    final parsed = jsonDecode(payload) as Map<String, dynamic>;
    final boxes = parsed['boxes'] as Map<String, dynamic>;

    for (final box in _boxes) {
      await _cache.clear(box);
      final entries =
          (boxes[box] as List?)?.cast<Map<String, dynamic>>() ?? [];
      if (entries.isEmpty) continue;
      final mapped = <String, Map<String, dynamic>>{};
      for (final e in entries) {
        final id = e['id'] as String?;
        if (id != null) mapped[id] = e;
      }
      if (mapped.isNotEmpty) await _cache.putAll(box, mapped);
    }
  }

  Future<String?> exportToFile(String password) async {
    final payload = jsonEncode(await _collectData());
    final envelope = _encryption.encrypt(payload, password);
    final bytes = Uint8List.fromList(utf8.encode(envelope));
    final date = DateTime.now().toIso8601String().substring(0, 10);

    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Keep Track Backup',
      fileName: 'keep_track_$date.ktbak',
      bytes: bytes,
    );

    // On desktop, file_picker returns the path but doesn't write the bytes.
    // We write them explicitly. On web, saveFile triggers the download directly.
    if (path != null && !kIsWeb) {
      await File(path).writeAsBytes(bytes);
    }

    return path;
  }

  Future<void> syncToCloud(String password) async {
    final payload = jsonEncode(await _collectData());
    final envelope = _encryption.encrypt(payload, password);
    await _remote.upload(envelope);
  }

  Future<Uint8List?> pickBackupFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['ktbak'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;

    final file = result.files.first;
    if (file.bytes != null) return file.bytes!;
    if (file.path != null && !kIsWeb) return File(file.path!).readAsBytes();
    throw const InvalidBackupException();
  }

  Future<void> restoreFromBytes(Uint8List bytes, String password) async {
    final envelopeJson = utf8.decode(bytes);
    final payload = _encryption.decrypt(envelopeJson, password);
    await _restoreData(payload);
  }

  Future<DateTime?> fetchLastSyncedAt() => _remote.fetchLastSyncedAt();

  Future<bool> importFromFile(String password) async {
    final bytes = await pickBackupFile();
    if (bytes == null) return false;
    await restoreFromBytes(bytes, password);
    return true;
  }

  Future<void> restoreFromCloud(String password) async {
    final envelopeJson = await _remote.download();
    final payload = _encryption.decrypt(envelopeJson, password);
    await _restoreData(payload);
  }
}
