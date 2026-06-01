import 'package:dio/dio.dart';
import 'package:keep_track/core/network/api_client.dart';
import 'package:keep_track/features/inbox/domain/entities/announcement.dart';

class AnnouncementDatasource {
  final Dio _dio = ApiClient.instance;

  Future<List<Announcement>> fetchAll() async {
    final res = await _dio.get('/announcements');
    final list = res.data as List<dynamic>;
    return list
        .map((e) => Announcement.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
