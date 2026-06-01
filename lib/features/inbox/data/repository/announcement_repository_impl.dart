import 'package:keep_track/features/inbox/data/datasource/announcement_datasource.dart';
import 'package:keep_track/features/inbox/domain/entities/announcement.dart';
import 'package:keep_track/features/inbox/domain/repository/announcement_repository.dart';

class AnnouncementRepositoryImpl implements AnnouncementRepository {
  final AnnouncementDatasource _datasource;

  AnnouncementRepositoryImpl(this._datasource);

  @override
  Future<List<Announcement>> fetchAll() => _datasource.fetchAll();
}
