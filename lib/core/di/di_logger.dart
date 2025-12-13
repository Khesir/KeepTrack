/// Logger for DI operations
class DILogger {
  static bool _enabled = false;

  /// Enable or disable logging
  static void enable() => _enabled = true;
  static void disable() => _enabled = false;
  static void toggle() => _enabled = !_enabled;

  static bool get isEnabled => _enabled;

  static void log(String message) {
    if (_enabled) {
      print('[DI] $message');
    }
  }

  static void registerSingleton(Type type) {
    log('📦 Registered singleton: $type');
  }

  static void registerFactory(Type type) {
    log('🏭 Registered factory: $type');
  }

  static void registerLazySingleton(Type type) {
    log('💤 Registered lazy singleton: $type');
  }

  static void resolve(Type type) {
    log('✅ Resolved: $type');
  }

  static void unregister(Type type) {
    log('❌ Unregistered: $type');
  }

  static void dispose(Type type) {
    log('🗑️  Disposed: $type');
  }

  static void createScope(String? name) {
    log('🔷 Created scope: ${name ?? "anonymous"}');
  }

  static void disposeScope(String? name) {
    log('🔶 Disposed scope: ${name ?? "anonymous"}');
  }

  static void error(String message) {
    if (_enabled) {
      print('[DI ERROR] ⚠️  $message');
    }
  }
}
