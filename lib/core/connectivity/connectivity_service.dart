import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  ConnectivityService._() {
    Connectivity().onConnectivityChanged.listen((results) {
      if (!_forceOffline) {
        _controller.add(results.any((r) => r != ConnectivityResult.none));
      }
    });
  }

  static final ConnectivityService instance = ConnectivityService._();

  final _controller = StreamController<bool>.broadcast();
  bool _forceOffline = false;

  bool get isForceOffline => _forceOffline;

  void setForceOffline(bool value) {
    _forceOffline = value;
    _controller.add(!value);
  }

  Stream<bool> get onConnectivityChanged => _controller.stream;

  Future<bool> get isOnline async {
    if (_forceOffline) return false;
    final results = await Connectivity().checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }
}
