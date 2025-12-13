/// Interface for services that need cleanup when disposed
abstract class Disposable {
  /// Called when the service is unregistered or container is disposed
  void dispose();
}

/// Mixin for async disposable resources
mixin AsyncDisposable {
  Future<void> disposeAsync();
}
