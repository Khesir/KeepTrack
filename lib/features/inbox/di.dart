import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/features/inbox/data/datasource/announcement_datasource.dart';
import 'package:keep_track/features/inbox/data/repository/announcement_repository_impl.dart';
import 'package:keep_track/features/inbox/domain/controller/inbox_controller.dart';
import 'package:keep_track/features/inbox/domain/repository/announcement_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void setupInboxDependencies() {
  locator.registerLazySingleton<AnnouncementDatasource>(
    () => AnnouncementDatasource(),
  );
  locator.registerLazySingleton<AnnouncementRepository>(
    () => AnnouncementRepositoryImpl(locator.get<AnnouncementDatasource>()),
  );
  locator.registerLazySingleton<InboxController>(
    () => InboxController(
      locator.get<AnnouncementRepository>(),
      locator.get<SharedPreferences>(),
    ),
  );
}
