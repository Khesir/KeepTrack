import 'package:keep_track/features/inbox/domain/entities/announcement.dart';

abstract class AnnouncementRepository {
  Future<List<Announcement>> fetchAll();
}
