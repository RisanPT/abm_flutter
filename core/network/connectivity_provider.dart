import 'dart:async';

import 'package:abm_madrasa/core/network/dio_client.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    // No sendTimeout: the probe only does bodyless GETs, and on Flutter Web Dio
    // logs a warning for every request when sendTimeout is set without a body —
    // which, on the heartbeat, floods the console. connect/receive cover us.
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
    // 1. Primary probe: check real backend reachability
    try {
      await probe.get(apiBaseUrl);
      return true; // backend answered — internet is up
    } catch (_) {
      // 2. Fallback probe: if backend is briefly restarting/slow, verify internet connectivity via CDN
      try {
        await probe.get('https://cloudflare.com/cdn-cgi/trace');
        return true;
      } catch (_) {
        return false; // both backend and fallback failed — truly no usable internet
      }
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
