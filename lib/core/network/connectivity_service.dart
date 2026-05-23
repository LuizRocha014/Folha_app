import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Wrapper sobre `connectivity_plus`. Expõe um `Stream<bool>` (online/offline)
/// e um getter síncrono `isOnline` cacheado.
class ConnectivityService {
  ConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity() {
    _sub = _connectivity.onConnectivityChanged.listen((results) {
      _online = _isOnlineList(results);
      _controller.add(_online);
    });
  }

  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _sub;
  final StreamController<bool> _controller = StreamController<bool>.broadcast();
  bool _online = true;

  bool get isOnline => _online;
  Stream<bool> get onChanged => _controller.stream;

  Future<void> probe() async {
    final results = await _connectivity.checkConnectivity();
    _online = _isOnlineList(results);
    _controller.add(_online);
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    await _controller.close();
  }

  static bool _isOnlineList(List<ConnectivityResult> results) {
    if (results.isEmpty) return false;
    return results.any((r) =>
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.ethernet ||
        r == ConnectivityResult.vpn);
  }
}
