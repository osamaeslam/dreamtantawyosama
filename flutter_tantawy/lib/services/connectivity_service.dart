import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../models/models.dart';

/// **Real** connectivity verification — not just a network-interface signal.
///
/// Many offline-first apps gate on `ConnectivityResult` which merely reports
/// whether a network interface is up. That is insufficient for financial apps:
/// you can be "connected" to a WiFi captive portal that cannot reach the
/// backend. This service performs an active HTTP probe (HEAD) against the
/// server health endpoint with a short timeout, so the app only transitions
/// to **online** when the backend is genuinely reachable.
class ConnectivityService {
  ConnectivityService._();

  static final ConnectivityService instance = ConnectivityService._();

  final _connectivity = Connectivity();
  final _statusController = StreamController<ConnectionStatus>.broadcast();

  /// The current (last known) status, exposed for one-shot reads.
  ConnectionStatus _currentStatus = ConnectionStatus.checking;

  ConnectionStatus get currentStatus => _currentStatus;

  /// Stream of status changes. Widgets like [ConnectionStatusBar] listen here.
  Stream<ConnectionStatus> get statusStream => _statusController.stream;

  /// Ping endpoint — a lightweight HEAD against the Supabase REST root.
  /// Override via constructor/param if you expose a dedicated /health route.
  static const String defaultProbeUrl = 'https://rxthpgmlcsfckstpqhqf.supabase.co/functions/v1/ping';

  /// Performs an **active** reachability probe.
  /// Returns true only when a full HTTP handshake with our backend succeeds.
  Future<bool> pingServer([String? probeUrl]) async {
    final url = probeUrl ?? defaultProbeUrl;
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 5);
      final request = await client.headUrl(Uri.parse(url));
      request.followRedirects = false;
      final response = await request.close();
      client.close(force: true);
      // Any HTTP response (even 401/404) means the server is reachable.
      // A DNS failure / timeout / socket error means unreachable.
      return response.statusCode < 600;
    } catch (e) {
      debugPrint('[Connectivity] Server ping failed: $e');
      return false;
    }
  }

  /// Combines the passive `connectivity_plus` check with an active probe.
  Future<ConnectionStatus> _evaluate() async {
    final result = await _connectivity.checkConnectivity();

    // No network interface at all.
    if (result == ConnectivityResult.none) {
      return ConnectionStatus.disconnected;
    }

    // We have *some* interface — prove the backend is actually reachable.
    final reachable = await pingServer();
    return reachable ? ConnectionStatus.online : ConnectionStatus.offline;
  }

  /// One-shot check + notify listeners. Call this on app start/resume.
  Future<ConnectionStatus> checkNow() async {
    final status = await _evaluate();
    _emit(status);
    return status;
  }

  /// Starts a periodic watcher (default every 30s). Pass `interval` to tune.
  /// Call `stop()` before disposal or when the app goes to background.
  Timer? _timer;

  void startWatching({Duration interval = const Duration(seconds: 30)}) {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) => checkNow());
  }

  void dispose() {
    _timer?.cancel();
    _statusController.close();
  }

  void _emit(ConnectionStatus status) {
    if (status == _currentStatus) return;
    _currentStatus = status;
    if (!_statusController.isClosed) {
      _statusController.add(status);
    }
    debugPrint('[Connectivity] Status -> ${_currentStatus.name}');
  }

  /// Convenience: subscribe to real-time updates.
  Stream<ConnectionStatus> watchStatus() => statusStream;
}
