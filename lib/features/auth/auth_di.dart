import 'package:persona_codex/core/di/service_locator.dart';
import 'package:persona_codex/features/auth/data/services/auth_service.dart';
import 'package:persona_codex/features/auth/presentation/state/auth_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void setupAuthDependencies() {
  // Register AuthService as singleton
  locator.registerLazySingleton<AuthService>(
    () => AuthService(Supabase.instance.client),
  );

  // Register AuthController as singleton
  locator.registerLazySingleton<AuthController>(
    () => AuthController(locator.get<AuthService>()),
  );
}
