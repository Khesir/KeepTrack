import 'package:dio/dio.dart';
import 'package:keep_track/core/network/api_client.dart';

class BackupRemoteDatasource {
  final Dio _dio = ApiClient.instance;

  Future<void> upload(String encryptedEnvelope) async {
    await _dio.post('/backup', data: {'data': encryptedEnvelope});
  }

  Future<String> download() async {
    final res = await _dio.get('/backup');
    return (res.data as Map<String, dynamic>)['data'] as String;
  }

  Future<DateTime?> fetchLastSyncedAt() async {
    try {
      final res = await _dio.get('/backup/meta');
      final raw = (res.data as Map<String, dynamic>)['lastSyncedAt'];
      if (raw == null) return null;
      return DateTime.tryParse(raw as String);
    } catch (_) {
      return null;
    }
  }
}
