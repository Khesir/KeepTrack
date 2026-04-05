import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  ConnectivityService._();
  static final ConnectivityService instance = ConnectivityService._();

  Stream<bool> get onConnectivityChanged =>
      Connectivity().onConnectivityChanged.map(
            (results) => results.any((r) => r != ConnectivityResult.none),
          );

  Future<bool> get isOnline async {
    final results = await Connectivity().checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }
}
