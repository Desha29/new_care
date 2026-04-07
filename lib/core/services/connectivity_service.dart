import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// خدمة فحص الاتصال بالإنترنت - Connectivity Service
class ConnectivityService {
  static ConnectivityService? _instance;
  final Connectivity _connectivity = Connectivity();

  bool _isConnected = true;
  StreamSubscription? _subscription;

  /// Stream controller for connectivity changes
  final _controller = StreamController<bool>.broadcast();
  Stream<bool> get onConnectivityChanged => _controller.stream;
  bool get isConnected => _isConnected;

  ConnectivityService._();

  static ConnectivityService get instance {
    _instance ??= ConnectivityService._();
    return _instance!;
  }

  /// تهيئة الخدمة - Initialize
  Future<void> initialize() async {
    await _checkConnectivity();
    _subscription = _connectivity.onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      final connected =
          results.any((r) => r != ConnectivityResult.none);
      if (connected != _isConnected) {
        _isConnected = connected;
        _controller.add(_isConnected);
        debugPrint('[Connectivity] ${_isConnected ? "Online ✓" : "Offline ✗"}');
      }
    });
  }

  /// فحص الاتصال الحالي - Check current connectivity
  Future<bool> _checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _isConnected = results.any((r) => r != ConnectivityResult.none);
      return _isConnected;
    } catch (_) {
      _isConnected = false;
      return false;
    }
  }

  /// تحقق سريع من الاتصال - Quick check
  Future<bool> checkConnection() async {
    return _checkConnectivity();
  }

  /// التخلص من الموارد - Dispose
  void dispose() {
    _subscription?.cancel();
    _controller.close();
  }
}
