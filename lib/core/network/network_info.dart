import 'package:connectivity_plus/connectivity_plus.dart';

/// Reports whether the device has a network interface. It cannot guarantee
/// the server is reachable, so request errors are still handled separately.
class NetworkInfo {
  NetworkInfo([Connectivity? connectivity])
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  static bool _isOnline(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);

  Future<bool> get isOnline async =>
      _isOnline(await _connectivity.checkConnectivity());

  Stream<bool> get onStatusChange =>
      _connectivity.onConnectivityChanged.map(_isOnline).distinct();
}
