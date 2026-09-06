import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final ConnectivityService instance = ConnectivityService._init();
  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _controller = StreamController<bool>.broadcast();

  bool _isOnline = true;
  bool _isSimulatedOffline = false;

  ConnectivityService._init() {
    _initConnectivity();
    _connectivity.onConnectivityChanged.listen(_handleStatusChange);
  }

  bool get isOnline => _isSimulatedOffline ? false : _isOnline;
  bool get isSimulatedOffline => _isSimulatedOffline;
  Stream<bool> get onConnectivityChanged => _controller.stream;

  Future<void> _initConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _handleStatusChange(results);
    } catch (_) {
      _isOnline = true;
      _controller.add(isOnline);
    }
  }

  void _handleStatusChange(List<ConnectivityResult> results) {
    final hasConnection = results.any(
      (r) => r == ConnectivityResult.wifi ||
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.ethernet,
    );
    _isOnline = hasConnection;
    _controller.add(isOnline);
  }

  void toggleSimulatedOffline(bool simulated) {
    _isSimulatedOffline = simulated;
    _controller.add(isOnline);
  }

  void dispose() {
    _controller.close();
  }
}
