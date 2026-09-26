import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Where the reachability probe is sent. Same compile-time override as the API
/// client, so the probe always targets the deployment's real backend.
const _probeUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:5001/api',
);

/// Emits `true` when the device has REAL internet, `false` when it does not.
///
/// `connectivity_plus` on its own only reports whether a network *interface*
/// (Wi-Fi/mobile) is up — a phone joined to a router with no internet still
/// reads "connected". So this provider goes one step further and actively probes
/// the backend:
///   * no interface at all  → offline immediately (fast path);
///   * interface up         → a short HTTP probe confirms real reachability.
///
/// It re-checks on every interface change AND on a periodic timer, so a
/// "connected but no internet" drop is caught within a few seconds, and recovery
/// is detected automatically.
final connectivityProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();
  final probe = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 5),
    sendTimeout: const Duration(seconds: 5),
    // Any HTTP answer (even 401/404) proves reachability; only transport-level
    // failures (no route, DNS, timeout, refused) mean we are truly offline.
    validateStatus: (_) => true,
  ));

  Future<bool> hasInternet() async {
    try {
      final results = await connectivity.checkConnectivity();
      final hasInterface =
          results.isNotEmpty && results.any((r) => r != ConnectivityResult.none);
      if (!hasInterface) return false;
    } catch (_) {
      // If the interface check itself fails, fall through to the active probe.
    }
    try {
      await probe.get(_probeUrl);
      return true; // server answered — internet is up
    } catch (_) {
      return false; // connection error / timeout — no usable internet
    }
  }

  var last = await hasInternet();
  yield last;

  // Coalesce interface events + a heartbeat into one re-probe trigger.
  final trigger = StreamController<void>();
  final sub = connectivity.onConnectivityChanged.listen((_) => trigger.add(null));
  final timer = Timer.periodic(const Duration(seconds: 12), (_) {
    if (!trigger.isClosed) trigger.add(null);
  });
  ref.onDispose(() {
    sub.cancel();
    timer.cancel();
    trigger.close();
    probe.close();
  });

  await for (final _ in trigger.stream) {
    final now = await hasInternet();
    if (now != last) {
      last = now;
      yield now;
    }
  }
});
