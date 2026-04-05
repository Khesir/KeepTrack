import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/features/auth/data/services/auth_service.dart';
import 'package:keep_track/features/auth/presentation/state/auth_controller.dart';

void setupAuthDependencies() {
  locator.registerLazySingleton<AuthService>(() => AuthService());

  locator.registerLazySingleton<AuthController>(
    () => AuthController(locator.get<AuthService>()),
  );
}
